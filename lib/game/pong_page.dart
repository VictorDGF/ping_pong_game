
import 'package:flutter/material.dart';
import '../game/pong_controller.dart';
import '../widgets/pong_painter.dart';

class PongPage extends StatefulWidget {
  const PongPage({super.key});

  @override
  State<PongPage> createState() => _PongPageState();
}

class _PongPageState extends State<PongPage> {
  final PongController controller = PongController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerTick);
    controller.start();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerTick);
    controller.dispose();
    super.dispose();
  }

  void _onControllerTick() => setState(() {});

  void _onDragUpdate(DragUpdateDetails details) {
    controller.onDragUpdate(details.localPosition);
  }

  void _onTapDown(TapDownDetails details) {
    controller.onTap(details.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ping Pong - Flutter'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(controller.running ? Icons.pause : Icons.play_arrow),
            onPressed: controller.togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: controller.restart,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          controller.setLayout(constraints.biggest);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: _onDragUpdate,
            onTapDown: _onTapDown,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: PongPainter(
                    state: controller.state,
                  ),
                ),
                if (!controller.running)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Pausado', style: TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text('Puntos: ${controller.state.leftScore} - ${controller.state.rightScore}'),
            const Spacer(),
            const Text('Toca izquierda/derecha para mover paleta'),
          ],
        ),
      ),
    );
  }
}

