import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  AudioService({
    required this.backendBaseUrl,
  });

  final String backendBaseUrl;
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

    await _recorder.start(
      const RecordConfig(),
      path: filePath,
    );

    return filePath;
  }

  Future<UploadResult> stopRecordingAndUpload() async {
    final path = await _recorder.stop();
    if (path == null) {
      throw const AudioServiceException('No recording was created');
    }

    final responseBody = await _uploadFile(path);
    return UploadResult(
      filePath: path,
      responseBody: responseBody,
    );
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  Future<String> _uploadFile(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    final client = HttpClient();
    try {
      final uri = Uri.parse('$backendBaseUrl/upload-audio');
      final request = await client.postUrl(uri);

      request.headers.contentType = ContentType('application', 'octet-stream');
      request.headers.set('x-file-name', path.split('/').last);

      request.add(bytes);

      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AudioServiceException(
          'Upload failed: ${response.statusCode} $body',
        );
      }

      return body;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

class UploadResult {
  const UploadResult({
    required this.filePath,
    required this.responseBody,
  });

  final String filePath;
  final String responseBody;
}

class AudioServiceException implements Exception {
  const AudioServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}