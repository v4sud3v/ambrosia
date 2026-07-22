import 'package:flutter/foundation.dart';

import 'extraction.dart';
import 'extractor.dart';

enum ExtractionStatus {
  idle,
  preparingModel, // one-time weight download
  extracting,
  done,
  error,
}

/// Drives Module 3: takes a transcript and produces a structured [Extraction]
/// fully on-device.
///
/// Same shape as [RecordingService] / [TranscriptionService] — a
/// [ChangeNotifier] over an injected [Extractor] seam, unit-testable with a
/// fake and with a synchronous busy-guard.
class ExtractionService extends ChangeNotifier {
  ExtractionService({required Extractor extractor})
      : _extractor = extractor; // ignore: prefer_initializing_formals

  final Extractor _extractor;

  bool _running = false;
  ExtractionStatus _status = ExtractionStatus.idle;
  Extraction? _extraction;
  String? _errorMessage;

  ExtractionStatus get status => _status;
  Extraction? get extraction => _extraction;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == ExtractionStatus.preparingModel ||
      _status == ExtractionStatus.extracting;

  /// Extract from [transcript], downloading the model first if needed.
  Future<void> run(String transcript) async {
    if (_running) return; // guard set synchronously, before the first await
    _running = true;

    _errorMessage = null;
    _extraction = null;

    try {
      if (!await _extractor.isModelReady()) {
        _setStatus(ExtractionStatus.preparingModel);
        await _extractor.downloadModel();
      }

      _setStatus(ExtractionStatus.extracting);
      _extraction = await _extractor.extract(transcript);
      _setStatus(ExtractionStatus.done);
    } on ExtractionException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Extraction failed on this device. Try again.');
    } finally {
      _running = false;
    }
  }

  void _setStatus(ExtractionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _fail(String message) {
    _status = ExtractionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
