import 'package:flutter/material.dart';
import '../game/pong_controller.dart';

class PongPainter extends CustomPainter {
  final PongState state;

  PongPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    // Fondo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // Pelota
    canvas.drawCircle(
      Offset(state.ballX, state.ballY),
      state.ballRadius,
      paint,
    );

    // Paddle del jugador
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(state.paddleWidth / 2, state.leftPaddleY),
        width: state.paddleWidth,
        height: state.paddleHeight,
      ),
      paint,
    );

    // Paddle CPU
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width - state.paddleWidth / 2, state.rightPaddleY),
        width: state.paddleWidth,
        height: state.paddleHeight,
      ),
      paint,
    );

    // Línea central punteada
    final dashHeight = 10.0;
    final dashSpace = 10.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(size.width / 2 - 2, startY, 4, dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
