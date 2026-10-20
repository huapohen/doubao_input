import 'package:flutter/material.dart';
import '../../theme.dart';
import 'keyboard_controller.dart';

class HandwritingPad extends StatelessWidget {
  final KeyboardController c;
  final VoidCallback onLookup;
  const HandwritingPad({super.key, required this.c, required this.onLookup});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => c.startStroke(e.localPosition),
                    onPointerMove: (e) => c.addStrokePoint(e.localPosition),
                    onPointerUp: (_) => c.endStroke(),
                    onPointerCancel: (_) => c.endStroke(),
                    child: CustomPaint(
                      painter: _StrokePainter(
                        strokes: c.strokes,
                        grid: p.divider,
                        ink: p.text,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                if (c.strokes.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gesture_rounded,
                            size: 38, color: p.textSecondary.withValues(alpha: 0.45)),
                        const SizedBox(height: 6),
                        Text('在此手写，停顿后自动识别',
                            style: TextStyle(fontSize: 12, color: p.textSecondary)),
                        Text('支持撤销、清空与手写找字',
                            style: TextStyle(fontSize: 10, color: p.textSecondary.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                if (c.recognizing)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: p.primary),
                          ),
                          const SizedBox(width: 5),
                          Text('识别中', style: TextStyle(fontSize: 10, color: p.primary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: p.keyboardBg.withValues(alpha: 0.7),
              border: Border(top: BorderSide(color: p.divider)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: c.undoStroke,
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: const Text('撤销', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: c.clearStrokes,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('清空', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: c.recognizeHandwriting,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('识别', style: TextStyle(fontSize: 11)),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onLookup,
                  icon: const Icon(Icons.manage_search_rounded, size: 16),
                  label: const Text('手写找字', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color grid;
  final Color ink;
  _StrokePainter({required this.strokes, required this.grid, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..color = grid.withValues(alpha: 0.5)
      ..strokeWidth = 0.6;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(size.width * i / 4, 0), Offset(size.width * i / 4, size.height), g);
      canvas.drawLine(Offset(0, size.height * i / 4), Offset(size.width, size.height * i / 4), g);
    }
    final paint = Paint()
      ..color = ink
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(s.first, 2.5, Paint()..color = ink);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
