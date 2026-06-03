import 'dart:io';

import '../bridge/ambrosia_bridge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  AudioService({required this.engine});

  final AmbrosiaEngine engine;
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  Future<String> startRecording() async {
    final permitted = await _recorder.hasPermission();
    if (!permitted) {
      throw const AudioServiceException('Microphone permission denied');
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'ambrosia_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final filePath = '${tempDir.path}/$fileName';

    await _recorder.start(const RecordConfig(), path: filePath);

    return filePath;
  }

  Future<AudioProcessingResult> stopRecordingAndProcess() async {
    final path = await _recorder.stop();
    if (path == null) {
      throw const AudioServiceException('No recording was created');
    }

    try {
      final engineResult = engine.processAudioFile(path);
      return AudioProcessingResult(
        filePath: path,
        message: engineResult.message,
        bytes: engineResult.bytes,
      );
    } finally {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

class AudioProcessingResult {
  const AudioProcessingResult({
    required this.filePath,
    required this.message,
    required this.bytes,
  });

  final String filePath;
  final String message;
  final int bytes;
}

class AudioServiceException implements Exception {
  const AudioServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
