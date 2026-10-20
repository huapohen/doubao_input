import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Canonical persisted keys (shared with the other two clones).
class K {
  static const onboardingDone = 'onboarding_done';
  static const privacyMode = 'privacy_mode';
  static const keyboardType = 'keyboard_type';
  static const themeMode = 'theme_mode';
  static const inputMode = 'input_mode';
  static const fuzzyEnabled = 'fuzzy_enabled';
  static const fuzzyInitials = 'fuzzy_initials';
  static const fuzzyFinals = 'fuzzy_finals';
  static const fuzzySyllables = 'fuzzy_syllables';
  static const associationEnabled = 'association_enabled';
  static const predictionEmoji = 'prediction_emoji';
  static const predictionImage = 'prediction_image';
  static const predictionKaomoji = 'prediction_kaomoji';
  static const keySound = 'key_sound';
  static const keyVibrate = 'key_vibrate';
  static const keyVibrateLevel = 'key_vibrate_level';
  static const keyBubble = 'key_bubble';
  static const quickSpace = 'quick_space';
  static const quickCapitalize = 'quick_capitalize';
  static const quickDoubleSpacePeriod = 'quick_double_space_period';
  static const clipboardCandidate = 'clipboard_candidate';
  static const clipboardHistory = 'clipboard_history';
  static const voiceSmartOrganize = 'voice_smart_organize';
  static const voicePunctuation = 'voice_punctuation';
  static const voiceFiller = 'voice_filler';
  static const voiceOffline = 'voice_offline';
  static const voiceActionEnabled = 'voice_action_enabled';
  static const voiceActions = 'voice_actions';
  static const candidateFontSize = 'candidate_font_size';
  static const pinyinLocation = 'pinyin_location';
  static const enterSend = 'enter_send';
  static const oneHand = 'one_hand';
  static const floating = 'floating';
  static const keyboardHeight = 'keyboard_height';
  static const customToolbar = 'custom_toolbar';
  static const commonPhrases = 'common_phrases';
  static const personalLexicon = 'personal_lexicon';
  static const clipboardItems = 'clipboard_items';
  static const aiBaseUrl = 'ai_base_url';
  static const aiModel = 'ai_model';
  static const aiKey = 'ai_key';
  static const accountLoggedIn = 'account_logged_in';
  static const accountName = 'account_name';
  static const superTransferEnabled = 'super_transfer_enabled';
  static const deviceId = 'device_id';
  static const traditional = 'traditional';
  static const shuangpinScheme = 'shuangpin_scheme';
  static const wubiHint = 'wubi_hint';
  static const wubiMix = 'wubi_mix';
  static const wubiUnique4 = 'wubi_unique4';
  static const wubiFifth = 'wubi_fifth';
}

class AppState extends ChangeNotifier {
  AppState._();

  static AppState? _instance;
  static AppState get I => _instance!;
  static bool get ready => _instance != null;

  late SharedPreferences prefs;
  bool loaded = false;
  bool secureStorageOk = true;
  String _memoryKey = '';

  static const _secure = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
  );

  static const _defaults = <String, Object>{
    K.onboardingDone: false,
    K.privacyMode: 'none',
    K.keyboardType: '',
    K.themeMode: 'system',
    K.inputMode: 'smart',
    K.fuzzyEnabled: false,
    K.associationEnabled: true,
    K.predictionEmoji: true,
    K.predictionImage: true,
    K.predictionKaomoji: true,
    K.keySound: true,
    K.keyVibrate: true,
    K.keyVibrateLevel: 2,
    K.keyBubble: true,
    K.quickSpace: true,
    K.quickCapitalize: true,
    K.quickDoubleSpacePeriod: true,
    K.clipboardCandidate: true,
    K.clipboardHistory: true,
    K.voiceSmartOrganize: true,
    K.voicePunctuation: '智能标点',
    K.voiceFiller: '正常',
    K.voiceOffline: false,
    K.voiceActionEnabled: false,
    K.candidateFontSize: 21,
    K.pinyinLocation: '候选栏',
    K.enterSend: false,
    K.oneHand: 'off',
    K.floating: false,
    K.keyboardHeight: 340,
    K.customToolbar:
        'toolbox,voice,clipboard,translate,emoji,phrases,keyboard,tradition,onehand,handwriting,undo,ai,collapse',
    K.aiBaseUrl: 'https://api.deepseek.com',
    K.aiModel: 'deepseek-chat',
    K.accountLoggedIn: false,
    K.accountName: '',
    K.superTransferEnabled: false,
    K.traditional: false,
    K.shuangpinScheme: '小鹤双拼',
    K.wubiHint: true,
    K.wubiMix: true,
    K.wubiUnique4: true,
    K.wubiFifth: true,
  };

  static const defaultToolbar = <String>[
    'toolbox', 'voice', 'clipboard', 'translate', 'emoji', 'phrases',
    'keyboard', 'tradition', 'onehand', 'handwriting', 'undo', 'ai', 'collapse',
  ];

  static const defaultPhrases = <Map<String, String>>[
    {'text': '你好，我在忙，稍后回复。', 'category': '工作'},
    {'text': '收到，谢谢！', 'category': '工作'},
    {'text': '好的，没问题。', 'category': '日常'},
    {'text': '辛苦啦，早点休息。', 'category': '日常'},
    {'text': '方便的时候联系我。', 'category': '工作'},
    {'text': '地址：北京市海淀区示例路 1 号', 'category': '地址'},
  ];

  static const defaultClipboard = <Map<String, String>>[
    {'text': '豆包输入法（复刻）演示文本', 'time': '刚刚'},
    {'text': '会议时间：周三 14:00，地点：三层会议室', 'time': '今天'},
    {'text': 'https://example.com/doubao-input-clone', 'time': '昨天'},
  ];

  static Future<AppState>? _loading;

  static Future<AppState> load() async {
    if (_instance != null) return _instance!;
    if (_loading != null) return _loading!;
    final future = _doLoad();
    _loading = future;
    return future;
  }

  static Future<AppState> _doLoad() async {
    final s = AppState._();
    s.prefs = await SharedPreferences.getInstance();
    final existingDid = s.prefs.getString(K.deviceId);
    if (existingDid == null) {
      final rnd = Random.secure();
      final did = List.generate(16, (_) => '0123456789abcdef'[rnd.nextInt(16)]).join();
      await s.prefs.setString(K.deviceId, 'DID-${did.toUpperCase()}');
    }
    if (!s.prefs.containsKey(K.commonPhrases)) {
      await s.prefs.setString(K.commonPhrases, jsonEncode(defaultPhrases));
    }
    if (!s.prefs.containsKey(K.clipboardItems)) {
      await s.prefs.setString(K.clipboardItems, jsonEncode(defaultClipboard));
    }
    if (!s.prefs.containsKey('messages_json')) {
      await s.prefs.setString('messages_json', jsonEncode([
        {'id': '1', 'title': '欢迎使用豆包输入法（复刻）', 'body': '这是净室复刻版，非官方产品。所有数据保存在本机。', 'time': '今天 09:00', 'read': false, 'category': '系统'},
        {'id': '2', 'title': '离线语音包已可下载', 'body': '在「语音转文字」中可体验模拟离线语音下载。', 'time': '昨天 18:20', 'read': false, 'category': '功能'},
        {'id': '3', 'title': '超级互传提示', 'body': '超级互传为本机演示，不会连接官方服务。', 'time': '10月18日', 'read': true, 'category': '功能'},
      ]));
    }
    if (!s.prefs.containsKey(K.fuzzyInitials)) {
      await s.prefs.setStringList(K.fuzzyInitials, const []);
    }
    if (!s.prefs.containsKey(K.fuzzyFinals)) {
      await s.prefs.setStringList(K.fuzzyFinals, const []);
    }
    if (!s.prefs.containsKey(K.fuzzySyllables)) {
      await s.prefs.setStringList(K.fuzzySyllables, const []);
    }
    try {
      final v = await _secure.read(key: K.aiKey);
      if (v != null && v.isNotEmpty) s._memoryKey = v;
    } catch (_) {
      s.secureStorageOk = false;
    }
    if (s._memoryKey.isEmpty) {
      s._memoryKey = s.prefs.getString('ai_key_fallback') ?? '';
    }
    s.loaded = true;
    _instance = s;
    return s;
  }

  // ---------------------------------------------------------------------------
  // Generic accessors. Every mutation is persisted synchronously in memory and
  // asynchronously flushed to disk; the UI is notified immediately.
  // ---------------------------------------------------------------------------
  Object? _default(String key) => _defaults[key];

  bool getBool(String key, {bool? fallback}) {
    final v = prefs.getBool(key);
    if (v != null) return v;
    final d = _default(key);
    return d is bool ? d : (fallback ?? false);
  }

  String getString(String key) {
    final v = prefs.getString(key);
    if (v != null) return v;
    final d = _default(key);
    return d is String ? d : '';
  }

  int getInt(String key) {
    final v = prefs.getInt(key);
    if (v != null) return v;
    final d = _default(key);
    return d is int ? d : 0;
  }

  double getDouble(String key, {double fallback = 0}) {
    final v = prefs.getDouble(key);
    if (v != null) return v;
    final i = prefs.getInt(key);
    if (i != null) return i.toDouble();
    final d = _default(key);
    return d is double ? d : (d is int ? d.toDouble() : fallback);
  }

  List<String> getList(String key) {
    final v = prefs.getStringList(key);
    if (v != null) return List<String>.of(v);
    final d = _default(key);
    if (d is List<String>) return List<String>.of(d);
    if (d is String) return d.split(',');
    return <String>[];
  }

  void _write(String key, Object value) {
    if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is int) {
      prefs.setInt(key, value);
    } else if (value is double) {
      prefs.setDouble(key, value);
    } else if (value is List<String>) {
      prefs.setStringList(key, value);
    } else {
      prefs.setString(key, value.toString());
    }
  }

  void setBool(String key, bool v) {
    _write(key, v);
    notifyListeners();
  }

  void setString(String key, String v) {
    _write(key, v);
    notifyListeners();
  }

  void setInt(String key, int v) {
    _write(key, v);
    notifyListeners();
  }

  void setDouble(String key, double v) {
    _write(key, v);
    notifyListeners();
  }

  void setList(String key, List<String> v) {
    _write(key, v);
    notifyListeners();
  }

  // Structured JSON list helpers.
  List<Map<String, dynamic>> jsonList(String key, List<Map<String, dynamic>> fallback) {
    final raw = prefs.getString(key);
    if (raw == null) return fallback.map((e) => Map<String, dynamic>.of(e)).toList();
    try {
      final v = jsonDecode(raw);
      if (v is List) {
        return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return fallback.map((e) => Map<String, dynamic>.of(e)).toList();
  }

  void _saveJsonList(String key, List<Map<String, dynamic>> list) {
    prefs.setString(key, jsonEncode(list));
    notifyListeners();
  }

  List<Map<String, dynamic>> get phrases => jsonList(K.commonPhrases, defaultPhrases);
  List<Map<String, dynamic>> get lexicon => jsonList(K.personalLexicon, const []);
  List<Map<String, dynamic>> get clipboardItems => jsonList(K.clipboardItems, defaultClipboard);
  List<Map<String, dynamic>> get messages => jsonList('messages_json', const []);
  List<Map<String, dynamic>> get feedbacks => jsonList('feedbacks_json', const []);
  List<Map<String, dynamic>> get devices => jsonList('transfer_devices_json', const []);

  // ---------------------------------------------------------------------------
  // Onboarding / modes
  // ---------------------------------------------------------------------------
  bool get onboardingDone => getBool(K.onboardingDone);
  String get privacyMode => getString(K.privacyMode);
  String get inputMode => getString(K.inputMode);
  bool get isSmartMode => privacyMode != 'basic' && inputMode != 'basic';

  void completeConsent(String mode) {
    setString(K.privacyMode, mode);
    setString(K.inputMode, mode);
    setBool(K.onboardingDone, true);
  }

  void setInputMode(String mode) {
    setString(K.inputMode, mode);
    setString(K.privacyMode, mode);
  }

  String get keyboardType => getString(K.keyboardType);
  bool get hasKeyboardType => keyboardType.isNotEmpty;
  void setKeyboardType(String v) => setString(K.keyboardType, v);

  ThemeMode get themeMode => switch (getString(K.themeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
  void setThemeMode(String v) => setString(K.themeMode, v);

  // ---------------------------------------------------------------------------
  // Voice
  // ---------------------------------------------------------------------------
  bool get voiceSmartOrganize => getBool(K.voiceSmartOrganize);
  String get voicePunctuation => getString(K.voicePunctuation);
  String get voiceFiller => getString(K.voiceFiller);
  bool get voiceOffline => getBool(K.voiceOffline);
  bool get voiceActionEnabled => getBool(K.voiceActionEnabled);
  List<String> get voiceActions => getList(K.voiceActions).isEmpty
      ? const ['帮我发送', '我说完了', '立即发送', '发送发送', 'overover']
      : getList(K.voiceActions);
  void setVoiceActions(List<String> v) => setList(K.voiceActions, v);
  String get offlineStatus => getString('voice_offline_status');
  double get offlineProgress => getDouble('voice_offline_progress');
  void setOfflineProgress(double v, String status) {
    setDouble('voice_offline_progress', v);
    setString('voice_offline_status', status);
  }

  // ---------------------------------------------------------------------------
  // Layout / keyboard
  // ---------------------------------------------------------------------------
  double get candidateFontSize => getDouble(K.candidateFontSize, fallback: 21).clamp(14, 28);
  String get pinyinLocation => getString(K.pinyinLocation);
  bool get enterSend => getBool(K.enterSend);
  String get oneHand => getString(K.oneHand);
  bool get floating => getBool(K.floating);
  int get keyboardHeight => getInt(K.keyboardHeight);
  List<String> get toolbar => getList(K.customToolbar).isEmpty ? defaultToolbar : getList(K.customToolbar);
  void setToolbar(List<String> v) => setList(K.customToolbar, v);
  String get toolbarAlign => getString('toolbar_align').isEmpty ? 'left' : getString('toolbar_align');
  List<String> get customSymbols {
    final v = getList('custom_symbols');
    return v.isEmpty ? const ['，', '。', '？', '！'] : v;
  }
  void setCustomSymbols(List<String> v) => setList('custom_symbols', v);
  int get keyboardGap => getInt('keyboard_gap');
  double get floatingScale => getDouble('floating_scale', fallback: 1).clamp(0.7, 1.0);
  String get shuangpinScheme => getString(K.shuangpinScheme);
  bool get traditional => getBool(K.traditional);

  // ---------------------------------------------------------------------------
  // AI
  // ---------------------------------------------------------------------------
  String get aiBaseUrl => getString(K.aiBaseUrl);
  String get aiModel => getString(K.aiModel);
  String get aiKeyEffective {
    if (_memoryKey.isNotEmpty) return _memoryKey;
    const injected = String.fromEnvironment('DEEPSEEK_API_KEY');
    return injected;
  }

  bool get aiConfigured => aiKeyEffective.isNotEmpty;
  bool get aiUsable => aiConfigured && isSmartMode;

  Future<void> setAiKey(String key) async {
    _memoryKey = key.trim();
    notifyListeners();
    try {
      await _secure.write(key: K.aiKey, value: _memoryKey);
      secureStorageOk = true;
      await prefs.remove('ai_key_fallback');
    } catch (_) {
      secureStorageOk = false;
      await prefs.setString('ai_key_fallback', _memoryKey);
    }
  }

  Future<void> clearAiKey() async {
    _memoryKey = '';
    try {
      await _secure.delete(key: K.aiKey);
    } catch (_) {}
    await prefs.remove('ai_key_fallback');
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Account / transfer
  // ---------------------------------------------------------------------------
  bool get loggedIn => getBool(K.accountLoggedIn);
  String get accountName => getString(K.accountName);
  void login(String name) {
    setBool(K.accountLoggedIn, true);
    setString(K.accountName, name);
  }
  void logout() {
    setBool(K.accountLoggedIn, false);
    setString(K.accountName, '');
    setBool(K.superTransferEnabled, false);
  }
  bool get superTransferEnabled => getBool(K.superTransferEnabled);
  String get deviceId => getString(K.deviceId);

  // ---------------------------------------------------------------------------
  // Lists / CRUD
  // ---------------------------------------------------------------------------
  void addPhrase(String text, String category) {
    final list = phrases..add({'text': text, 'category': category});
    _saveJsonList(K.commonPhrases, list);
  }

  void updatePhrase(int i, String text, String category) {
    final list = phrases;
    list[i] = {'text': text, 'category': category};
    _saveJsonList(K.commonPhrases, list);
  }

  void removePhrase(int i) {
    final list = phrases;
    list.removeAt(i);
    _saveJsonList(K.commonPhrases, list);
  }

  void addLexicon(String word, String pinyin, {bool contact = false}) {
    final list = lexicon
      ..add({'w': word, 'p': pinyin, 'f': 99999999, 'u': 1, if (contact) 'contact': true});
    _saveJsonList(K.personalLexicon, list);
  }

  void removeLexicon(int i) {
    final list = lexicon;
    list.removeAt(i);
    _saveJsonList(K.personalLexicon, list);
  }

  void addClipboard(String text) {
    if (text.trim().isEmpty) return;
    final list = clipboardItems;
    list.insert(0, {'text': text, 'time': '刚刚'});
    if (list.length > 100) list.removeRange(100, list.length);
    _saveJsonList(K.clipboardItems, list);
  }

  void removeClipboard(int i) {
    final list = clipboardItems;
    list.removeAt(i);
    _saveJsonList(K.clipboardItems, list);
  }

  void clearClipboard() => _saveJsonList(K.clipboardItems, const []);

  void addDevice(String name) {
    final list = devices..add({'name': name, 'id': 'DEV-${DateTime.now().millisecondsSinceEpoch % 100000}', 'last': '刚刚'});
    _saveJsonList('transfer_devices_json', list);
  }

  void removeDevice(int i) {
    final list = devices;
    list.removeAt(i);
    _saveJsonList('transfer_devices_json', list);
  }

  void addFeedback(String type, String text) {
    final list = feedbacks..insert(0, {
      'type': type,
      'text': text,
      'time': DateTime.now().toString().substring(0, 16),
    });
    _saveJsonList('feedbacks_json', list);
  }

  void deleteFeedback(int i) {
    final list = feedbacks;
    list.removeAt(i);
    _saveJsonList('feedbacks_json', list);
  }

  List<String> get learnedWords => getList('learned_words');
  void learnWord(String word) {
    if (word.trim().isEmpty) return;
    final list = learnedWords..remove(word);
    list.insert(0, word);
    if (list.length > 200) list.removeRange(200, list.length);
    setList('learned_words', list);
  }

  List<String> get deletedWords => getList('deleted_words');
  void deleteWord(String word) {
    final list = deletedWords..add(word);
    setList('deleted_words', list);
  }

  List<String> get recentEmoji => getList('recent_emoji');
  void addRecentEmoji(String e) {
    final list = recentEmoji..remove(e);
    list.insert(0, e);
    if (list.length > 32) list.removeRange(32, list.length);
    setList('recent_emoji', list);
  }

  void markMessageRead(String id) {
    final list = messages;
    for (final m in list) {
      if (m['id'] == id) m['read'] = true;
    }
    _saveJsonList('messages_json', list);
  }

  void deleteMessage(String id) {
    final list = messages..removeWhere((m) => m['id'] == id);
    _saveJsonList('messages_json', list);
  }

  void markAllMessagesRead() {
    final list = messages;
    for (final m in list) {
      m['read'] = true;
    }
    _saveJsonList('messages_json', list);
  }

  int get unreadMessages => messages.where((m) => m['read'] != true).length;

  // Reset helpers used by the layout page.
  void resetKeyboardTuning() {
    setInt(K.keyboardHeight, 340);
    setInt('keyboard_gap', 0);
    setDouble('floating_scale', 1);
    setInt(K.candidateFontSize, 21);
    notifyListeners();
  }
}
