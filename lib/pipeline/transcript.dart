import 'package:flutter/foundation.dart';

/// One timestamped chunk of transcribed speech.
@immutable
class TranscriptSegment {
  const TranscriptSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  final Duration start;
  final Duration end;
  final String text;
}

/// The raw output of Module 2 — what Whisper heard, before any extraction.
///
/// This is a plain data object with no plugin types, so the rest of the
/// pipeline (extraction, review, PDF) never depends on the STT engine.
@immutable
class Transcript {
  const Transcript({
    required this.text,
    this.segments = const [],
    this.processingTime = Duration.zero,
  });

  /// Full transcript text.
  final String text;

  /// Per-segment timestamps, when the engine provides them.
  final List<TranscriptSegment> segments;

  /// How long transcription took (useful for on-device latency budgeting).
  final Duration processingTime;

  bool get isEmpty => text.trim().isEmpty;
}
