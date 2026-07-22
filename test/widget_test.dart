import 'package:ambrosia/recorder/recorder_screen.dart';
import 'package:ambrosia/recorder/recording_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_service_test.dart' show FakeAudioBackend;

void main() {
  RecordingService serviceWith(FakeAudioBackend backend) => RecordingService(
        backend: backend,
        tempDirPath: () async => '/tmp/ambrosia',
      );

  testWidgets('shows the idle prompt and privacy reassurance', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RecorderScreen(service: serviceWith(FakeAudioBackend())),
    ));

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Audio stays on this device. Nothing is uploaded.'),
        findsOneWidget);
    expect(find.text('On device'), findsOneWidget);
  });

  testWidgets('tap toggles recording then saves', (tester) async {
    final service = serviceWith(FakeAudioBackend());
    await tester.pumpWidget(MaterialApp(home: RecorderScreen(service: service)));

    // Start
    await tester.tap(find.bySemanticsLabel('Start recording'));
    await tester.pump();
    expect(find.text('RECORDING'), findsOneWidget);

    // Stop
    await tester.tap(find.bySemanticsLabel('Stop recording'));
    await tester.pump();
    expect(find.text('Saved · ready for review'), findsOneWidget);
  });

  testWidgets('denied permission shows guidance', (tester) async {
    final service = serviceWith(FakeAudioBackend()..permission = false);
    await tester.pumpWidget(MaterialApp(home: RecorderScreen(service: service)));

    await tester.tap(find.bySemanticsLabel('Start recording'));
    await tester.pump();

    expect(find.textContaining('Microphone access is off'), findsOneWidget);
  });
}
