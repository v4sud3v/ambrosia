import 'package:ambrosia/pipeline/extraction.dart';
import 'package:ambrosia/pipeline/extraction_screen.dart';
import 'package:ambrosia/pipeline/extraction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'extraction_service_test.dart' show FakeExtractor;

void main() {
  testWidgets('shows the structured plan when done', (tester) async {
    final service = ExtractionService(
      extractor: FakeExtractor(
        result: const Extraction(
          diagnosis: 'Viral fever',
          medicines: [Medicine(name: 'Paracetamol', dosage: '500 mg')],
          followUp: 'Review in 5 days',
        ),
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: ExtractionScreen(transcript: 't', service: service),
    ));
    await tester.pumpAndSettle();

    expect(find.text('DIAGNOSIS'), findsOneWidget);
    expect(find.text('Viral fever'), findsOneWidget);
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.text('Review in 5 days'), findsOneWidget);
    expect(find.text('Structured on this device. Nothing is uploaded.'),
        findsOneWidget);
  });

  testWidgets('shows empty-field guidance and a retry on failure',
      (tester) async {
    final service = ExtractionService(
      extractor: FakeExtractor(throwMessage: 'model returned junk'),
    );

    await tester.pumpWidget(MaterialApp(
      home: ExtractionScreen(transcript: 't', service: service),
    ));
    await tester.pumpAndSettle();

    expect(find.text('model returned junk'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
  });
}
