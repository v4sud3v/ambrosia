import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_backend.dart';

enum RecordingStatus { idle, recording, saved, error }

/// Owns the recording state machine for Module 1 (Recorder).
///
/// Responsibilities: request mic permission, write the consultation to a local
/// temp file, expose live status + elapsed duration, and surface the saved file
/// path for the next stage of the pipeline (Whisper STT). Nothing here touches
/// the network — the recording never leaves the device.
class RecordingService extends ChangeNotifier {
  RecordingService({
    required AudioBackend backend,
    Future<String> Function()? tempDirPath,
    DateTime Function()? now,
  })  : _backend = backend, // ignore: prefer_initializing_formals
        _tempDirPath = tempDirPath ?? _defaultTempDirPath,
        _now = now ?? DateTime.now;

  final AudioBackend _backend;
  final Future<String> Function() _tempDirPath;
  final DateTime Function() _now;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  RecordingStatus _status = RecordingStatus.idle;
  Duration _elapsed = Duration.zero;
  String? _lastRecordingPath;
  String? _errorMessage;

  RecordingStatus get status => _status;
  Duration get elapsed => _elapsed;
  String? get lastRecordingPath => _lastRecordingPath;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _status == RecordingStatus.recording;

  static Future<String> _defaultTempDirPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// Start a new recording. Any previously saved recording is discarded from
  /// state (the next pipeline stage is expected to have consumed it already).
  Future<void> start() async {
    if (_status == RecordingStatus.recording) return;

    if (!await _backend.hasPermission()) {
      _fail('Microphone access is off. Enable it in Settings to record.');
      return;
    }

    final path = await _buildTempFilePath();
    try {
      await _backend.start(path);
    } catch (_) {
      _fail("Couldn't start recording. Try again.");
      return;
    }

    _lastRecordingPath = path;
    _errorMessage = null;
    _elapsed = Duration.zero;
    _status = RecordingStatus.recording;
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _elapsed = _stopwatch.elapsed;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Stop recording and settle on the saved file.
  Future<void> stop() async {
    if (_status != RecordingStatus.recording) return;

    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _elapsed = _stopwatch.elapsed;

    String? path;
    try {
      path = await _backend.stop();
    } catch (_) {
      _fail("Couldn't save the recording. Try again.");
      return;
    }

    _lastRecordingPath = path ?? _lastRecordingPath;
    _status = RecordingStatus.saved;
    notifyListeners();
  }

  /// Return to the idle prompt, ready for a fresh recording.
  void reset() {
    if (_status == RecordingStatus.recording) return;
    _status = RecordingStatus.idle;
    _elapsed = Duration.zero;
    _lastRecordingPath = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<String> _buildTempFilePath() async {
    final dir = await _tempDirPath();
    final stamp = _now().millisecondsSinceEpoch;
    return '$dir/consultation_$stamp.wav';
  }

  void _fail(String message) {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _status = RecordingStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// `m:ss` for short consultations. Grows to `h:mm:ss` only if needed.
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      final mm = m.toString().padLeft(2, '0');
      return '$h:$mm:$ss';
    }
    return '$m:$ss';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _backend.dispose();
    super.dispose();
  }
}
