import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/pinyin_engine.dart';
import '../../theme.dart';
import '../widgets.dart';
import 'handwriting_pad.dart';
import 'key_views.dart';
import 'keyboard_controller.dart';
import 'panels.dart';
import 'voice_overlay.dart';

class KeyboardDemoPage extends StatefulWidget {
  final String? initialPanel;
  final String? initialMode;
  final String? initialComposing;
  const KeyboardDemoPage({super.key, this.initialPanel, this.initialMode, this.initialComposing});

  @override
  State<KeyboardDemoPage> createState() => _KeyboardDemoPageState();
}

class _KeyboardDemoPageState extends State<KeyboardDemoPage> {
  late final KeyboardController c;
  Offset _floatOffset = const Offset(20, 160);
  bool _snapped = false;

  @override
  void initState() {
    super.initState();
    c = KeyboardController(initialPanel: widget.initialPanel);
    if (widget.initialMode != null && widget.initialMode!.isNotEmpty) {
      c.mode = widget.initialMode!;
      AppState.I.setKeyboardType(widget.initialMode!);
      c.refreshCandidates();
    }
    if (widget.initialComposing != null && widget.initialComposing!.isNotEmpty) {
      c.composing = widget.initialComposing!;
      c.refreshCandidates();
    }
    c.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted && c.isHandwriting) c.ensureHandwritingReady();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    c.toast = (m) => toast(context, m);
  }

  @override
  void dispose() {
    c.removeListener(_onControllerChanged);
    c.dispose();
    super.dispose();
  }

  void _voice() {
    showVoiceOverlay(context, c);
  }

  void _navigate(String route) {
    c.setPanel(null);
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppScope.of(context);
    return Scaffold(
      backgroundColor: p.pageBg,
      appBar: AppBar(
        title: const Text('键盘体验'),
        actions: [
          IconButton(
            tooltip: '布局与显示',
            onPressed: () => _navigate('/layout'),
            icon: const Icon(Icons.tune_rounded, size: 21),
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (v) => _navigate(v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: '/keyboard-types', child: Text('键盘类型')),
              PopupMenuItem(value: '/key-feedback', child: Text('按键反馈')),
              PopupMenuItem(value: '/ai-settings', child: Text('AI 服务配置')),
              PopupMenuItem(value: '/permissions', child: Text('系统权限')),
              PopupMenuItem(value: '/help', child: Text('帮助与反馈')),
              PopupMenuItem(value: '/about', child: Text('关于')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final desired = s.keyboardHeight.toDouble();
            var keyboardH = desired;
            if (wide && !landscape) keyboardH = min(desired, 430.0);
            if (landscape) keyboardH = min(desired, min(constraints.maxHeight * 0.58, 400.0));
            keyboardH = min(keyboardH, constraints.maxHeight - 120);
            keyboardH = max(keyboardH, 230.0);
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            final maxW = min(960.0, constraints.maxWidth);

            final keyboard = _buildKeyboard(context, s, keyboardH, maxW);
            Widget normal = keyboard;
            if (s.oneHand != 'off') {
              normal = Align(
                alignment: s.oneHand == 'left' ? Alignment.bottomLeft : Alignment.bottomRight,
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: keyboard,
                ),
              );
            }

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: _inputArea(context, s, p)),
                    if (!s.floating) ...[
                      if (!c.collapsed)
                        SizedBox(
                          height: (s.keyboardHeight.toDouble() - keyboardH) > 0
                              ? keyboardH
                              : keyboardH,
                          child: normal,
                        ),
                      if (c.collapsed) _collapsedBar(context, p),
                      SizedBox(height: bottomInset),
                    ] else
                      SizedBox(height: bottomInset),
                  ],
                ),
                if (s.floating && !c.collapsed)
                  _floatingKeyboard(context, s, constraints, keyboardH, keyboard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _inputArea(BuildContext context, AppState s, AppPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppMark(size: 32),
              const SizedBox(width: 8),
              Text('输入演示',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(width: 8),
              TagChip(c.modeName, color: p.primary),
              const Spacer(),
              TagChip(s.isSmartMode ? '智能模式' : '基础模式',
                  color: s.isSmartMode ? p.primary : const Color(0xFF23A26D)),
            ],
          ),
          const SizedBox(height: 10),
          if (s.pinyinLocation == '输入框上方' && c.composing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text('拼音：',
                      style: TextStyle(fontSize: 11, color: p.textSecondary)),
                  Text(c.composing,
                      style: TextStyle(
                          fontSize: 13, color: p.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('${(PinyinEngine.instance.lastQueryMicros / 1000).toStringAsFixed(1)} ms',
                      style: TextStyle(fontSize: 9, color: p.textSecondary)),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.divider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              controller: c.text,
              focusNode: c.focus,
              readOnly: true,
              showCursor: true,
              enableInteractiveSelection: true,
              maxLines: 6,
              minLines: 3,
              style: TextStyle(fontSize: 16, color: p.text, height: 1.5),
              onTap: () => c.focus.requestFocus(),
              decoration: InputDecoration(
                hintText: '点击输入框，再用下方键盘输入…',
                hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '系统键盘不会弹出 · 点击候选上屏 · 长按字母/候选有更多操作',
                  style: TextStyle(fontSize: 10, color: p.textSecondary),
                  maxLines: 2,
                ),
              ),
              IconButton(
                tooltip: '复制全部',
                visualDensity: VisualDensity.compact,
                onPressed: c.copyAll,
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
              IconButton(
                tooltip: '清空',
                visualDensity: VisualDensity.compact,
                onPressed: c.clearText,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
              IconButton(
                tooltip: '收起/显示键盘',
                visualDensity: VisualDensity.compact,
                onPressed: c.toggleCollapse,
                icon: Icon(c.collapsed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20),
              ),
            ],
          ),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final q in const ['你好', '豆包输入法', '智能', 'Hello', '123', '，。！'])
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => c.insertText(q),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.memory_rounded, size: 13, color: p.textSecondary),
              const SizedBox(width: 4),
              Text(
                '本地词典 ${PinyinEngine.instance.entryCount} 词 · 加载 ${PinyinEngine.instance.loadMillis} ms',
                style: TextStyle(fontSize: 9.5, color: p.textSecondary),
              ),
              if (c.lastQueryMicros != null && c.lastQueryMicros! > 0) ...[
                const SizedBox(width: 8),
                Text('查询 ${(c.lastQueryMicros! / 1000).toStringAsFixed(1)} ms',
                    style: TextStyle(fontSize: 9.5, color: p.primary)),
              ],
              const Spacer(),
              if (s.traditional)
                Text('繁體', style: TextStyle(fontSize: 9.5, color: p.primary)),
              if (s.isSmartMode && !s.aiConfigured)
                Text(' · AI 离线模板', style: TextStyle(fontSize: 9.5, color: p.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _collapsedBar(BuildContext context, AppPalette p) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: p.keyboardBg,
      child: Row(
        children: [
          Icon(Icons.keyboard_hide_rounded, size: 18, color: p.textSecondary),
          const SizedBox(width: 8),
          Text('键盘已收起', style: TextStyle(fontSize: 13, color: p.textSecondary)),
          const Spacer(),
          TextButton.icon(
            onPressed: c.toggleCollapse,
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
            label: const Text('显示键盘', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard(BuildContext context, AppState s, double height, double maxWidth) {
    final p = context.pal;
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    final compact = height < 280;
    return Center(
      child: SizedBox(
        width: tablet ? min(maxWidth, 960.0) : double.infinity,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: p.keyboardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(tablet ? 18 : 12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              KeyboardToolbar(
                c: c,
                onToolbox: () => c.setPanel('toolbox'),
                onVoice: _voice,
                onPanel: (id) => c.setPanel(id),
                onSettings: () => _navigate('/layout'),
                onCollapse: c.toggleCollapse,
              ),
              if (c.panel != null)
                Expanded(
                  child: KeyboardPanelHost(
                    id: c.panel!,
                    c: c,
                    onClose: () => c.setPanel(null),
                    onNavigate: _navigate,
                    onVoice: _voice,
                  ),
                )
              else ...[
                CandidateBar(
                  c: c,
                  onExpand: () => c.setPanel('candidates'),
                  onVoice: _voice,
                  onClosePanel: () => c.setPanel(null),
                  panelOpen: false,
                ),
                Expanded(
                  child: compact
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width,
                            height: 260,
                            child: _body(context),
                          ),
                        )
                      : _body(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (c.isHandwriting) {
      return HandwritingPad(c: c, onLookup: () => c.setPanel('handwriting'));
    }
    if (c.isStroke) return StrokeKeyboard(c: c);
    if (c.isNine) return NineKeyboard(c: c);
    return QwertyKeyboard(c: c);
  }

  Widget _floatingKeyboard(
    BuildContext context,
    AppState s,
    BoxConstraints constraints,
    double keyboardH,
    Widget keyboard,
  ) {
    final p = context.pal;
    final scale = s.floatingScale;
    final width = min(900.0, constraints.maxWidth - 24) * scale;
    final height = keyboardH * scale;
    final left = _floatOffset.dx.clamp(6.0, max(6.0, constraints.maxWidth - width - 6)).toDouble();
    final top = _floatOffset.dy.clamp(6.0, max(6.0, constraints.maxHeight - height - 6)).toDouble();
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height + 30,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: p.keyboardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: p.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  setState(() {
                    _floatOffset += d.delta;
                    _floatOffset = Offset(
                      _floatOffset.dx.clamp(0.0, constraints.maxWidth - width).toDouble(),
                      _floatOffset.dy.clamp(0.0, constraints.maxHeight - height - 30).toDouble(),
                    );
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _snapped = true;
                    final center = _floatOffset.dx + width / 2;
                    _floatOffset = Offset(
                      center < constraints.maxWidth / 2 ? 8 : constraints.maxWidth - width - 8,
                      _floatOffset.dy,
                    );
                  });
                },
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: p.card,
                  child: Row(
                    children: [
                      Icon(Icons.drag_indicator_rounded, size: 16, color: p.textSecondary),
                      const SizedBox(width: 4),
                      Text('悬浮键盘', style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
                      if (_snapped) ...[
                        const SizedBox(width: 4),
                        Text('已贴边', style: TextStyle(fontSize: 9, color: p.primary)),
                      ],
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          s.setBool(K.floating, false);
                          toast(context, '已恢复底部键盘');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text('恢复', style: TextStyle(fontSize: 10, color: p.primary)),
                        ),
                      ),
                      InkWell(
                        onTap: () => c.toggleCollapse(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(Icons.close_rounded, size: 14, color: p.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: min(900.0, constraints.maxWidth - 24),
                      height: keyboardH,
                      child: keyboard,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
