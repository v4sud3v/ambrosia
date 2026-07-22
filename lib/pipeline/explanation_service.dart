import 'package:flutter/foundation.dart';

import 'explainer.dart';
import 'explanation.dart';
import 'extraction.dart';

enum ExplanationStatus {
  idle,
  preparingModel, // one-time weight download (shared with extraction)
  explaining,
  done,
  error,
}

/// Drives Module 4: takes a structured [Extraction] and produces a
/// patient-facing [Explanation] fully on-device.
///
/// Same shape as the other pipeline services — a [ChangeNotifier] over an
/// injected [Explainer] seam with a synchronous busy-guard.
class ExplanationService extends ChangeNotifier {
  ExplanationService({required Explainer explainer})
      : _explainer = explainer; // ignore: prefer_initializing_formals

  final Explainer _explainer;

  bool _running = false;
  ExplanationStatus _status = ExplanationStatus.idle;
  Explanation? _explanation;
  String? _errorMessage;

  ExplanationStatus get status => _status;
  Explanation? get explanation => _explanation;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == ExplanationStatus.preparingModel ||
      _status == ExplanationStatus.explaining;

  /// Explain [extraction], downloading the model first if needed.
  Future<void> run(Extraction extraction) async {
    if (_running) return; // guard set synchronously, before the first await
    _running = true;

    _errorMessage = null;
    _explanation = null;

    try {
      if (!await _explainer.isModelReady()) {
        _setStatus(ExplanationStatus.preparingModel);
        await _explainer.downloadModel();
      }

      _setStatus(ExplanationStatus.explaining);
      _explanation = await _explainer.explain(extraction);
      _setStatus(ExplanationStatus.done);
    } on ExplanationException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Explanation failed on this device. Try again.');
    } finally {
      _running = false;
    }
  }

  void _setStatus(ExplanationStatus status) {
    _status = status;
    notifyListeners();
  }

  void _fail(String message) {
    _status = ExplanationStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
