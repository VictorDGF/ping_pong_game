import 'package:flutter/material.dart';
import '../game/pong_controller.dart';
import '../widgets/pong_painter.dart';
import '../services/firebase_service.dart';

class PongPage extends StatefulWidget {
  const PongPage({super.key});

  @override
  State<PongPage> createState() => _PongPageState();
}

class _PongPageState extends State<PongPage> {
  final PongController controller = PongController();
  String? _username;
  final List<String> _players = [];

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerTick);
    controller.start();
    // No inicializamos Firebase aquí — lo debes inicializar en main() con FirebaseService.init()
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerTick);
    controller.dispose();
    super.dispose();
  }

  void _onControllerTick() {
    setState(() {});

    // Si quieres guardar automáticamente cuando termina una partida (por ejemplo cuando CPU llega a 10 puntos)
    // detecta condición de 'game over' y muestra diálogo para guardar.
    if (controller.state.leftScore >= 10 || controller.state.rightScore >= 10) {
      _showGameOverAndSave();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    controller.onDragUpdate(details.localPosition);
  }

  void _onTapDown(TapDownDetails details) {
    controller.onTap(details.localPosition);
  }

  Future<void> _askUsernameIfNeeded() async {
    if (_username != null && _username!.trim().isNotEmpty) return;

    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresa tu nombre'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Nombre de jugador'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(textController.text.trim()), child: const Text('Aceptar')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _username = result;
        if (!_players.contains(result)) _players.add(result);
      });
    }
  }

  Future<void> _addPlayerDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar jugador'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Nombre de jugador'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(textController.text.trim()), child: const Text('Registrar')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_players.contains(result)) _players.add(result);
        _username = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jugador "${result}" registrado')));
    }
  }

  Future<void> _selectPlayerDialog() async {
    if (_players.isEmpty) return _addPlayerDialog();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecciona jugador'),
        children: _players.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(p),
          child: Text(p),
        )).toList(),
      ),
    );

    if (result != null) {
      setState(() => _username = result);
    }
  }

  Future<void> _showGameOverAndSave() async {
    // Pause the game while dialog is open
    controller.togglePause();

    final winner = controller.state.leftScore > controller.state.rightScore ? 'Jugador' : 'CPU';
    final playerScore = controller.state.leftScore;

    await _askUsernameIfNeeded();

    // If user provided username, save the score
    if (_username != null && _username!.isNotEmpty) {
      try {
        await FirebaseService.saveScore(username: _username!, score: playerScore);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puntaje guardado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando puntaje: $e')));
        }
      }
    }

    // Show final dialog
    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Partida finalizada'),
          content: Text('Ganador: $winner Puntaje: $playerScore'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok')),
          ],
        ),
      );
    }

    // Restart and resume
    controller.restart();
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
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Registrar jugador',
            onPressed: _addPlayerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Seleccionar jugador',
            onPressed: _selectPlayerDialog,
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
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text('Puntos: ${controller.state.leftScore} - ${controller.state.rightScore}'),
            const Spacer(),
            Text(_username == null ? 'Jugador: (sin registrar)' : 'Jugador: $_username'),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                // Show top scores
                final top = await FirebaseService.topScores(limit: 10);
                if (!mounted) return;
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Top puntajes'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: top.map((t) => ListTile(
                          title: Text(t['username'] ?? '---'),
                          trailing: Text((t['score'] ?? 0).toString()),
                        )).toList(),
                      ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
                  ),
                );
              },
              child: const Text('Top'),
            ),
          ],
        ),
      ),
    );
  }
}
