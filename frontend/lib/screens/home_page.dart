import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRecording = false;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = _isRecording ? Icons.stop : Icons.mic;
    final String label = _isRecording ? 'Recording...' : 'Record';
    final Color? backgroundColor = _isRecording ? Colors.red : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ambrosia')),
      body: Center(
        child: FilledButton.icon(
          onPressed: _toggleRecording,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
 