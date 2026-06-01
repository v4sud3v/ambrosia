import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/audio_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AudioService _audioService;
  bool _isRecording = false;
  bool _isBusy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService(
      backendBaseUrl: AppConfig.backendBaseUrl,
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });

    try {
      if (_isRecording) {
        final result = await _audioService.stopRecordingAndUpload();
        setState(() {
          _isRecording = false;
          _statusMessage = 'Uploaded: ${result.filePath.split('/').last}';
        });
      } else {
        await _audioService.startRecording();
        setState(() {
          _isRecording = true;
          _statusMessage = 'Recording...';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = e.toString();
        _isRecording = false;
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = _isRecording ? Icons.stop : Icons.mic;
    final String label = _isRecording ? 'Stop' : 'Record';
    final Color? backgroundColor = _isRecording ? Colors.red : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ambrosia')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _isBusy ? null : _toggleRecording,
              icon: Icon(icon),
              label: Text(_isBusy ? 'Please wait...' : label),
              style: FilledButton.styleFrom(
                backgroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(_statusMessage!),
            ],
          ],
        ),
      ),
    );
  }
}