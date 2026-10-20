import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';
import '../../core/handwriting.dart';
import '../../core/local_tools.dart';
import '../../core/pinyin_engine.dart';
import '../../core/stroke_engine.dart';

class KeyboardController extends ChangeNotifier {
  KeyboardController({String? initialPanel}) {
    text = TextEditingController(text: '豆包输入法复刻版测试：');
    text.selection = TextSelection.collapsed(offset: text.text.length);
    text.addListener(notifyListeners);
    panel = initialPanel;
    mode = AppState.ready && AppState.I.keyboardType.isNotEmpty
        ? AppState.I.keyboardType
        : 'pinyin26';
    chinese = true;
    _refreshCandidates();
  }

  late final TextEditingController text;
  final FocusNode focus = FocusNode();
  void Function(String message)? toast;

  String mode = 'pinyin26';
  String composing = '';
  bool chinese = true;
  bool shift = false;
  bool caps = false;
  bool collapsed = false;
  String? panel;
  int panelIndex = 0;
  int candidatePage = 0;
  bool numberLayout = false;
  bool symbolLayout = false;
  bool recognizing = false;

  List<Cand> candidates = [];
  List<String> associations = [];
  List<String> predictions = [];
  String? lastCommitted;
  String? clipboardHint;
  int? lastQueryMicros;

  String _englishWord = '';
  List<String> englishSuggestions = [];
  String _undo = '';

  List<List<Offset>> strokes = [];
  List<Offset> _currentStroke = [];
  List<String> handwritingCandidates = [];
  bool handwritingConfident = false;
  bool handwritingReady = false;
  bool handwritingLoading = false;
  Timer? _handwritingTimer;

  String strokeCode = '';
  List<StrokeCand> strokeCandidates = [];

  DateTime _lastShiftTap = DateTime.fromMillisecondsSinceEpoch(0);

  static const _englishWords = <String>[
    'the', 'this', 'that', 'there', 'these', 'those', 'today', 'tomorrow',
    'time', 'team', 'test', 'text', 'thank', 'thanks', 'think', 'then',
    'hello', 'help', 'here', 'have', 'has', 'happy', 'home', 'hope', 'hour',
    'good', 'great', 'green', 'group', 'give', 'going', 'game',
    'you', 'your', 'yes', 'year', 'yesterday', 'young',
    'we', 'well', 'week', 'work', 'world', 'word', 'with', 'will', 'would', 'write',
    'i', 'in', 'is', 'it', 'if', 'into', 'input', 'idea', 'important',
    'a', 'an', 'and', 'are', 'all', 'also', 'about', 'after', 'again', 'app',
    'be', 'but', 'by', 'because', 'before', 'best', 'better', 'build', 'business',
    'can', 'come', 'could', 'call', 'change', 'check', 'clear', 'click', 'close',
    'do', 'day', 'did', 'does', 'done', 'down', 'data', 'design', 'develop',
    'email', 'each', 'easy', 'edit', 'end', 'enter', 'even', 'every',
    'for', 'from', 'first', 'find', 'fine', 'finish', 'focus', 'friend', 'full',
    'get', 'go', 'got', 'give', 'glass', 'keyboard', 'know', 'kind', 'keep',
    'like', 'list', 'look', 'little', 'last', 'later', 'learn', 'let', 'line',
    'me', 'my', 'more', 'make', 'many', 'maybe', 'meeting', 'message', 'model',
    'new', 'need', 'next', 'nice', 'night', 'note', 'now', 'number',
    'of', 'on', 'or', 'our', 'out', 'one', 'only', 'open', 'other', 'over',
    'people', 'please', 'phone', 'place', 'plan', 'point', 'possible', 'project',
    'quick', 'question', 'read', 'right', 'run', 'ready', 'really', 'reply',
    'so', 'some', 'see', 'send', 'set', 'show', 'small', 'start', 'still', 'sure',
    'to', 'too', 'two', 'take', 'talk', 'tell', 'than', 'them', 'thing', 'try',
    'up', 'us', 'use', 'very', 'voice', 'want', 'way', 'what', 'when', 'where',
    'which', 'who', 'why', 'word', 'work', 'write', 'wrong',
  ];

  String get modeName => switch (mode) {
        'pinyin9' => '拼音 9 键',
        'handwriting' => '手写',
        'stroke' => '笔画',
        'shuangpin' => '双拼',
        'wubi' => '五笔',
        _ => '拼音 26 键',
      };

  bool get isHandwriting => mode == 'handwriting';
  bool get isStroke => mode == 'stroke';
  bool get isNine => mode == 'pinyin9';
  bool get isWubi => mode == 'wubi';
  bool get isShuangpin => mode == 'shuangpin';

  List<Cand> get visibleCandidates {
    final start = candidatePage * 9;
    if (start >= candidates.length) return const [];
    return candidates.sublist(start, (start + 9).clamp(0, candidates.length));
  }

  int get pageCount => (candidates.length / 9).ceil().clamp(1, 9);

  String get displayComposing => composing;

  void syncFromState() {
    final s = AppState.I;
    if (s.keyboardType.isNotEmpty && s.keyboardType != mode) {
      mode = s.keyboardType;
      composing = '';
      candidates = [];
      candidatePage = 0;
      strokeCode = '';
      strokeCandidates = [];
      _refreshCandidates();
      notifyListeners();
    }
  }

  void setMode(String m) {
    AppState.I.setKeyboardType(m);
    mode = m;
    composing = '';
    candidates = [];
    candidatePage = 0;
    numberLayout = false;
    symbolLayout = false;
    panel = null;
    strokeCode = '';
    strokeCandidates = [];
    strokes = [];
    handwritingCandidates = [];
    notifyListeners();
  }

  void refreshUI() => notifyListeners();

  void setPanel(String? p) {
    panel = p;
    panelIndex = 0;
    if (p != 'candidates') candidatePage = 0;
    notifyListeners();
  }

  void setPanelPage(int i) {
    panelIndex = i;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Text insertion
  // ---------------------------------------------------------------------------
  TextSelection get _selection {
    final s = text.selection;
    if (!s.isValid) return TextSelection.collapsed(offset: text.text.length);
    return s;
  }

  bool get _atSentenceStart {
    final t = text.text;
    final i = _selection.start - 1;
    if (i < 0) return true;
    return '.!?\n。！？'.contains(t[i]);
  }

  String _withSmartSpace(String value) {
    if (value.isEmpty || !AppState.I.getBool(K.quickSpace)) return value;
    final sel = _selection;
    if (sel.start <= 0) return value;
    final prev = text.text[sel.start - 1];
    if (prev == ' ' || prev == '\n') return value;
    final vIsAscii = RegExp(r'^[A-Za-z0-9]').hasMatch(value);
    final vIsCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(value);
    final pIsAscii = RegExp(r'[A-Za-z0-9]').hasMatch(prev);
    final pIsCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(prev);
    if ((vIsAscii && pIsCjk) || (vIsCjk && pIsAscii)) return ' $value';
    return value;
  }

  void insertText(String value, {bool learn = false, bool applyScript = true}) {
    if (value.isEmpty) return;
    var v = value;
    if (applyScript && AppState.I.traditional) v = toTraditional(v);
    v = _withSmartSpace(v);
    final sel = _selection;
    final base = text.text;
    final start = sel.start.clamp(0, base.length);
    final end = sel.end.clamp(start, base.length);
    final next = base.replaceRange(start, end, v);
    text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + v.length),
    );
    if (learn) {
      AppState.I.learnWord(value);
      PinyinEngine.instance.clearCache();
    }
    notifyListeners();
  }

  void clearText() {
    _undo = text.text;
    text.clear();
    composing = '';
    candidates = [];
    associations = [];
    predictions = [];
    notifyListeners();
  }

  void copyAll() => copyTextValue(text.text);

  void copyTextValue(String v) {
    Clipboard.setData(ClipboardData(text: v));
    if (toast != null) toast!('已复制');
  }

  // ---------------------------------------------------------------------------
  // Key events
  // ---------------------------------------------------------------------------
  void onLetter(String letter) {
    if (isHandwriting || isStroke) return;
    final upper = caps || shift;
    if (chinese) {
      if (upper) {
        insertText(letter.toUpperCase(), applyScript: false);
        shift = false;
        notifyListeners();
        return;
      }
      composing += letter.toLowerCase();
      _refreshCandidates();
      if (isWubi && candidates.isNotEmpty) {
        final st = AppState.I;
        if (st.getBool(K.wubiUnique4) && composing.length == 4 && candidates.length == 1) {
          commitCandidate(candidates.first);
          if (toast != null) toast!('四码唯一，已自动上屏');
          return;
        }
        if (st.getBool(K.wubiFifth) && composing.length >= 5) {
          commitCandidate(candidates.first);
          if (toast != null) toast!('第五码首选，已上屏');
          return;
        }
      }
      notifyListeners();
      return;
    }
    var ch = upper ? letter.toUpperCase() : letter.toLowerCase();
    if (!upper && AppState.I.getBool(K.quickCapitalize) && _atSentenceStart) {
      ch = ch.toUpperCase();
    }
    insertText(ch, applyScript: false);
    _englishWord += ch.toLowerCase();
    _updateEnglishSuggestions();
    if (shift) shift = false;
    notifyListeners();
  }

  void onDigit(String digit) {
    if (isNine) {
      composing += digit;
      _refreshCandidates();
      notifyListeners();
    } else {
      insertText(digit, applyScript: false);
    }
  }

  void onSeparator() {
    if (composing.isNotEmpty) {
      composing += "'";
      notifyListeners();
    } else {
      insertText("'", applyScript: false);
    }
  }

  void onBackspace() {
    if (isHandwriting) {
      undoStroke();
      return;
    }
    if (isStroke && strokeCode.isNotEmpty) {
      strokeCode = strokeCode.substring(0, strokeCode.length - 1);
      strokeCandidates = lookupStrokes(strokeCode);
      notifyListeners();
      return;
    }
    if (composing.isNotEmpty) {
      composing = composing.substring(0, composing.length - 1);
      _refreshCandidates();
      notifyListeners();
      return;
    }
    final sel = _selection;
    final t = text.text;
    if (sel.start != sel.end) {
      _undo = t.substring(sel.start, sel.end);
      text.value = TextEditingValue(
        text: t.replaceRange(sel.start, sel.end, ''),
        selection: TextSelection.collapsed(offset: sel.start),
      );
    } else if (sel.start > 0) {
      _undo = t[sel.start - 1];
      text.value = TextEditingValue(
        text: t.replaceRange(sel.start - 1, sel.start, ''),
        selection: TextSelection.collapsed(offset: sel.start - 1),
      );
    }
    if (_englishWord.isNotEmpty) {
      _englishWord = _englishWord.substring(0, _englishWord.length - 1);
      _updateEnglishSuggestions();
    }
    notifyListeners();
  }

  void undoDelete() {
    if (_undo.isEmpty) {
      if (toast != null) toast!('没有可撤销的删除');
      return;
    }
    insertText(_undo, applyScript: false);
    _undo = '';
    if (toast != null) toast!('已撤销删除');
  }

  void onSpace() {
    if (isHandwriting) return;
    if (composing.isNotEmpty) {
      if (candidates.isNotEmpty) {
        commitCandidate(candidates.first);
      } else {
        insertText(composing, applyScript: false);
        composing = '';
        _refreshCandidates();
        notifyListeners();
      }
      return;
    }
    if (isStroke && strokeCode.isNotEmpty) {
      strokeCode = '';
      strokeCandidates = [];
      notifyListeners();
      return;
    }
    if (!chinese && AppState.I.getBool(K.quickDoubleSpacePeriod)) {
      final sel = _selection;
      if (sel.start > 0 && text.text[sel.start - 1] == ' ') {
        text.value = TextEditingValue(
          text: text.text.replaceRange(sel.start - 1, sel.start, '. '),
          selection: TextSelection.collapsed(offset: sel.start + 1),
        );
        _englishWord = '';
        _updateEnglishSuggestions();
        notifyListeners();
        return;
      }
    }
    insertText(' ', applyScript: false);
    _englishWord = '';
    _updateEnglishSuggestions();
  }

  void onEnter() {
    if (AppState.I.enterSend) {
      focus.unfocus();
      if (toast != null) toast!('已发送（演示）');
      return;
    }
    insertText('\n', applyScript: false);
  }

  void onPunctuation(String p) {
    if (composing.isNotEmpty) {
      if (candidates.isNotEmpty) commitCandidate(candidates.first);
      else {
        composing = '';
        _refreshCandidates();
      }
    }
    insertText(p, applyScript: false);
    _englishWord = '';
    _updateEnglishSuggestions();
  }

  void onShift() {
    final now = DateTime.now();
    if (caps) {
      caps = false;
      shift = false;
    } else if (shift) {
      if (now.difference(_lastShiftTap) < const Duration(milliseconds: 350)) {
        caps = true;
        shift = false;
      } else {
        shift = false;
      }
    } else {
      shift = true;
    }
    _lastShiftTap = now;
    notifyListeners();
  }

  void toggleChinese() {
    chinese = !chinese;
    composing = '';
    candidates = [];
    candidatePage = 0;
    shift = false;
    caps = false;
    _englishWord = '';
    _updateEnglishSuggestions();
    if (!chinese) associations = [];
    notifyListeners();
    if (toast != null) toast!(chinese ? '中文输入' : '英文输入');
  }

  void toggleTraditional() {
    final s = AppState.I;
    s.setBool(K.traditional, !s.traditional);
    if (toast != null) toast!(s.traditional ? '繁体模式已开启' : '简体模式已开启');
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Candidates
  // ---------------------------------------------------------------------------
  void refreshCandidates() => _refreshCandidates();

  void _refreshCandidates() {
    final s = AppState.I;
    final q = composing.replaceAll("'", '');
    if (q.isEmpty) {
      candidates = [];
      candidatePage = 0;
      lastQueryMicros = 0;
      return;
    }
    final fuzzy = s.getBool(K.fuzzyEnabled);
    final result = PinyinEngine.instance.query(
      q,
      mode: mode == 'wubi'
          ? 'wubi'
          : mode == 'pinyin9'
              ? 'pinyin9'
              : mode == 'shuangpin'
                  ? 'shuangpin'
                  : 'pinyin26',
      limit: 48,
      fuzzy: fuzzy,
      fuzzyInitials: s.getList(K.fuzzyInitials),
      fuzzyFinals: s.getList(K.fuzzyFinals),
      fuzzySyllables: s.getList(K.fuzzySyllables),
      wubiMix: s.getBool(K.wubiMix),
    );
    candidates = result;
    lastQueryMicros = PinyinEngine.instance.lastQueryMicros;
    candidatePage = 0;
  }

  void commitCandidate(Cand c) {
    insertText(c.text);
    lastCommitted = c.text;
    composing = '';
    candidates = [];
    candidatePage = 0;
    _updateAssociations(c.text);
    notifyListeners();
  }

  void commitHandwriting(String s) {
    insertText(s);
    lastCommitted = s;
    handwritingCandidates = [];
    _updateAssociations(s);
    notifyListeners();
  }

  void _updateAssociations(String word) {
    final s = AppState.I;
    if (!s.getBool(K.associationEnabled)) {
      associations = [];
      predictions = [];
      return;
    }
    associations = PinyinEngine.instance.associates(word);
    final p = <String>[];
    if (s.getBool(K.predictionEmoji)) {
      p.addAll(PinyinEngine.instance.emojiFor(word).take(2));
    }
    if (s.getBool(K.predictionImage)) {
      p.addAll(PinyinEngine.stickers.take(2).map((e) => e[0]));
    }
    if (s.getBool(K.predictionKaomoji)) {
      p.add(PinyinEngine.kaomoji.first);
    }
    predictions = p.take(6).toList();
  }

  void commitPrediction(String p) {
    insertText(p);
    notifyListeners();
  }

  void deleteCandidate(Cand c) {
    AppState.I.deleteWord(c.text);
    _refreshCandidates();
    notifyListeners();
    if (toast != null) toast!('已删除候选「${c.text}」，本机不再推荐');
  }

  void nextPage() {
    if (candidatePage + 1 < pageCount) {
      candidatePage++;
      notifyListeners();
    }
  }

  void prevPage() {
    if (candidatePage > 0) {
      candidatePage--;
      notifyListeners();
    }
  }

  void _updateEnglishSuggestions() {
    if (_englishWord.isEmpty) {
      englishSuggestions = [];
      return;
    }
    final q = _englishWord.toLowerCase();
    englishSuggestions = _englishWords
        .where((w) => w.startsWith(q) && w != q)
        .take(8)
        .toList();
  }

  void applyEnglishSuggestion(String word) {
    if (_englishWord.isEmpty) {
      insertText('$word ', applyScript: false);
    } else {
      final len = _englishWord.length;
      final sel = _selection;
      final start = (sel.start - len).clamp(0, text.text.length);
      text.value = TextEditingValue(
        text: text.text.replaceRange(start, sel.start, '$word '),
        selection: TextSelection.collapsed(offset: start + word.length + 1),
      );
    }
    _englishWord = '';
    _updateEnglishSuggestions();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Handwriting
  // ---------------------------------------------------------------------------
  Future<void> ensureHandwritingReady() async {
    if (handwritingReady || handwritingLoading) return;
    handwritingLoading = true;
    notifyListeners();
    try {
      await HandwritingRecognizer.instance.prepare();
      handwritingReady = true;
    } catch (_) {}
    handwritingLoading = false;
    notifyListeners();
  }

  void startStroke(Offset p) {
    _currentStroke = [p];
    strokes.add(_currentStroke);
    handwritingCandidates = [];
    notifyListeners();
  }

  void addStrokePoint(Offset p) {
    if (_currentStroke.isEmpty) startStroke(p);
    else {
      _currentStroke.add(p);
      notifyListeners();
    }
  }

  void endStroke() {
    if (_currentStroke.isEmpty) return;
    _handwritingTimer?.cancel();
    _handwritingTimer = Timer(const Duration(milliseconds: 650), recognizeHandwriting);
    notifyListeners();
  }

  void undoStroke() {
    _handwritingTimer?.cancel();
    if (strokes.isNotEmpty) strokes.removeLast();
    handwritingCandidates = [];
    notifyListeners();
  }

  void clearStrokes() {
    _handwritingTimer?.cancel();
    strokes = [];
    _currentStroke = [];
    handwritingCandidates = [];
    handwritingConfident = false;
    notifyListeners();
  }

  Future<void> recognizeHandwriting() async {
    if (strokes.isEmpty || recognizing) return;
    recognizing = true;
    notifyListeners();
    try {
      if (!handwritingReady) await ensureHandwritingReady();
      final result = await HandwritingRecognizer.instance.recognize(strokes);
      handwritingCandidates = result.candidates;
      handwritingConfident = result.confident;
    } catch (_) {
      handwritingCandidates = [];
      handwritingConfident = false;
    }
    recognizing = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Stroke input
  // ---------------------------------------------------------------------------
  void onStroke(String code) {
    strokeCode += code;
    strokeCandidates = lookupStrokes(strokeCode);
    notifyListeners();
  }

  void clearStroke() {
    strokeCode = '';
    strokeCandidates = [];
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Toolbar actions
  // ---------------------------------------------------------------------------
  void toggleCollapse() {
    collapsed = !collapsed;
    panel = null;
    notifyListeners();
  }

  void openVoicePanel() {
    panel = 'voice';
    notifyListeners();
  }

  void showClipboardHint() {
    final items = AppState.I.clipboardItems;
    clipboardHint = items.isEmpty ? null : (items.first['text'] ?? '').toString();
    notifyListeners();
  }

  @override
  void dispose() {
    _handwritingTimer?.cancel();
    text.removeListener(notifyListeners);
    text.dispose();
    focus.dispose();
    super.dispose();
  }
}
