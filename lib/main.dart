import 'package:flutter/material.dart';
import 'game/pong_page.dart';


void main() {
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