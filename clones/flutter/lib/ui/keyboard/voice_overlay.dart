import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/local_tools.dart';
import '../../core/speech_service.dart';
import '../../theme.dart';
import '../widgets.dart';
import 'keyboard_controller.dart';

Future<void> showVoiceOverlay(BuildContext context, KeyboardController c) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '语音输入',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, a, b) => VoiceOverlay(controller: c),
    transitionBuilder: (ctx, a, b, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
      ), child: child),
    ),
  );
}

enum _Phase { starting, listening, processing, editing, error }

class VoiceOverlay extends StatefulWidget {
  final KeyboardController controller;
  const VoiceOverlay({super.key, required this.controller});

  @override
  State<VoiceOverlay> createState() => _VoiceOverlayState();
}

class _VoiceOverlayState extends State<VoiceOverlay> with SingleTickerProviderStateMixin {
  final SpeechService _speech = SpeechService();
  _Phase _phase = _Phase.starting;
  String _text = '';
  String _error = '';
  String _hint = '';
  bool _demo = false;
  Timer? _timer;
  int _seconds = 0;
  StreamSubscription<String>? _partialSub;
  late final AnimationController _wave;
  final TextEditingController _edit = TextEditingController();

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _partialSub = _speech.partials.listen((v) {
      if (!mounted) return;
      setState(() {
        _text = v;
        _phase = _Phase.listening;
      });
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _phase == _Phase.listening) setState(() => _seconds++);
    });
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.starting;
      _text = '';
      _error = '';
      _seconds = 0;
      _demo = false;
    });
    final ok = await _speech.start();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _phase = _Phase.error;
        _error = _speech.lastError ?? '语音识别不可用';
      });
    } else {
      setState(() => _phase = _Phase.listening);
    }
  }

  Future<void> _finish() async {
    setState(() => _phase = _Phase.processing);
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (_text.trim().isEmpty) {
      setState(() {
        _phase = _Phase.error;
        _error = '没听清，请重新开始';
        _hint = '也可以使用演示结果继续体验编辑与插入';
      });
    } else {
      _edit.text = _text;
      setState(() => _phase = _Phase.editing);
    }
  }

  void _useDemo() {
    setState(() {
      _demo = true;
      _text = SpeechService.demoTranscript();
      _edit.text = _text;
      _phase = _Phase.editing;
      _hint = '这是演示文本，未经过真实语音识别';
    });
  }

  void _organize() {
    final s = AppState.I;
    final out = localOrganize(
      _edit.text,
      aggressive: s.voiceFiller == '激进',
      blankLine: s.getBool('voice_paragraph'),
      punctuation: s.voicePunctuation,
    );
    setState(() => _edit.text = out);
    toast(context, '已按语音设置本地整理');
  }

  void _insert() {
    final s = AppState.I;
    var text = _edit.text.trim();
    if (text.isEmpty) {
      toast(context, '没有可插入的文字');
      return;
    }
    if (s.voiceSmartOrganize && !_demo) {
      text = localOrganize(
        text,
        aggressive: s.voiceFiller == '激进',
        blankLine: s.getBool('voice_paragraph'),
        punctuation: s.voicePunctuation,
      );
    }
    var actionTriggered = false;
    if (s.voiceActionEnabled) {
      for (final a in s.voiceActions) {
        if (text.contains(a)) {
          text = text.replaceAll(a, '').trim();
          actionTriggered = true;
          break;
        }
      }
    }
    widget.controller.insertText(text);
    widget.controller.lastCommitted = text;
    Navigator.of(context).pop();
    if (actionTriggered) {
      widget.controller.onEnter();
      toast(context, '语音口令已触发发送');
    } else {
      toast(context, _demo ? '已插入演示文本' : '语音文字已插入');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _partialSub?.cancel();
    _wave.dispose();
    _speech.dispose();
    _edit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final size = MediaQuery.sizeOf(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: min(size.width - 32, 520),
          constraints: BoxConstraints(maxHeight: size.height - 80),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 40),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: _content(context, p),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppPalette p) {
    return switch (_phase) {
      _Phase.starting => _statusView(
          context,
          p,
          icon: Icons.mic_none_rounded,
          title: '正在启动语音识别…',
          subtitle: '首次使用会请求麦克风与语音识别权限',
          showWave: false,
        ),
      _Phase.listening => _listeningView(context, p),
      _Phase.processing => _statusView(
          context,
          p,
          icon: Icons.auto_awesome_rounded,
          title: '识别优化中…',
          subtitle: _text.isEmpty ? '正在等待最终结果' : _text,
          showWave: false,
        ),
      _Phase.editing => _editingView(context, p),
      _Phase.error => _errorView(context, p),
    };
  }

  Widget _statusView(
    BuildContext context,
    AppPalette p, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showWave,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Icon(icon, size: 40, color: p.primary),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.5)),
        if (showWave) ...[
          const SizedBox(height: 20),
          _Wave(controller: _wave, color: p.primary),
        ],
        const SizedBox(height: 20),
        TextButton(
          onPressed: () async {
            await _speech.cancel();
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _listeningView(BuildContext context, AppPalette p) {
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: p.danger, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('正在倾听', style: TextStyle(fontSize: 13, color: p.text)),
            const Spacer(),
            Text('$mm:$ss', style: TextStyle(fontSize: 12, color: p.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),
        _Wave(controller: _wave, color: p.primary, big: true),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.pageBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _text.isEmpty ? '请开始说话…' : _text,
            style: TextStyle(
              fontSize: 16,
              color: _text.isEmpty ? p.textSecondary : p.text,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('松手后点击完成；识别结果可继续编辑',
            style: TextStyle(fontSize: 11, color: p.textSecondary)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton('取消', icon: Icons.close_rounded, onPressed: () async {
                await _speech.cancel();
                if (mounted) Navigator.of(context).pop();
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton('完成', icon: Icons.check_rounded, onPressed: _finish),
            ),
          ],
        ),
      ],
    );
  }

  Widget _errorView(BuildContext context, AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Icon(Icons.mic_off_rounded, size: 40, color: p.danger),
        const SizedBox(height: 12),
        Text('语音识别未完成',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
        const SizedBox(height: 8),
        Text(_error,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.5)),
        if (_hint.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.textSecondary.withValues(alpha: 0.8))),
        ],
        const SizedBox(height: 18),
        PrimaryButton('使用演示结果', icon: Icons.science_outlined, onPressed: _useDemo),
        const SizedBox(height: 8),
        SecondaryButton('重试', icon: Icons.refresh_rounded, onPressed: _start),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _editingView(BuildContext context, AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('识别结果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text)),
            const SizedBox(width: 8),
            TagChip(_demo ? '演示' : '系统识别', color: _demo ? const Color(0xFFE08A00) : const Color(0xFF23A26D)),
            const Spacer(),
            if (AppState.I.voiceSmartOrganize)
              TextButton(onPressed: _organize, child: const Text('整理')),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: SingleChildScrollView(
            child: TextField(
              controller: _edit,
              maxLines: null,
              minLines: 4,
              style: TextStyle(fontSize: 15, color: p.text, height: 1.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: p.pageBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (_hint.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_hint, style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SecondaryButton('重新录制', icon: Icons.refresh_rounded, onPressed: _start),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton('插入', icon: Icons.keyboard_return_rounded, onPressed: _insert),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('插入后可在输入框中继续划选修改',
              style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        ),
      ],
    );
  }
}

class _Wave extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final bool big;
  const _Wave({required this.controller, required this.color, this.big = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          height: big ? 58 : 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(13, (i) {
              final t = controller.value * 2 * pi + i * 0.55;
              final h = (big ? 14.0 : 8.0) + (sin(t) + 1) * (big ? 18 : 9);
              return Container(
                width: big ? 5 : 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
