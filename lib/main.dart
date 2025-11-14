import 'package:flutter/material.dart';
import 'package:ping_pong_game/services/firebase_service.dart';
import 'game/pong_page.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.init();
  runApp(const PongApp());
}


class PongApp extends StatelessWidget {
const PongApp({super.key});


@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Flutter Ping Pong',
theme: ThemeData.dark(),
home: const PongPage(),
debugShowCheckedModeBanner: false,
);
}
}