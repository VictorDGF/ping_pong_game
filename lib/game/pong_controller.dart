
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PongState {
  double ballX = 0, ballY = 0;
  double ballVX = 0, ballVY = 0;
  double ballRadius = 10;

  double leftPaddleY = 0, rightPaddleY = 0;
  double paddleWidth = 12, paddleHeight = 120;

  double screenWidth = 1, screenHeight = 1;

  int leftScore = 0, rightScore = 0;
}

class PongController extends ChangeNotifier {
  final PongState state = PongState();
  final Random rng = Random();

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool running = true;

  PongController() {
    _ticker = Ticker(_onTick);
  }

  void start() {
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void setLayout(Size size) {
    if (state.screenWidth != size.width || state.screenHeight != size.height) {
      state.screenWidth = size.width;
      state.screenHeight = size.height;
      state.paddleHeight = max(80.0, state.screenHeight * 0.2);
      state.paddleWidth = max(12.0, state.screenWidth * 0.03);
      state.leftPaddleY = state.screenHeight / 2;
      state.rightPaddleY = state.screenHeight / 2;
      _resetBall(toRight: rng.nextBool());
      notifyListeners();
    }
  }

  void _onTick(Duration elapsed) {
    if (!running) {
      _lastTick = elapsed;
      return;
    }
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;
    if (dt <= 0) return;

    // Update physics
    _updateBall(dt);
    _updateAI(dt);

    notifyListeners();
  }

  void _updateBall(double dt) {
    final s = state;
    s.ballX += s.ballVX * dt;
    s.ballY += s.ballVY * dt;

    if (s.ballY - s.ballRadius <= 0 && s.ballVY < 0) {
      s.ballY = s.ballRadius;
      s.ballVY = -s.ballVY;
    } else if (s.ballY + s.ballRadius >= s.screenHeight && s.ballVY > 0) {
      s.ballY = s.screenHeight - s.ballRadius;
      s.ballVY = -s.ballVY;
    }

    final leftRect = Rect.fromCenter(center: Offset(s.paddleWidth / 2, s.leftPaddleY), width: s.paddleWidth, height: s.paddleHeight);
    final rightRect = Rect.fromCenter(center: Offset(s.screenWidth - s.paddleWidth / 2, s.rightPaddleY), width: s.paddleWidth, height: s.paddleHeight);

    if (s.ballVX < 0) {
      if (_circleRectCollision(s.ballX, s.ballY, s.ballRadius, leftRect)) {
        s.ballX = leftRect.right + s.ballRadius;
        _bounceOffPaddle(leftRect);
      }
    } else {
      if (_circleRectCollision(s.ballX, s.ballY, s.ballRadius, rightRect)) {
        s.ballX = rightRect.left - s.ballRadius;
        _bounceOffPaddle(rightRect);
      }
    }

    if (s.ballX + s.ballRadius < 0) {
      s.rightScore += 1;
      _resetBall(toRight: false);
    } else if (s.ballX - s.ballRadius > s.screenWidth) {
      s.leftScore += 1;
      _resetBall(toRight: true);
    }
  }

  void _updateAI(double dt) {
    final s = state;
    double aiSpeed = 450;
    if (s.ballX > s.screenWidth * 0.5) {
      if ((s.rightPaddleY - s.ballY).abs() > 4) {
        if (s.rightPaddleY < s.ballY) {
          s.rightPaddleY = min(s.rightPaddleY + aiSpeed * dt, s.screenHeight - s.paddleHeight / 2);
        } else {
          s.rightPaddleY = max(s.rightPaddleY - aiSpeed * dt, s.paddleHeight / 2);
        }
      }
    } else {
      if ((s.rightPaddleY - s.screenHeight / 2).abs() > 4) {
        if (s.rightPaddleY < s.screenHeight / 2) {
          s.rightPaddleY = min(s.rightPaddleY + aiSpeed * dt * 0.3, s.screenHeight - s.paddleHeight / 2);
        } else {
          s.rightPaddleY = max(s.rightPaddleY - aiSpeed * dt * 0.3, s.paddleHeight / 2);
        }
      }
    }
  }

  bool _circleRectCollision(double cx, double cy, double r, Rect rect) {
    double nearestX = cx.clamp(rect.left, rect.right);
    double nearestY = cy.clamp(rect.top, rect.bottom);
    double dx = cx - nearestX;
    double dy = cy - nearestY;
    return dx * dx + dy * dy <= r * r;
  }

  void _bounceOffPaddle(Rect paddleRect) {
    final s = state;
    // reflect x
    s.ballVX = -s.ballVX;
    double relativeIntersectY = (s.ballY - paddleRect.center.dy) / (s.paddleHeight / 2);
    relativeIntersectY = relativeIntersectY.clamp(-1.0, 1.0);
    double maxAngle = pi / 3;
    double angle = relativeIntersectY * maxAngle;
    double speed = sqrt(s.ballVX * s.ballVX + s.ballVY * s.ballVY);
    double dir = s.ballVX.sign;
    s.ballVX = -dir * speed * cos(angle);
    s.ballVY = speed * sin(angle);
    double speedIncrease = 1.03;
    s.ballVX *= speedIncrease;
    s.ballVY *= speedIncrease;
  }

  void _resetBall({required bool toRight}) {
    final s = state;
    s.ballX = s.screenWidth / 2;
    s.ballY = s.screenHeight / 2;
    double baseSpeed = 300 + min((s.leftScore + s.rightScore) * 10.0, 400);
    double angle = (rng.nextDouble() * pi / 4) - (pi / 8);
    s.ballVX = baseSpeed * (toRight ? 1 : -1) * cos(angle);
    s.ballVY = baseSpeed * sin(angle);
  }

  void onDragUpdate(Offset localPos) {
    final s = state;
    final dx = localPos.dx;
    final dy = localPos.dy;
    if (dx < s.screenWidth / 2) {
      s.leftPaddleY = dy.clamp(s.paddleHeight / 2, s.screenHeight - s.paddleHeight / 2);
    } else {
      s.rightPaddleY = dy.clamp(s.paddleHeight / 2, s.screenHeight - s.paddleHeight / 2);
    }
    notifyListeners();
  }

  void onTap(Offset localPos) {
    final s = state;
    final dx = localPos.dx;
    final dy = localPos.dy;
    if (dx < s.screenWidth / 2) {
      s.leftPaddleY = dy.clamp(s.paddleHeight / 2, s.screenHeight - s.paddleHeight / 2);
    } else {
      s.rightPaddleY = dy.clamp(s.paddleHeight / 2, s.screenHeight - s.paddleHeight / 2);
    }
    notifyListeners();
  }

  void togglePause() {
    running = !running;
    _lastTick = Duration.zero;
    notifyListeners();
  }

  void restart() {
    state.leftScore = 0;
    state.rightScore = 0;
    state.leftPaddleY = state.screenHeight / 2;
    state.rightPaddleY = state.screenHeight / 2;
    _resetBall(toRight: rng.nextBool());
    running = true;
    _lastTick = Duration.zero;
    notifyListeners();
  }
}