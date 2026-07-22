import 'package:record/record.dart';

/// Thin seam over the platform recorder.
///
/// [RecordingService] talks to this interface instead of the concrete
/// [AudioRecorder] so its state machine can be unit-tested with a fake, and so
/// the rest of the app never touches the plugin directly.
abstract class AudioBackend {
  /// Whether the microphone permission has been granted (prompts if needed).
  Future<bool> hasPermission();

  /// Begin capturing audio to [path].
  Future<void> start(String path);

  /// Stop capturing. Returns the path of the written file, or null if nothing
  /// was recorded.
  Future<String?> stop();

  /// Release native resources.
  Future<void> dispose();
}

/// Production backend backed by the `record` plugin.
///
/// Records AAC-LC in an m4a container — a good size/quality balance for the
/// short (2–3 min) consultations Whisper will later transcribe on-device.
class RecordAudioBackend implements AudioBackend {
  RecordAudioBackend([AudioRecorder? recorder])
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) {
    return _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000, // Whisper operates at 16 kHz; no reason to store more
        numChannels: 1,
      ),
      path: path,
    );
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> dispose() => _recorder.dispose();
}
