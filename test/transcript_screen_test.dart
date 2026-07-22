import 'package:ambrosia/pipeline/transcript.dart';
import 'package:ambrosia/pipeline/transcription_service.dart';
import 'package:ambrosia/pipeline/transcript_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transcription_service_test.dart' show FakeTranscriber;

void main() {
  testWidgets('shows the transcript when done', (tester) async {
    final service = TranscriptionService(
      transcriber: FakeTranscriber(
        result: const Transcript(text: 'patient has a mild fever'),
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: TranscriptScreen(audioPath: '/tmp/a.wav', service: service),
    ));
    await tester.pumpAndSettle();

    expect(find.text('patient has a mild fever'), findsOneWidget);
    expect(find.text('What was said'), findsOneWidget);
    expect(find.text('Transcribed on this device. Nothing is uploaded.'),
        findsOneWidget);
  });

  testWidgets('shows a retry action on failure', (tester) async {
    final service = TranscriptionService(
      transcriber: FakeTranscriber(throwMessage: 'engine failed'),
    );

    await tester.pumpWidget(MaterialApp(
      home: TranscriptScreen(audioPath: '/tmp/a.wav', service: service),
    ));
    await tester.pumpAndSettle();

    expect(find.text('engine failed'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
  });
}
