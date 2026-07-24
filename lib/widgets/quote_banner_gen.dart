import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Replikasi PERSIS fungsi `generateQuoteBanner()` di public/index.html:
/// canvas 1280x720, background putih, teks quote hitam tebal auto-shrink,
/// tanda tangan "Wanz" pojok kiri bawah. Hasilnya PNG bytes, di-upload
/// sebagai `banner_image` biasa -> lewat jalur yang SAMA PERSIS kayak upload
/// foto manual di backend (sendPhoto), gak ada field/jalur baru.
Future<Uint8List> generateQuoteBannerPng(String rawText) async {
  const w = 1280.0, h = 720.0;
  const marginX = 70.0;
  const maxWidth = w - marginX * 2;
  const minFont = 30.0;
  const maxLines = 7;

  final quoted = '"${rawText.trim().replaceAll(RegExp(r'^["“”]+|["“”]+$'), '')}"';

  List<String> wrap(double fontSize) {
    final words = quoted.split(RegExp(r'\s+'));
    final out = <String>[];
    var cur = '';
    for (final word in words) {
      final test = cur.isEmpty ? word : '$cur $word';
      final tp = TextPainter(
        text: TextSpan(text: test, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, fontFamily: 'Arial')),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > maxWidth && cur.isNotEmpty) {
        out.add(cur);
        cur = word;
      } else {
        cur = test;
      }
    }
    if (cur.isNotEmpty) out.add(cur);
    return out;
  }

  double fontSize = 80;
  List<String> lines = [];
  while (fontSize > minFont) {
    lines = wrap(fontSize);
    final lineHeight = fontSize * 1.18;
    final totalH = lines.length * lineHeight;
    if (lines.length <= maxLines && totalH < h - 220) break;
    fontSize -= 2;
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

  // Background putih
  canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);

  final lineHeight = fontSize * 1.18;
  final totalH = lines.length * lineHeight;
  var y = (h - totalH) / 2;

  for (final line in lines) {
    final tp = TextPainter(
      text: TextSpan(text: line, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, fontFamily: 'Arial', color: const Color(0xFF0A0A0A))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(marginX, y));
    y += lineHeight;
  }

  // Signature "Wanz" pojok kiri bawah
  final signSize = (fontSize * 0.36) < 28 ? 28.0 : fontSize * 0.36;
  final signTp = TextPainter(
    text: TextSpan(text: 'Wanz', style: TextStyle(fontSize: signSize, fontWeight: FontWeight.w700, fontFamily: 'Arial', color: const Color(0xFF0A0A0A))),
    textDirection: TextDirection.ltr,
  )..layout();
  signTp.paint(canvas, Offset(marginX, h - 60 - signSize));

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
