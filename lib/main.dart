import 'package:flutter/material.dart';

import 'recorder/recorder_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const AmbrosiaApp());

class AmbrosiaApp extends StatelessWidget {
  const AmbrosiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambrosia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RecorderScreen(),
    );
  }
}
