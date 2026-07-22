import 'package:ambrosia/pipeline/transcript.dart';
import 'package:ambrosia/pipeline/transcriber.dart';
import 'package:ambrosia/pipeline/transcription_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic transcriber that records interactions.
class FakeTranscriber implements Transcriber {
  FakeTranscriber({
    this.modelReady = true,
    this.result = const Transcript(text: 'fever and cough for three days'),
    this.throwMessage,
  });

  bool modelReady;
  Transcript result;
  String? throwMessage;

  int downloadCount = 0;
  int transcribeCount = 0;
  final List<double> reportedProgress = [];

  @override
  Future<bool> isModelReady() async => modelReady;

  @override
  Future<void> downloadModel() async {
    downloadCount++;
    modelReady = true;
  }

  @override
  Future<Transcript> transcribe(
    String audioPath, {
    void Function(double progress)? onProgress,
  }) async {
    transcribeCount++;
    if (throwMessage != null) throw TranscriptionException(throwMessage!);
    onProgress?.call(0.5);
    onProgress?.call(1.0);
    return result;
  }
}

void main() {
  test('transcribes directly when the model is already present', () async {
    final fake = FakeTranscriber(modelReady: true);
    final service = TranscriptionService(transcriber: fake);

    await service.run('/tmp/consultation.wav');

    expect(service.status, TranscriptionStatus.done);
    expect(service.transcript?.text, 'fever and cough for three days');
    expect(fake.downloadCount, 0);
    expect(service.progress, 1.0);
  });

  test('downloads the model first when it is missing', () async {
    final fake = FakeTranscriber(modelReady: false);
    final service = TranscriptionService(transcriber: fake);

    final seen = <TranscriptionStatus>[];
    service.addListener(() => seen.add(service.status));

    await service.run('/tmp/consultation.wav');

    expect(fake.downloadCount, 1);
    expect(seen, contains(TranscriptionStatus.preparingModel));
    expect(seen, contains(TranscriptionStatus.transcribing));
    expect(service.status, TranscriptionStatus.done);
  });

  test('surfaces an engine failure as an error', () async {
    final fake = FakeTranscriber(throwMessage: 'boom');
    final service = TranscriptionService(transcriber: fake);

    await service.run('/tmp/consultation.wav');

    expect(service.status, TranscriptionStatus.error);
    expect(service.errorMessage, 'boom');
  });

  test('treats an empty transcript as a recoverable error', () async {
    final fake = FakeTranscriber(result: const Transcript(text: '   '));
    final service = TranscriptionService(transcriber: fake);

    await service.run('/tmp/consultation.wav');

    expect(service.status, TranscriptionStatus.error);
    expect(service.errorMessage, contains('No speech'));
  });

  test('ignores a second run while busy', () async {
    final fake = FakeTranscriber();
    final service = TranscriptionService(transcriber: fake);

    final first = service.run('/tmp/a.wav');
    final second = service.run('/tmp/b.wav'); // should be ignored while busy
    await Future.wait([first, second]);

    expect(fake.transcribeCount, 1);
  });
}
