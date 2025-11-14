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
    bool _gameOverDialogShowing = false; // evita re-entradas al mostrar el diálogo


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

    void _onControllerTick() {
    // actualizamos UI
    setState(() {});

    // Si se cumple condición de fin de partida (por ejemplo 10 puntos), mostramos diálogo UNA sola vez
    final isGameOver = controller.state.leftScore >= 10 || controller.state.rightScore >= 10;
    if (isGameOver && !_gameOverDialogShowing) {
      _gameOverDialogShowing = true;

      // Ejecutar después del frame actual para evitar setState-during-build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _showGameOverAndSave();
        } catch (e) {
          // captura cualquier error en la lógica del diálogo para no dejar la flag establecida
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        } finally {
          // permitir futuros diálogos después de reiniciar/terminar
          _gameOverDialogShowing = false;
        }
      });
    }
  }


  void _onDragUpdate(DragUpdateDetails details) {
    controller.onDragUpdate(details.localPosition);
  }

  void _onTapDown(TapDownDetails details) {
    controller.onTap(details.localPosition);
  }

  // Pide nombre si no hay uno (diálogo)
  Future<void> _askUsernameIfNeeded() async {
    if (_username != null && _username!.trim().isNotEmpty) return;

    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresa tu nombre'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nombre de jugador'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: const Text('Aceptar')),
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

  // Registrar jugador manual
  Future<void> _addPlayerDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar jugador'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nombre de jugador'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: const Text('Registrar')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_players.contains(result)) _players.add(result);
        _username = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Jugador '$result' registrado")));
      }
    }
  }

  // Seleccionar jugador de la lista local
  Future<void> _selectPlayerDialog() async {
    if (_players.isEmpty) return _addPlayerDialog();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecciona jugador'),
        children: _players.map((p) => SimpleDialogOption(onPressed: () => Navigator.of(context).pop(p), child: Text(p))).toList(),
      ),
    );

    if (result != null) {
      setState(() => _username = result);
    }
  }

  // Al finalizar la partida guarda automáticamente (si hay nombre) y muestra diálogo
  Future<void> _showGameOverAndSave() async {
    controller.togglePause(); // pausa mientras muestra diálogo

    final winner = controller.state.leftScore > controller.state.rightScore ? 'Jugador' : 'CPU';
    final score = controller.state.leftScore;

    await _askUsernameIfNeeded();

    if (_username != null && _username!.isNotEmpty) {
      try {
        // Llamada con parámetros nombrados (corrige el error)
        await FirebaseService.saveScore(username: _username!, score: score);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puntaje guardado')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando puntaje: $e')));
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partida finalizada'),
        content: Text('Ganador: $winner\nPuntaje: $score'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
      ),
    );

    controller.restart();
  }

  // Guardado manual con botón
  Future<void> _manualSave() async {
    await _askUsernameIfNeeded();
    if (_username == null || _username!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero registra tu nombre')));
      return;
    }

    try {
      await FirebaseService.saveScore(username: _username!, score: controller.state.leftScore);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puntaje guardado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando puntaje: $e')));
    }
  }

  // Mostrar top (usa getTopScores de FirebaseService)
  Future<void> _showTop() async {
    try {
      final top = await FirebaseService.topScores();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Top puntajes'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: top.map((t) {
                final name = t['username'] ?? t['player'] ?? '---';
                final score = t['score'] ?? 0;
                return ListTile(title: Text(name), trailing: Text(score.toString()));
              }).toList(),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error obteniendo top: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ping Pong - Flutter'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(controller.running ? Icons.pause : Icons.play_arrow), onPressed: controller.togglePause),
          IconButton(icon: const Icon(Icons.replay), onPressed: controller.restart),
          IconButton(icon: const Icon(Icons.person_add), tooltip: 'Registrar jugador', onPressed: _addPlayerDialog),
          IconButton(icon: const Icon(Icons.people), tooltip: 'Seleccionar jugador', onPressed: _selectPlayerDialog),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // actualizar layout (evita setState durante build porque setLayout hace post-frame notify)
          controller.setLayout(constraints.biggest);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: _onDragUpdate,
            onTapDown: _onTapDown,
            child: CustomPaint(
              size: Size.infinite,
              painter: PongPainter(controller.state),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text('Puntos: ${controller.state.leftScore} - ${controller.state.rightScore}'),
            const Spacer(),
            Text(_username == null ? 'Jugador: (sin registrar)' : 'Jugador: $_username'),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: _manualSave, child: const Text('Guardar')),
            const SizedBox(width: 6),
            ElevatedButton(onPressed: _showTop, child: const Text('Top')),
          ],
        ),
      ),
    );
  }
}
