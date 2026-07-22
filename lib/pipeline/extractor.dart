import 'extraction.dart';

/// Thrown when extraction cannot produce a usable [Extraction].
class ExtractionException implements Exception {
  const ExtractionException(this.message);
  final String message;
  @override
  String toString() => 'ExtractionException: $message';
}

/// On-device structured-extraction seam.
///
/// [ExtractionService] depends on this rather than the Gemma plugin, so the
/// state machine, prompt, and parser can be exercised without a 2B model, and
/// the engine can later be swapped for a fine-tuned checkpoint.
///
/// Implementations must run inference on-device. The only permitted network
/// call is the one-time model weight download in [downloadModel].
abstract class Extractor {
  /// Whether the model weights are already present locally.
  Future<bool> isModelReady();

  /// Fetch the model weights once and cache them on-device. No-op if present.
  Future<void> downloadModel();

  /// Extract structured data from [transcript] fully on-device.
  ///
  /// Throws [ExtractionException] if the model fails or emits nothing usable.
  Future<Extraction> extract(String transcript);
}
