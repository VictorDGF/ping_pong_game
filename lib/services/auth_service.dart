import 'package:flutter/material.dart';
import '../game/pong_controller.dart';

class PongPainter extends CustomPainter {
  final PongState state;

  PongPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, p..color = Colors.black87);

    final double dashHeight = 12;
    final double gap = 8;
    double y = 0;
    p.color = Colors.white24;
    while (y < size.height) {
      canvas.drawRect(Rect.fromLTWH(size.width / 2 - 2, y, 4, dashHeight), p);
      y += dashHeight + gap;
    }

    p.color = Colors.white;
    canvas.drawCircle(Offset(state.ballX, state.ballY), state.ballRadius, p);

    final leftRect = Rect.fromCenter(center: Offset(state.paddleWidth / 2, state.leftPaddleY), width: state.paddleWidth, height: state.paddleHeight);
    final rightRect = Rect.fromCenter(center: Offset(size.width - state.paddleWidth / 2, state.rightPaddleY), width: state.paddleWidth, height: state.paddleHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(leftRect, const Radius.circular(6)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(rightRect, const Radius.circular(6)), p);

    final textStyle = TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 36, fontWeight: FontWeight.bold);
    _drawTextCentered(canvas, size.width * 0.25, 30, state.leftScore.toString(), textStyle);
    _drawTextCentered(canvas, size.width * 0.75, 30, state.rightScore.toString(), textStyle);
  }

  void _drawTextCentered(Canvas canvas, double x, double y, String text, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant PongPainter oldDelegate) {
    return oldDelegate.state.ballX != state.ballX ||
        oldDelegate.state.ballY != state.ballY ||
        oldDelegate.state.leftPaddleY != state.leftPaddleY ||
        oldDelegate.state.rightPaddleY != state.rightPaddleY ||
        oldDelegate.state.leftScore != state.leftScore ||
        oldDelegate.state.rightScore != state.rightScore;
  }
}

// ------------------------------
// Nota:
// - Crea las carpetas lib/pages, lib/game, lib/widgets y pega cada archivo en su lugar.
// - Ejecuta: flutter run
// - Si quieres, puedo generar un commit de ejemplo (diff) o añadir sonidos, niveles de dificultad o controles por teclado.
