import 'dart:io';

import 'package:whisper_ggml/whisper_ggml.dart';

import 'transcript.dart';
import 'transcriber.dart';

/// Real on-device STT backed by whisper.cpp via `whisper_ggml`.
///
/// The model weights download once (the one network call the trust model
/// permits) and are cached in the app's library directory; every transcription
/// after that is fully offline. Audio is fed as a local file path and never
/// leaves the device.
class WhisperTranscriber implements Transcriber {
  WhisperTranscriber({
    this.model = WhisperModel.small, // per spec: Whisper small
    this.language = 'auto', // Malayalam-English code-mixed → let Whisper detect
    WhisperController? controller,
  }) : _controller = controller ?? WhisperController();

  final WhisperModel model;
  final String language;
  final WhisperController _controller;

  @override
  Future<bool> isModelReady() async {
    final path = await _controller.getPath(model);
    return File(path).existsSync();
  }

  @override
  Future<void> downloadModel() async {
    await _controller.downloadModel(model);
  }

  @override
  Future<Transcript> transcribe(
    String audioPath, {
    void Function(double progress)? onProgress,
  }) async {
    if (!File(audioPath).existsSync()) {
      throw const TranscriptionException('Recording file is missing.');
    }

    final result = await _controller.transcribe(
      model: model,
      audioPath: audioPath,
      lang: language,
      withSegments: true,
      onProgress: (percent) => onProgress?.call(percent / 100),
    );

    if (result == null) {
      throw const TranscriptionException(
        "Couldn't transcribe the recording on this device.",
      );
    }

    final segments = (result.transcription.segments ?? [])
        .map((s) => TranscriptSegment(
              start: s.fromTs,
              end: s.toTs,
              text: s.text.trim(),
            ))
        .toList();

    return Transcript(
      text: result.transcription.text.trim(),
      segments: segments,
      processingTime: result.time,
    );
  }
}
