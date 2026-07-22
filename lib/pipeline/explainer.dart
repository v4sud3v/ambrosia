import 'explanation.dart';
import 'extraction.dart';

/// Thrown when explanation cannot produce a usable [Explanation].
class ExplanationException implements Exception {
  const ExplanationException(this.message);
  final String message;
  @override
  String toString() => 'ExplanationException: $message';
}

/// On-device plain-language explanation seam.
///
/// [ExplanationService] depends on this rather than the Gemma engine, so the
/// state machine, prompt and parser can be exercised with a fake.
///
/// Implementations must run inference on-device. The only permitted network
/// call is the one-time model weight download in [downloadModel].
abstract class Explainer {
  /// Whether the model weights are already present locally.
  Future<bool> isModelReady();

  /// Fetch the model weights once and cache them on-device. No-op if present.
  Future<void> downloadModel();

  /// Produce a patient-facing [Explanation] from a structured [extraction],
  /// fully on-device. Throws [ExplanationException] on failure.
  Future<Explanation> explain(Extraction extraction);
}
