import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';
import '../../core/pinyin_engine.dart';
import '../../core/stroke_engine.dart';
import '../../theme.dart';
import '../widgets.dart';
import 'keyboard_controller.dart';

const _swipeNumbers = '1234567890';
const _swipeSymbols = {
  'a': '-', 's': '/', 'd': ':', 'f': ';', 'g': '(', 'h': ')', 'j': '～',
  'k': '"', 'l': '”', 'q': '@', 'w': '#', 'e': '¥', 'r': '&', 't': '*',
  'y': '、', 'u': '_', 'i': '+', 'o': '=', 'p': '|', 'z': '@', 'x': '.',
  'c': '#', 'v': '、', 'b': '？', 'n': '！', 'm': '，',
};

void _showKeyBubble(
  BuildContext context,
  String letter, {
  required ValueChanged<String> onPick,
}) {
  final box = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context);
  final size = MediaQuery.sizeOf(context);
  final offset = box?.localToGlobal(Offset.zero) ?? Offset(size.width / 2, size.height - 200);
  final digit = letter.length == 1 && RegExp('[qwertyuiop]').hasMatch(letter)
      ? _swipeNumbers['qwertyuiop'.indexOf(letter)]
      : null;
  final symbol = _swipeSymbols[letter] ?? '';
  final variants = <String>[
    letter,
    letter.toUpperCase(),
    if (digit != null) digit,
    if (symbol.isNotEmpty) symbol,
  ];
  late OverlayEntry entry;
  var closed = false;
  void close() {
    if (closed) return;
    closed = true;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) {
      final left = (offset.dx - 70).clamp(8.0, size.width - 228);
      final top = (offset.dy - 76).clamp(8.0, size.height - 100);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: close,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: context.pal.card,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final v in variants)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            close();
                            onPick(v);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: context.pal.pageBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(v,
                                  style: TextStyle(
                                    fontSize: v.length == 1 ? 22 : 16,
                                    color: context.pal.text,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  overlay.insert(entry);
  Timer(const Duration(seconds: 3), close);
}


void _keyFeedback() {
  final s = AppState.I;
  if (s.getBool(K.keySound) &&
      s.getDouble('key_sound_volume', fallback: 60) > 0) {
    SystemSound.play(SystemSoundType.click);
  }
  if (s.getBool(K.keyVibrate)) {
    final level = s.getInt(K.keyVibrateLevel);
    if (level <= 1) {
      HapticFeedback.selectionClick();
    } else if (level == 2) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }
}

void _showTapBubble(BuildContext context, String label) {
  if (!AppState.I.getBool(K.keyBubble) || label.length != 1) return;
  if (!RegExp(r'[a-zA-Z]').hasMatch(label)) return;
  final box = context.findRenderObject() as RenderBox?;
  if (box == null) return;
  final size = MediaQuery.sizeOf(context);
  final offset = box.localToGlobal(Offset.zero);
  final entry = OverlayEntry(
    builder: (_) {
      final left = (offset.dx + box.size.width / 2 - 24).clamp(4.0, size.width - 52);
      final top = (offset.dy - 56).clamp(4.0, size.height - 60);
      return Positioned(
        left: left,
        top: top,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 48,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.pal.card,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: context.pal.text,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Overlay.of(context).insert(entry);
  Timer(const Duration(milliseconds: 180), () {
    try {
      entry.remove();
    } catch (_) {}
  });
}

class KeyCap extends StatefulWidget {
  final String label;
  final int flex;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeUp;
  final Color? color;
  final Color? textColor;
  final double fontSize;
  final IconData? icon;
  final Widget? child;
  final EdgeInsets margin;

  const KeyCap({
    super.key,
    this.label = '',
    this.flex = 1,
    this.onTap,
    this.onLongPress,
    this.onSwipeUp,
    this.color,
    this.textColor,
    this.fontSize = 20,
    this.icon,
    this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
  });

  @override
  State<KeyCap> createState() => _KeyCapState();
}

class _KeyCapState extends State<KeyCap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bg = widget.color ?? p.key;
    final fg = widget.textColor ?? p.text;
    return Expanded(
      flex: widget.flex,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _pressed = true);
          _keyFeedback();
          if (widget.label.length == 1) _showTapBubble(context, widget.label);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onVerticalDragEnd: widget.onSwipeUp == null
            ? null
            : (details) {
                if ((details.primaryVelocity ?? 0) < -80) {
                  widget.onSwipeUp!();
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: widget.margin,
          decoration: BoxDecoration(
            color: _pressed ? Color.alphaBlend(Colors.black.withValues(alpha: 0.09), bg) : bg,
            borderRadius: BorderRadius.circular(T.radiusKey),
            boxShadow: [
              if (bg == p.key || widget.color == null)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Center(
            child: widget.child ??
                (widget.icon != null
                    ? Icon(widget.icon, size: widget.fontSize + 2, color: fg)
                    : Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          color: fg,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      )),
          ),
        ),
      ),
    );
  }
}

class BackspaceKey extends StatefulWidget {
  final KeyboardController controller;
  final int flex;
  const BackspaceKey({super.key, required this.controller, this.flex = 1});

  @override
  State<BackspaceKey> createState() => _BackspaceKeyState();
}

class _BackspaceKeyState extends State<BackspaceKey> {
  Timer? _timer;
  bool _pressed = false;

  void _start() {
    widget.controller.onBackspace();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      widget.controller.onBackspace();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Expanded(
      flex: widget.flex,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          setState(() => _pressed = true);
          _keyFeedback();
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => widget.controller.onBackspace(),
        onLongPressStart: (_) => _start(),
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: _pressed
                ? Color.alphaBlend(Colors.black.withValues(alpha: 0.12), p.keyFunc)
                : p.keyFunc,
            borderRadius: BorderRadius.circular(T.radiusKey),
          ),
          child: Icon(Icons.backspace_outlined, size: 21, color: p.text),
        ),
      ),
    );
  }
}

class KeyboardToolbar extends StatelessWidget {
  final KeyboardController c;
  final VoidCallback onToolbox;
  final VoidCallback onVoice;
  final void Function(String panel) onPanel;
  final VoidCallback onSettings;
  final VoidCallback onCollapse;

  const KeyboardToolbar({
    super.key,
    required this.c,
    required this.onToolbox,
    required this.onVoice,
    required this.onPanel,
    required this.onSettings,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final items = s.toolbar;
    final widgets = <Widget>[];
    for (final id in items) {
      switch (id) {
        case 'toolbox':
          widgets.add(_ToolbarIcon(
            icon: Icons.apps_rounded,
            tooltip: '工具箱',
            onTap: onToolbox,
            badge: true,
          ));
          break;
        case 'voice':
          widgets.add(_VoicePill(onTap: onVoice));
          break;
        case 'clipboard':
          widgets.add(_ToolbarIcon(
              icon: Icons.content_paste_rounded,
              tooltip: '剪切板',
              onTap: () => onPanel('clipboard')));
          break;
        case 'translate':
          widgets.add(_ToolbarIcon(
              icon: Icons.translate_rounded,
              tooltip: '翻译',
              onTap: () => onPanel('translate')));
          break;
        case 'emoji':
          widgets.add(_ToolbarIcon(
              icon: Icons.emoji_emotions_outlined,
              tooltip: '表情',
              onTap: () => onPanel('emoji')));
          break;
        case 'phrases':
          widgets.add(_ToolbarIcon(
              icon: Icons.format_quote_rounded,
              tooltip: '常用语',
              onTap: () => onPanel('phrases')));
          break;
        case 'keyboard':
          widgets.add(_ToolbarIcon(
              icon: Icons.keyboard_rounded,
              tooltip: '键盘选择',
              onTap: () => onPanel('keyboard')));
          break;
        case 'tradition':
          widgets.add(InkWell(
            onTap: c.toggleTraditional,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(s.traditional ? '繁' : '简',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: p.primary,
                    )),
              ),
            ),
          ));
          break;
        case 'onehand':
          widgets.add(_ToolbarIcon(
              icon: Icons.phone_iphone_rounded,
              tooltip: '单手',
              onTap: () => onPanel('onehand')));
          break;
        case 'handwriting':
          widgets.add(_ToolbarIcon(
              icon: Icons.gesture_rounded,
              tooltip: '手写找字',
              onTap: () => onPanel('handwriting')));
          break;
        case 'undo':
          widgets.add(_ToolbarIcon(
              icon: Icons.undo_rounded,
              tooltip: '撤销删除',
              onTap: c.undoDelete));
          break;
        case 'ai':
          widgets.add(_ToolbarIcon(
              icon: Icons.auto_awesome_rounded,
              tooltip: 'AI',
              onTap: () => onPanel('ai'),
              color: p.primary));
          break;
        case 'collapse':
          widgets.add(_ToolbarIcon(
              icon: Icons.keyboard_arrow_down_rounded,
              tooltip: '收起键盘',
              onTap: onCollapse));
          break;
        default:
          break;
      }
    }
    return Container(
      height: 48,
      color: p.keyboardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: s.toolbarAlign == 'right',
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment:
              s.toolbarAlign == 'right' ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: widgets,
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;
  final Color? color;

  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, size: 20, color: color ?? p.text)),
              if (badge)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoicePill extends StatelessWidget {
  final VoidCallback onTap;
  const _VoicePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(Icons.mic_none_rounded, size: 18, color: p.primary),
            const SizedBox(width: 5),
            Text('点击说话', style: TextStyle(fontSize: 13, color: p.text)),
          ],
        ),
      ),
    );
  }
}

class CandidateBar extends StatelessWidget {
  final KeyboardController c;
  final VoidCallback onExpand;
  final VoidCallback onVoice;
  final VoidCallback onClosePanel;
  final bool panelOpen;

  const CandidateBar({
    super.key,
    required this.c,
    required this.onExpand,
    required this.onVoice,
    required this.onClosePanel,
    this.panelOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final fs = s.candidateFontSize;
    final composing = c.composing.isNotEmpty;
    final height = composing ? 66.0 : 46.0;
    return Container(
      height: height,
      color: p.keyboardBg,
      child: panelOpen
          ? Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text('面板',
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                ),
                TextButton(onPressed: onClosePanel, child: const Text('返回键盘')),
              ],
            )
          : (c.isHandwriting
              ? _handwritingCandidates(context, p, fs)
              : (c.isStroke
                  ? _strokeCandidates(context, p, fs)
                  : (c.chinese
                      ? _chineseCandidates(context, p, fs)
                      : _englishCandidates(context, p, fs)))),
    );
  }

  Widget _chineseCandidates(BuildContext context, AppPalette p, double fs) {
    if (c.composing.isNotEmpty) {
      return Column(
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.isWubi
                        ? '五笔 ${c.composing}'
                        : (c.isShuangpin
                            ? '${AppScope.of(context).shuangpinScheme} ${c.composing}'
                            : c.composing),
                    style: TextStyle(fontSize: 11.5, color: p.primary),
                  ),
                ),
                if (c.isWubi && AppScope.of(context).getBool(K.wubiHint)) ...[
                  const SizedBox(width: 6),
                  Text('86版',
                      style: TextStyle(fontSize: 10, color: p.textSecondary)),
                ],
                const Spacer(),
                if (c.lastQueryMicros != null && c.lastQueryMicros! > 0)
                  Text('${(c.lastQueryMicros! / 1000).toStringAsFixed(1)} ms',
                      style: TextStyle(fontSize: 9, color: p.textSecondary)),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: c.visibleCandidates.isEmpty
                      ? Center(
                          child: Text('暂无候选，点击空格上屏原文',
                              style: TextStyle(fontSize: 12, color: p.textSecondary)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: c.visibleCandidates.length,
                          itemBuilder: (context, i) {
                            final cand = c.visibleCandidates[i];
                            return _CandidateItem(
                              text: cand.text,
                              fontSize: fs,
                              highlight: i == 0,
                              onTap: () => c.commitCandidate(cand),
                              onLongPress: () => _candidateSheet(context, cand),
                            );
                          },
                        ),
                ),
                if (c.pageCount > 1) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: c.prevPage,
                    icon: Icon(Icons.chevron_left_rounded,
                        size: 20, color: p.textSecondary.withValues(alpha: 0.7)),
                  ),
                  Text('${c.candidatePage + 1}/${c.pageCount}',
                      style: TextStyle(fontSize: 9, color: p.textSecondary)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: c.nextPage,
                    icon: Icon(Icons.chevron_right_rounded,
                        size: 20, color: p.textSecondary.withValues(alpha: 0.7)),
                  ),
                ],
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: '更多候选',
                  onPressed: onExpand,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 22, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final chips = <Widget>[];
    if (c.associations.isNotEmpty) {
      for (final a in c.associations) {
        chips.add(_SuggestionChip(
          text: a,
          icon: Icons.subdirectory_arrow_right_rounded,
          onTap: () => c.commitPrediction(a),
        ));
      }
    }
    if (c.predictions.isNotEmpty) {
      for (final e in c.predictions) {
        chips.add(_SuggestionChip(text: e, onTap: () => c.commitPrediction(e)));
      }
    }
    if (AppScope.of(context).getBool('clipboard_consent') &&
        AppScope.of(context).getBool(K.clipboardCandidate) &&
        AppScope.of(context).clipboardItems.isNotEmpty) {
      final t = (AppScope.of(context).clipboardItems.first['text'] ?? '').toString();
      chips.add(_SuggestionChip(
        text: '剪贴板 · ${t.length > 10 ? '${t.substring(0, 10)}…' : t}',
        icon: Icons.content_paste_rounded,
        onTap: () => c.insertText(t),
      ));
    }
    if (chips.isEmpty) {
      return Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.mic_none_rounded, size: 16, color: p.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              c.lastCommitted == null ? '点击说话，或使用下方键盘输入' : '继续输入，或点击联想词',
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '语音输入',
            onPressed: onVoice,
            icon: Icon(Icons.mic_rounded, size: 19, color: p.primary),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '更多候选',
            onPressed: onExpand,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: p.textSecondary),
          ),
        ],
      );
    }
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final chip in chips)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Center(child: chip),
                ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '更多候选',
          onPressed: onExpand,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: p.textSecondary),
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  Widget _englishCandidates(BuildContext context, AppPalette p, double fs) {
    final suggestions = c.englishSuggestions;
    return Row(
      children: [
        const SizedBox(width: 10),
        Text('EN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.primary)),
        const SizedBox(width: 8),
        Expanded(
          child: suggestions.isEmpty
              ? Text('英文输入 · 双击空格补句号',
                  style: TextStyle(fontSize: 12, color: p.textSecondary))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  itemBuilder: (context, i) => _CandidateItem(
                    text: suggestions[i],
                    fontSize: fs * 0.85,
                    highlight: i == 0,
                    onTap: () => c.applyEnglishSuggestion(suggestions[i]),
                  ),
                ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '更多候选',
          onPressed: onExpand,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: p.textSecondary),
        ),
      ],
    );
  }

  Widget _handwritingCandidates(BuildContext context, AppPalette p, double fs) {
    if (c.handwritingLoading) {
      return Center(
        child: Text('手写识别准备中…',
            style: TextStyle(fontSize: 12, color: p.textSecondary)),
      );
    }
    if (c.handwritingCandidates.isEmpty) {
      return Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.gesture_rounded, size: 16, color: p.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              c.strokes.isEmpty
                  ? '在下方手写区书写，停顿后自动识别'
                  : (c.recognizing ? '识别中…' : '没有把握，换个写法试试'),
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onExpand,
            child: const Text('手写找字', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
    return Row(
      children: [
        const SizedBox(width: 8),
        Text(c.handwritingConfident ? '识别' : '可能是',
            style: TextStyle(fontSize: 10, color: p.textSecondary)),
        const SizedBox(width: 4),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: c.handwritingCandidates.length,
            itemBuilder: (context, i) {
              final text = c.handwritingCandidates[i];
              return _CandidateItem(
                text: text,
                fontSize: fs + 4,
                highlight: i == 0,
                onTap: () => c.commitHandwriting(text),
              );
            },
          ),
        ),
        TextButton(
          onPressed: onExpand,
          child: const Text('更多', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _strokeCandidates(BuildContext context, AppPalette p, double fs) {
    final list = c.strokeCandidates;
    return Row(
      children: [
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: p.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(c.strokeCode.isEmpty ? '笔画' : describeStroke(c.strokeCode),
              style: TextStyle(fontSize: 10.5, color: p.primary)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: list.isEmpty
              ? Text(c.strokeCode.isEmpty ? '使用横竖撇捺折输入' : '没有匹配，点击 * 通配',
                  style: TextStyle(fontSize: 12, color: p.textSecondary))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  itemBuilder: (context, i) => _CandidateItem(
                    text: list[i].char,
                    fontSize: fs + 4,
                    highlight: i == 0,
                    onTap: () {
                      c.insertText(list[i].char);
                      c.clearStroke();
                    },
                  ),
                ),
        ),
        TextButton(
          onPressed: c.clearStroke,
          child: const Text('清空', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  void _candidateSheet(BuildContext context, Cand cand) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cand.text, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('拼音：${cand.pinyin} · 来源：${cand.source}',
                  style: TextStyle(fontSize: 12, color: context.pal.textSecondary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton('从本机删除此词',
                        icon: Icons.delete_outline_rounded,
                        onPressed: () {
                          Navigator.pop(ctx);
                          c.deleteCandidate(cand);
                        }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton('上屏',
                        onPressed: () {
                          Navigator.pop(ctx);
                          c.commitCandidate(cand);
                        }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateItem extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool highlight;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CandidateItem({
    required this.text,
    required this.fontSize,
    this.highlight = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minWidth: 34),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: highlight ? p.primary : p.text,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: p.primary),
              const SizedBox(width: 3),
            ],
            Text(text, style: TextStyle(fontSize: 12.5, color: p.text)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QWERTY
// ---------------------------------------------------------------------------
class QwertyKeyboard extends StatelessWidget {
  final KeyboardController c;
  const QwertyKeyboard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final split = s.getBool('comma_period_split', fallback: true);
    final cnLeft = s.getBool('cn_en_left');
    final swipe = s.getBool('swipe_symbols', fallback: true);
    if (c.numberLayout) return _NumberKeyboard(c: c, symbols: c.symbolLayout);
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
      child: Column(
        children: [
          Expanded(child: _row(context, 'qwertyuiop', c, swipe)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                ...'asdfghjkl'.split('').map((k) => _letter(context, k, c, swipe)),
                const Spacer(flex: 1),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _shiftKey(context, c),
                ...'zxcvbnm'.split('').map((k) => _letter(context, k, c, swipe, flex: 2)),
                BackspaceKey(controller: c, flex: 3),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyCap(
                  label: '123',
                  flex: 12,
                  fontSize: 13,
                  color: p.keyFunc,
                  onTap: () {
                    c.numberLayout = true;
                    c.symbolLayout = false;
                    c.refreshUI();
                  },
                  onLongPress: () {
                    c.numberLayout = true;
                    c.symbolLayout = true;
                    c.refreshUI();
                  },
                ),
                if (split) ...[
                  KeyCap(
                    label: '，',
                    flex: 9,
                    fontSize: 18,
                    color: p.key,
                    onTap: () => c.onPunctuation('，'),
                    onLongPress: c.onSeparator,
                  ),
                  KeyCap(
                    label: '。',
                    flex: 9,
                    fontSize: 18,
                    color: p.key,
                    onTap: () => c.onPunctuation('。'),
                  ),
                ] else
                  KeyCap(
                    label: '，。',
                    flex: 12,
                    fontSize: 15,
                    color: p.key,
                    onTap: () {
                      final last = c.text.text.isEmpty ? '' : c.text.text[c.text.text.length - 1];
                      c.onPunctuation(last == '，' ? '。' : '，');
                    },
                    onLongPress: c.onSeparator,
                  ),
                KeyCap(
                  flex: 42,
                  color: p.key,
                  onTap: c.onSpace,
                  onLongPress: () => c.openVoicePanel(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.graphic_eq_rounded, size: 18, color: p.textSecondary),
                      const SizedBox(width: 8),
                      Text('空格',
                          style: TextStyle(fontSize: 13, color: p.textSecondary)),
                    ],
                  ),
                ),
                if (cnLeft) _cnKey(context, c),
                KeyCap(
                  label: AppScope.of(context).enterSend ? '发送' : '换行',
                  flex: 16,
                  fontSize: 14,
                  color: p.primary,
                  textColor: Colors.white,
                  onTap: c.onEnter,
                  onLongPress: () {
                    final st = AppScope.of(context);
                    st.setBool(K.enterSend, !st.enterSend);
                    if (c.toast != null) c.toast!('回车键：${st.enterSend ? '发送' : '换行'}');
                    c.refreshUI();
                  },
                ),
                if (!cnLeft) _cnKey(context, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String letters, KeyboardController c, bool swipe) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: letters.split('').map((k) => _letter(context, k, c, swipe)).toList(),
    );
  }

  Widget _letter(BuildContext context, String k, KeyboardController c, bool swipe, {int flex = 1}) {
    final upper = c.caps || c.shift;
    final idx = 'qwertyuiop'.indexOf(k);
    final digit = idx >= 0 ? _swipeNumbers[idx] : null;
    return KeyCap(
      label: upper ? k.toUpperCase() : k,
      flex: flex,
      fontSize: 20,
      onTap: () => c.onLetter(k),
      onLongPress: () => _showKeyBubble(
        context,
        k,
        onPick: (v) {
          if (RegExp('[a-zA-Z]').hasMatch(v) && v.length == 1) {
            c.insertText(v, applyScript: false);
          } else {
            c.insertText(v, applyScript: false);
          }
          c.shift = false;
          c.refreshUI();
        },
      ),
      onSwipeUp: swipe
          ? () => c.insertText(digit ?? _swipeSymbols[k] ?? '', applyScript: false)
          : null,
    );
  }

  Widget _shiftKey(BuildContext context, KeyboardController c) {
    final p = context.pal;
    return Expanded(
      flex: 3,
      child: GestureDetector(
        onTap: () {
          _keyFeedback();
          c.onShift();
        },
        onDoubleTap: () {
          c.caps = true;
          c.shift = false;
          c.refreshUI();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: c.caps || c.shift ? p.primary : p.keyFunc,
            borderRadius: BorderRadius.circular(T.radiusKey),
          ),
          child: Icon(
            c.caps ? Icons.keyboard_capslock_rounded : Icons.arrow_upward_rounded,
            size: 19,
            color: c.caps || c.shift ? Colors.white : p.text,
          ),
        ),
      ),
    );
  }

  Widget _cnKey(BuildContext context, KeyboardController c) {
    final p = context.pal;
    return KeyCap(
      flex: 16,
      color: c.chinese ? p.key : p.primary,
      textColor: c.chinese ? p.text : Colors.white,
      onTap: c.toggleChinese,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(c.chinese ? '中' : '英',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.chinese ? p.text : Colors.white,
              )),
          Text(c.chinese ? 'EN' : '中',
              style: TextStyle(
                fontSize: 7,
                color: c.chinese ? p.textSecondary : Colors.white.withValues(alpha: 0.85),
              )),
        ],
      ),
    );
  }

}

class _NumberKeyboard extends StatelessWidget {
  final KeyboardController c;
  final bool symbols;
  const _NumberKeyboard({required this.c, required this.symbols});

  static const _numRows = <String>['1234567890', '-/:;()¥&@"', '.,?!\'\u3000'];
  static const _symRows = <String>['[]{}#%^*+=', '_\\|~<>€£¥•', '.,?!\''];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final rows = symbols ? _symRows : _numRows;
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
      child: Column(
        children: [
          for (final row in rows)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final k in row.split(''))
                    KeyCap(
                      label: k == '\u3000' ? ' ' : k,
                      fontSize: 17,
                      onTap: () => c.insertText(k, applyScript: false),
                    ),
                  if (row == rows.last)
                    BackspaceKey(controller: c, flex: 2),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyCap(
                  label: symbols ? 'ABC' : '符号',
                  flex: 16,
                  fontSize: 13,
                  color: p.keyFunc,
                  onTap: () {
                    if (symbols) {
                      c.numberLayout = false;
                      c.symbolLayout = false;
                    } else {
                      c.symbolLayout = true;
                    }
                    c.refreshUI();
                  },
                ),
                if (!symbols)
                  KeyCap(
                    label: '符号',
                    flex: 12,
                    fontSize: 13,
                    color: p.keyFunc,
                    onTap: () {
                      c.symbolLayout = true;
                      c.refreshUI();
                    },
                  )
                else
                  KeyCap(
                    label: '123',
                    flex: 12,
                    fontSize: 13,
                    color: p.keyFunc,
                    onTap: () {
                      c.symbolLayout = false;
                      c.refreshUI();
                    },
                  ),
                KeyCap(
                  flex: 40,
                  color: p.key,
                  onTap: c.onSpace,
                  child: Icon(Icons.space_bar_rounded, size: 20, color: p.textSecondary),
                ),
                KeyCap(
                  label: '中/英',
                  flex: 16,
                  fontSize: 12,
                  color: p.key,
                  onTap: c.toggleChinese,
                ),
                KeyCap(
                  label: AppScope.of(context).enterSend ? '发送' : '换行',
                  flex: 16,
                  fontSize: 13,
                  color: p.primary,
                  textColor: Colors.white,
                  onTap: c.onEnter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 9 key
// ---------------------------------------------------------------------------
class NineKeyboard extends StatelessWidget {
  final KeyboardController c;
  const NineKeyboard({super.key, required this.c});

  static const _keys = <List<String>>[
    ['1', '，'], ['2', 'ABC'], ['3', 'DEF'],
    ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
    ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
    ['*', '分词'], ['0', '空格'], ['#', '符号'],
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    final symbols = s.customSymbols;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: KeyCap(
                            label: symbols[i % symbols.length],
                            flex: 1,
                            fontSize: 16,
                            color: p.keyFunc,
                            onTap: () => c.onPunctuation(symbols[i % symbols.length]),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      for (var r = 0; r < 4; r++)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var col = 0; col < 3; col++)
                                _t9Key(context, c, _keys[r * 3 + col]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 46,
                  child: Column(
                    children: [
                      BackspaceKey(controller: c, flex: 1),
                      Expanded(
                        child: KeyCap(
                          label: '重输',
                          flex: 1,
                          fontSize: 12,
                          color: p.keyFunc,
                          onTap: () {
                            c.composing = '';
                            c.candidates = [];
                            c.candidatePage = 0;
                            c.refreshUI();
                          },
                        ),
                      ),
                      Expanded(
                        child: KeyCap(
                          label: '收起',
                          flex: 1,
                          fontSize: 10,
                          color: p.keyFunc,
                          onTap: c.toggleCollapse,
                        ),
                      ),
                      Expanded(
                        child: KeyCap(
                          label: '符',
                          flex: 1,
                          fontSize: 14,
                          color: p.keyFunc,
                          onTap: () => c.setPanel('emoji'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyCap(
                  label: '符号',
                  flex: 12,
                  fontSize: 12,
                  color: p.keyFunc,
                  onTap: () {
                    c.numberLayout = true;
                    c.symbolLayout = true;
                    c.refreshUI();
                  },
                ),
                KeyCap(
                  label: '123',
                  flex: 10,
                  fontSize: 12,
                  color: p.keyFunc,
                  onTap: () {
                    c.numberLayout = true;
                    c.symbolLayout = false;
                    c.refreshUI();
                  },
                ),
                KeyCap(
                  flex: 30,
                  color: p.key,
                  onTap: c.onSpace,
                  onLongPress: () => c.openVoicePanel(),
                  child: Icon(Icons.graphic_eq_rounded, size: 20, color: p.textSecondary),
                ),
                KeyCap(
                  label: '中/英',
                  flex: 12,
                  fontSize: 11,
                  color: p.key,
                  onTap: c.toggleChinese,
                ),
                KeyCap(
                  label: AppScope.of(context).enterSend ? '发送' : '换行',
                  flex: 15,
                  fontSize: 12,
                  color: p.primary,
                  textColor: Colors.white,
                  onTap: c.onEnter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _t9Key(BuildContext context, KeyboardController c, List<String> key) {
    final p = context.pal;
    final digit = key[0];
    final letters = key[1];
    final isDigit = digit.codeUnitAt(0) >= 50 && digit.codeUnitAt(0) <= 57;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _keyFeedback();
          if (digit == '0') {
            c.onSpace();
          } else if (digit == '*') {
            c.onSeparator();
          } else if (digit == '#') {
            c.numberLayout = true;
            c.symbolLayout = true;
            c.refreshUI();
          } else if (isDigit) {
            c.onDigit(digit);
          } else {
            c.onPunctuation(letters);
          }
        },
        onLongPress: isDigit ? () {
          c.insertText(digit, applyScript: false);
          if (c.toast != null) c.toast!('长按输入数字 $digit');
        } : null,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: p.key,
            borderRadius: BorderRadius.circular(T.radiusKey),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(digit,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: p.text)),
              Text(letters,
                  style: TextStyle(fontSize: 8.5, color: p.textSecondary, height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stroke keyboard
// ---------------------------------------------------------------------------
class StrokeKeyboard extends StatelessWidget {
  final KeyboardController c;
  const StrokeKeyboard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const labels = ['横', '竖', '撇', '点', '折'];
    const codes = ['1', '2', '3', '4', '5'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        _keyFeedback();
                        c.onStroke(codes[i]);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: p.key,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(labels[i],
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w500, color: p.text)),
                            const SizedBox(height: 4),
                            Text('${i + 1}',
                                style: TextStyle(fontSize: 10, color: p.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyCap(
                  label: '*',
                  fontSize: 20,
                  color: p.keyFunc,
                  onTap: () => c.onStroke('*'),
                ),
                KeyCap(
                  label: '删除',
                  fontSize: 13,
                  color: p.keyFunc,
                  onTap: c.onBackspace,
                ),
                KeyCap(
                  label: '清空',
                  fontSize: 13,
                  color: p.keyFunc,
                  onTap: c.clearStroke,
                ),
                KeyCap(
                  flex: 2,
                  color: p.key,
                  onTap: c.onSpace,
                  child: Text('空格', style: TextStyle(fontSize: 13, color: p.textSecondary)),
                ),
                KeyCap(
                  label: '收起',
                  fontSize: 12,
                  color: p.keyFunc,
                  onTap: c.toggleCollapse,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
