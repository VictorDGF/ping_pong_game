import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_pong_game/game/pong_controller.dart';

void main() {
  
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PongController unit tests', () {
    late PongController controller;

    setUp(() {
      controller = PongController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('setLayout initializes sizes and ball inside screen', () {
      controller.setLayout(const Size(400, 800));
      final s = controller.state;

      expect(s.screenWidth, 400);
      expect(s.screenHeight, 800);
      expect(s.leftPaddleY, closeTo(400, 0.1));
      expect(s.rightPaddleY, closeTo(400, 0.1));
      expect(s.ballX, closeTo(200, 1.0));
      expect(s.ballY, closeTo(400, 1.0));
    });

    test('step moves ball by vx * dt and vy * dt', () {
      controller.setLayout(const Size(400, 800));
      final s = controller.state;
      final beforeX = s.ballX;
      final beforeY = s.ballY;
      final vx = s.ballVX;
      final vy = s.ballVY;

      controller.step(0.1);

      expect(s.ballX, closeTo(beforeX + vx * 0.1, 0.0001));
      expect(s.ballY, closeTo(beforeY + vy * 0.1, 0.0001));
    });

    test('ball bounces top and bottom', () {
      controller.setLayout(const Size(400, 200));
      final s = controller.state;

      s.ballY = s.ballRadius + 1;
      s.ballVY = -150;
      s.ballVX = 0;

      controller.step(0.02);
      expect(s.ballVY, greaterThan(0));
      expect(s.ballY, greaterThanOrEqualTo(s.ballRadius));
    });

    test('scoring when ball passes left and right edges', () {
      controller.setLayout(const Size(300, 500));
      final s = controller.state;

      s.ballX = -10;
      controller.step(0.01);
      expect(s.rightScore, greaterThanOrEqualTo(1));

      s.ballX = s.screenWidth + 10;
      controller.step(0.01);
      expect(s.leftScore, greaterThanOrEqualTo(1));
    });

    test('collision with left paddle inverts horizontal direction', () {
      controller.setLayout(const Size(400, 800));
      final s = controller.state;

      s.leftPaddleY = s.screenHeight / 2;
      s.ballX = s.paddleWidth + s.ballRadius + 0.1;
      s.ballY = s.leftPaddleY;
      s.ballVX = -200;
      s.ballVY = 0;

      controller.step(0.01);

      expect(s.ballVX, greaterThan(0));
    });
  });
}
