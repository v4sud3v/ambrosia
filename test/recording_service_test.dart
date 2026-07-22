import 'package:ambrosia/recorder/audio_backend.dart';
import 'package:ambrosia/recorder/recording_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records calls and lets each test dictate outcomes.
class FakeAudioBackend implements AudioBackend {
  bool permission = true;
  bool throwOnStart = false;
  bool throwOnStop = false;
  String? stopReturns; // null → plugin reported nothing saved

  String? startedPath;
  int startCount = 0;
  int stopCount = 0;
  bool disposed = false;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start(String path) async {
    if (throwOnStart) throw Exception('boom');
    startCount++;
    startedPath = path;
  }

  @override
  Future<String?> stop() async {
    if (throwOnStop) throw Exception('boom');
    stopCount++;
    return stopReturns ?? startedPath;
  }

  @override
  Future<void> dispose() async => disposed = true;
}

RecordingService buildService(FakeAudioBackend backend) {
  return RecordingService(
    backend: backend,
    tempDirPath: () async => '/tmp/ambrosia',
    now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

void main() {
  group('formatDuration', () {
    test('renders m:ss for short recordings', () {
      expect(RecordingService.formatDuration(Duration.zero), '0:00');
      expect(RecordingService.formatDuration(const Duration(seconds: 5)), '0:05');
      expect(
        RecordingService.formatDuration(const Duration(minutes: 2, seconds: 37)),
        '2:37',
      );
    });

    test('grows to h:mm:ss only past an hour', () {
      expect(
        RecordingService.formatDuration(
            const Duration(hours: 1, minutes: 4, seconds: 9)),
        '1:04:09',
      );
    });
  });

  group('start', () {
    test('goes live and writes a namespaced temp path', () async {
      final backend = FakeAudioBackend();
      final service = buildService(backend);

      await service.start();

      expect(service.status, RecordingStatus.recording);
      expect(service.isRecording, isTrue);
      expect(backend.startCount, 1);
      expect(service.lastRecordingPath,
          '/tmp/ambrosia/consultation_1700000000000.wav');
      expect(backend.startedPath, service.lastRecordingPath);

      await service.stop();
    });

    test('surfaces an error when permission is denied', () async {
      final backend = FakeAudioBackend()..permission = false;
      final service = buildService(backend);

      await service.start();

      expect(service.status, RecordingStatus.error);
      expect(service.errorMessage, isNotNull);
      expect(backend.startCount, 0);
    });

    test('surfaces an error when the backend fails to start', () async {
      final backend = FakeAudioBackend()..throwOnStart = true;
      final service = buildService(backend);

      await service.start();

      expect(service.status, RecordingStatus.error);
      expect(service.errorMessage, isNotNull);
    });

    test('is a no-op while already recording', () async {
      final backend = FakeAudioBackend();
      final service = buildService(backend);

      await service.start();
      await service.start();

      expect(backend.startCount, 1);
      await service.stop();
    });
  });

  group('stop', () {
    test('settles on saved and keeps the file path', () async {
      final backend = FakeAudioBackend();
      final service = buildService(backend);

      await service.start();
      final path = service.lastRecordingPath;
      await service.stop();

      expect(service.status, RecordingStatus.saved);
      expect(service.lastRecordingPath, path);
      expect(backend.stopCount, 1);
    });

    test('keeps the pre-stop path if the plugin reports nothing', () async {
      final backend = FakeAudioBackend()..stopReturns = null;
      final service = buildService(backend);

      await service.start();
      final path = service.lastRecordingPath;
      await service.stop();

      expect(service.lastRecordingPath, path);
    });

    test('errors when the backend fails to stop', () async {
      final backend = FakeAudioBackend()..throwOnStop = true;
      final service = buildService(backend);

      await service.start();
      await service.stop();

      expect(service.status, RecordingStatus.error);
    });

    test('is a no-op when not recording', () async {
      final backend = FakeAudioBackend();
      final service = buildService(backend);

      await service.stop();

      expect(backend.stopCount, 0);
      expect(service.status, RecordingStatus.idle);
    });
  });

  group('reset', () {
    test('returns to idle and clears the last path', () async {
      final backend = FakeAudioBackend();
      final service = buildService(backend);

      await service.start();
      await service.stop();
      service.reset();

      expect(service.status, RecordingStatus.idle);
      expect(service.lastRecordingPath, isNull);
      expect(service.elapsed, Duration.zero);
    });

    test('refuses to reset mid-recording', () async {
      final backend = FakeAudioBackend();
      final service = buildService(backend);

      await service.start();
      service.reset();

      expect(service.status, RecordingStatus.recording);
      await service.stop();
    });
  });
}
