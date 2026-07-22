import 'transcript.dart';

/// Thrown when transcription cannot produce a transcript.
class TranscriptionException implements Exception {
  const TranscriptionException(this.message);
  final String message;
  @override
  String toString() => 'TranscriptionException: $message';
}

/// On-device speech-to-text seam.
///
/// [TranscriptionService] depends on this rather than the whisper plugin, so
/// the state machine and UI can be exercised with a fake and the engine can be
/// swapped (e.g. a fine-tuned model) without touching callers.
///
/// Implementations must never send audio off the device. The single permitted
/// network call is the one-time model weight download in [downloadModel].
abstract class Transcriber {
  /// Whether the model weights are already present locally.
  Future<bool> isModelReady();

  /// Fetch the model weights once and cache them on-device. No-op if present.
  Future<void> downloadModel();

  /// Transcribe the audio at [audioPath] (16 kHz mono WAV) fully on-device.
  ///
  /// [onProgress] reports 0.0–1.0 while decoding. Throws
  /// [TranscriptionException] if the engine fails.
  Future<Transcript> transcribe(
    String audioPath, {
    void Function(double progress)? onProgress,
  });
}
