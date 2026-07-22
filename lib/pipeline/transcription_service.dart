import 'package:flutter/foundation.dart';

import 'transcript.dart';
import 'transcriber.dart';

enum TranscriptionStatus {
  idle,
  preparingModel, // one-time weight download
  transcribing,
  done,
  error,
}

/// Drives Module 2: takes a recorded WAV path and produces a [Transcript] fully
/// on-device, exposing status + progress for the UI.
///
/// Mirrors [RecordingService]'s shape — a [ChangeNotifier] over an injected
/// [Transcriber] seam so it's unit-testable with a fake.
class TranscriptionService extends ChangeNotifier {
  TranscriptionService({required Transcriber transcriber})
      : _transcriber = transcriber; // ignore: prefer_initializing_formals

  final Transcriber _transcriber;

  bool _running = false;
  TranscriptionStatus _status = TranscriptionStatus.idle;
  double _progress = 0;
  Transcript? _transcript;
  String? _errorMessage;

  TranscriptionStatus get status => _status;

  /// Decode progress 0.0–1.0 (meaningful only while [TranscriptionStatus.transcribing]).
  double get progress => _progress;
  Transcript? get transcript => _transcript;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == TranscriptionStatus.preparingModel ||
      _status == TranscriptionStatus.transcribing;

  /// Transcribe [audioPath], downloading the model first if needed.
  Future<void> run(String audioPath) async {
    if (_running) return; // guard set synchronously, before the first await
    _running = true;

    _errorMessage = null;
    _transcript = null;
    _progress = 0;

    try {
      if (!await _transcriber.isModelReady()) {
        _setStatus(TranscriptionStatus.preparingModel);
        await _transcriber.downloadModel();
      }

      _setStatus(TranscriptionStatus.transcribing);
      final transcript = await _transcriber.transcribe(
        audioPath,
        onProgress: (p) {
          _progress = p.clamp(0, 1);
          notifyListeners();
        },
      );

      if (transcript.isEmpty) {
        _fail('No speech was picked up. Try recording again.');
        return;
      }

      _transcript = transcript;
      _progress = 1;
      _setStatus(TranscriptionStatus.done);
    } on TranscriptionException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Transcription failed on this device. Try again.');
    } finally {
      _running = false;
    }
  }

  void _setStatus(TranscriptionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _fail(String message) {
    _status = TranscriptionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
