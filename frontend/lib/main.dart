import 'package:flutter/material.dart';

import 'bridge/ambrosia_bridge.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.engine});

  final AmbrosiaEngine? engine;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambrosia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: HomePage(engine: engine),
    );
  }
}
