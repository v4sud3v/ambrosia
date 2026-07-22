import 'dart:io';

import 'package:ambrosia/pipeline/whisper_transcriber.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Real on-device verification of Module 2: downloads the (tiny) Whisper model
/// once, then transcribes a bundled 16 kHz mono WAV of spoken English and
/// checks the words come back. Proves the native whisper.cpp path actually runs
/// on the device, not just the Dart state machine.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('transcribes a real recording on-device', (tester) async {
    // Copy the bundled fixture into the app sandbox as a real file path.
    final bytes = await rootBundle.load('assets/fixtures/sample.wav');
    final dir = await getTemporaryDirectory();
    await dir.create(recursive: true);
    final wav = File('${dir.path}/sample.wav');
    await wav.writeAsBytes(bytes.buffer.asUint8List());

    // Tiny model + English keeps the download small and the check robust; the
    // shipped app defaults to Whisper small with auto language detection.
    final transcriber = WhisperTranscriber(
      model: WhisperModel.tiny,
      language: 'en',
    );

    // One-time model weight download (the only network call the app permits).
    if (!await transcriber.isModelReady()) {
      await transcriber.downloadModel();
    }

    final transcript = await transcriber.transcribe(wav.path);

    // ignore: avoid_print
    print('ON-DEVICE TRANSCRIPT => "${transcript.text}"');

    expect(transcript.isEmpty, isFalse);
    final lower = transcript.text.toLowerCase();
    expect(
      lower.contains('fever') ||
          lower.contains('cough') ||
          lower.contains('patient'),
      isTrue,
      reason: 'expected the spoken words back, got: "${transcript.text}"',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
