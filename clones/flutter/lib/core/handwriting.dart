import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class HandwritingResult {
  final List<String> candidates;
  final bool confident;
  const HandwritingResult(this.candidates, this.confident);
}

/// Clean-room template handwriting recognizer.
///
/// Each template glyph is rasterized once with the platform font, ink-normalized
/// to a 72x72 grid, and compared against the normalized stroke bitmap using a
/// tolerant coverage score. No official model or asset is used.
class HandwritingRecognizer {
  static final HandwritingRecognizer instance = HandwritingRecognizer._();
  HandwritingRecognizer._();

  static const chars = <String>[
    '一', '二', '三', '十', '人', '大', '小', '口', '日', '月',
    '上', '山', '水', '中', '火', '木', '手', '天', '王', '女',
    '好', '你', '我', '的', '是', '不', '了', '有', '这', '来',
    '到', '时', '要', '就', '以', '说', '年', '得', '也', '他',
    '她', '在', '们', '国', '输', '入', '法', '0', '1', '2',
    '3', '4', '5', '6', '7', '8', '9',
  ];

  static const _n = 72;
  static const _src = 128;
  bool _ready = false;
  bool loading = false;
  Future<void>? _prepareFuture;
  final Map<String, Float32List> _glyphs = {};

  Future<void> prepare() {
    if (_ready) return Future.value();
    return _prepareFuture ??= _prepare();
  }

  Future<void> _prepare() async {
    loading = true;
    try {
      for (final c in chars) {
        _glyphs[c] = await _renderGlyph(c);
      }
      _ready = true;
    } finally {
      loading = false;
    }
  }

  Future<Float32List> _renderGlyph(String char) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _src.toDouble(), _src.toDouble()),
      Paint()..color = Colors.white,
    );
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 100,
      textAlign: TextAlign.center,
      fontFamily: 'sans-serif',
    ))
      ..pushStyle(ui.TextStyle(color: Colors.black, fontSize: 100))
      ..addText(char);
    final paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: _src.toDouble()));
    canvas.drawParagraph(paragraph, Offset(0, (_src - paragraph.height) / 2));
    final img = await recorder.endRecording().toImage(_src, _src);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    final src = _toInk(data!, _src);
    return _normalize(src, _src);
  }

  Float32List _toInk(ByteData data, int size) {
    final out = Float32List(size * size);
    for (var i = 0; i < size * size; i++) {
      final r = data.getUint8(i * 4);
      final g = data.getUint8(i * 4 + 1);
      final b = data.getUint8(i * 4 + 2);
      out[i] = 1.0 - ((r + g + b) / 3.0) / 255.0;
    }
    return out;
  }

  /// Scales the ink bounding box into a centered 80% box on a [_n] grid.
  Float32List _normalize(Float32List src, int size) {
    var minX = size, minY = size, maxX = -1, maxY = -1;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (src[y * size + x] > 0.12) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    final out = Float32List(_n * _n);
    if (maxX < minX || maxY < minY) return out;
    final w = (maxX - minX + 1).toDouble();
    final h = (maxY - minY + 1).toDouble();
    final scale = min(_n * 0.78 / w, _n * 0.78 / h);
    final dx = (_n - w * scale) / 2;
    final dy = (_n - h * scale) / 2;
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        final sx = ((x - dx) / scale + minX).round();
        final sy = ((y - dy) / scale + minY).round();
        if (sx >= minX && sx <= maxX && sy >= minY && sy <= maxY) {
          out[y * _n + x] = src[sy * size + sx];
        }
      }
    }
    return out;
  }

  Future<HandwritingResult> recognize(List<List<Offset>> strokes) async {
    if (!_ready) await prepare();
    if (strokes.isEmpty) return const HandwritingResult([], false);
    final query = await _rasterizeStrokes(strokes);
    final qDil = _dilate(query, 2);
    final scores = <MapEntry<String, double>>[];
    for (final entry in _glyphs.entries) {
      final g = entry.value;
      final gDil = _dilate(g, 2);
      var hit = 0.0;
      var drawn = 0.0;
      for (var i = 0; i < qDil.length; i++) {
        if (qDil[i] > 0.25) {
          drawn += 1;
          if (gDil[i] > 0.2) hit += 1;
        }
      }
      var gCount = 0.0;
      var gHit = 0.0;
      for (var i = 0; i < g.length; i++) {
        if (g[i] > 0.25) {
          gCount += 1;
          if (qDil[i] > 0.2) gHit += 1;
        }
      }
      if (drawn == 0 || gCount == 0) continue;
      final recall = hit / drawn;
      final precision = gHit / gCount;
      // A light stroke-count prior helps prevent one-stroke matches.
      final countPenalty = (strokes.length <= 1 ? 0.02 : 0.0);
      scores.add(MapEntry(entry.key, recall * 0.68 + precision * 0.32 - countPenalty));
    }
    scores.sort((a, b) => b.value.compareTo(a.value));
    final top = scores.take(9).toList();
    final confident = top.isNotEmpty && top.first.value > 0.34;
    return HandwritingResult(
      top.where((e) => e.value > 0.12).map((e) => e.key).toList(),
      confident,
    );
  }

  Future<Float32List> _rasterizeStrokes(List<List<Offset>> strokes) async {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final s in strokes) {
      for (final p in s) {
        minX = min(minX, p.dx);
        minY = min(minY, p.dy);
        maxX = max(maxX, p.dx);
        maxY = max(maxY, p.dy);
      }
    }
    if (!minX.isFinite) return Float32List(_src * _src);
    final w = max(1.0, maxX - minX);
    final h = max(1.0, maxY - minY);
    final scale = min(_src * 0.78 / w, _src * 0.78 / h);
    final dx = (_src - w * scale) / 2;
    final dy = (_src - h * scale) / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, _src.toDouble(), _src.toDouble()),
        Paint()..color = Colors.white);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      final path = Path();
      final p0 = Offset(dx + (s.first.dx - minX) * scale, dy + (s.first.dy - minY) * scale);
      path.moveTo(p0.dx, p0.dy);
      if (s.length == 1) {
        canvas.drawCircle(p0, 3.5, Paint()..color = Colors.black);
      } else {
        for (var i = 1; i < s.length; i++) {
          path.lineTo(dx + (s[i].dx - minX) * scale, dy + (s[i].dy - minY) * scale);
        }
        canvas.drawPath(path, paint);
      }
    }
    final img = await recorder.endRecording().toImage(_src, _src);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    final ink = _toInk(data!, _src);
    return _normalize(ink, _src);
  }

  Float32List _dilate(Float32List src, int radius) {
    final out = Float32List(src.length);
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        var m = 0.0;
        for (var dy = -radius; dy <= radius; dy++) {
          final yy = y + dy;
          if (yy < 0 || yy >= _n) continue;
          for (var dx = -radius; dx <= radius; dx++) {
            final xx = x + dx;
            if (xx < 0 || xx >= _n) continue;
            final v = src[yy * _n + xx];
            if (v > m) m = v;
          }
        }
        out[y * _n + x] = m;
      }
    }
    return out;
  }
}
