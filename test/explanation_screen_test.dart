import 'package:ambrosia/pipeline/explanation.dart';
import 'package:ambrosia/pipeline/explanation_screen.dart';
import 'package:ambrosia/pipeline/explanation_service.dart';
import 'package:ambrosia/pipeline/extraction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'explanation_service_test.dart' show FakeExplainer;

void main() {
  testWidgets('shows the plain-language sections when done', (tester) async {
    final service = ExplanationService(
      explainer: FakeExplainer(
        result: const Explanation(
          condition: 'A viral fever your body clears on its own.',
          recovery: 'Rest and drink fluids.',
          avoid: ['Cold drinks'],
          dangerSigns: ['Trouble breathing'],
        ),
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: ExplanationScreen(extraction: const Extraction(), service: service),
    ));
    await tester.pumpAndSettle();

    expect(find.text('What this is'), findsOneWidget);
    expect(find.text('Getting better'), findsOneWidget);
    expect(find.text('Things to avoid'), findsOneWidget);
    expect(find.text('See a doctor if…'), findsOneWidget);
    expect(find.text('Trouble breathing'), findsOneWidget);
    expect(find.text('Written on this device. Nothing is uploaded.'),
        findsOneWidget);
  });

  testWidgets('shows a retry on failure', (tester) async {
    final service = ExplanationService(
      explainer: FakeExplainer(throwMessage: 'no plain words'),
    );

    await tester.pumpWidget(MaterialApp(
      home: ExplanationScreen(extraction: const Extraction(), service: service),
    ));
    await tester.pumpAndSettle();

    expect(find.text('no plain words'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
  });
}
