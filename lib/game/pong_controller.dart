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

  bool _disposed = false;

  PongController() {
    // Ticker lives here; it will call _onTick each frame.
    _ticker = Ticker(_onTick);
  }

  void start() {
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _disposed = true;
    super.dispose();
  }

  /// Single-player layout setter. Notifica después del frame para evitar setState-during-build.
  void setLayout(Size size) {
    if (state.screenWidth != size.width || state.screenHeight != size.height) {
      state.screenWidth = size.width;
      state.screenHeight = size.height;
      state.paddleHeight = max(80.0, state.screenHeight * 0.2);
      state.paddleWidth = max(12.0, state.screenWidth * 0.03);
      state.leftPaddleY = state.screenHeight / 2;
      state.rightPaddleY = state.screenHeight / 2;
      _resetBall(toRight: rng.nextBool());

      // NOTIFY after the current frame finishes building to avoid setState-during-build errors
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
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

    if (!_disposed) notifyListeners();
  }

  void _updateBall(double dt) {
    final s = state;
    s.ballX += s.ballVX * dt;
    s.ballY += s.ballVY * dt;

    // Bounce top / bottom
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

    // Score: ball passed left or right
    if (s.ballX + s.ballRadius < 0) {
      s.rightScore += 1;
      _resetBall(toRight: true); // send ball towards player after cpu scores
    } else if (s.ballX - s.ballRadius > s.screenWidth) {
      s.leftScore += 1;
      _resetBall(toRight: false); // send ball towards CPU after player scores
    }
  }

  void _updateAI(double dt) {
    final s = state;
    double aiSpeed = 500; // AI speed (px/s)
    // Simple AI: follow the ball Y position but limited by speed
    if ((s.rightPaddleY - s.ballY).abs() > 4) {
      if (s.rightPaddleY < s.ballY) {
        s.rightPaddleY = min(s.rightPaddleY + aiSpeed * dt, s.screenHeight - s.paddleHeight / 2);
      } else {
        s.rightPaddleY = max(s.rightPaddleY - aiSpeed * dt, s.paddleHeight / 2);
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

  /// Fixed bounce logic:
  /// - Compute speed before modifying velocities
  /// - Determine outgoing horizontal direction based on which paddle was hit
  void _bounceOffPaddle(Rect paddleRect) {
    final s = state;

    // Compute current speed magnitude
    double speed = sqrt(s.ballVX * s.ballVX + s.ballVY * s.ballVY);
    if (speed < 50) speed = 50; // minimum speed to avoid too slow balls

    // Determine outgoing horizontal direction: left paddle => +1 (to right), right paddle => -1 (to left)
    double dir = (paddleRect.center.dx < s.screenWidth / 2) ? 1.0 : -1.0;

    // Compute hit position relative to paddle center to influence angle
    double relativeIntersectY = (s.ballY - paddleRect.center.dy) / (s.paddleHeight / 2);
    relativeIntersectY = relativeIntersectY.clamp(-1.0, 1.0);
    double maxAngle = pi / 3; // up to 60 degrees from horizontal
    double angle = relativeIntersectY * maxAngle;

    // Set new velocities keeping speed (with a small increase)
    double speedIncrease = 1.03;
    double newSpeed = speed * speedIncrease;
    s.ballVX = dir * newSpeed * cos(angle).abs();
    // vertical component keeps sign from angle
    s.ballVY = newSpeed * sin(angle);

    // Ensure ball is not stuck inside paddle; small position nudge already done by caller (_updateBall)
  }

  void _resetBall({required bool toRight}) {
    final s = state;
    s.ballX = s.screenWidth / 2;
    s.ballY = s.screenHeight / 2;
    double baseSpeed = 350 + min((s.leftScore + s.rightScore) * 12.0, 500);
    double angle = (rng.nextDouble() * pi / 6) - (pi / 12); // random angle between -15..15 deg
    s.ballVX = (toRight ? 1 : -1) * baseSpeed * cos(angle).abs();
    s.ballVY = baseSpeed * sin(angle);
  }

  // Player controls: only left half (single-player)
  void onDragUpdate(Offset localPos) {
    final s = state;
    final dx = localPos.dx;
    final dy = localPos.dy;
    // Only accept input on left half for player control
    if (dx < s.screenWidth / 2) {
      s.leftPaddleY = dy.clamp(s.paddleHeight / 2, s.screenHeight - s.paddleHeight / 2);
      if (!_disposed) notifyListeners();
    }
  }

  void onTap(Offset localPos) {
    final s = state;
    final dx = localPos.dx;
    final dy = localPos.dy;
    if (dx < s.screenWidth / 2) {
      s.leftPaddleY = dy.clamp(s.paddleHeight / 2, s.screenHeight - s.paddleHeight / 2);
      if (!_disposed) notifyListeners();
    }
  }

  void togglePause() {
    running = !running;
    _lastTick = Duration.zero;
    if (!_disposed) notifyListeners();
  }

  void restart() {
    state.leftScore = 0;
    state.rightScore = 0;
    state.leftPaddleY = state.screenHeight / 2;
    state.rightPaddleY = state.screenHeight / 2;
    _resetBall(toRight: rng.nextBool());
    running = true;
    _lastTick = Duration.zero;
    if (!_disposed) notifyListeners();
  }
}
