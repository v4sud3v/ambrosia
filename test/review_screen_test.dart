import 'package:ambrosia/pipeline/explanation.dart';
import 'package:ambrosia/pipeline/extraction.dart';
import 'package:ambrosia/pipeline/review_controller.dart';
import 'package:ambrosia/pipeline/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _extraction = Extraction(
  diagnosis: 'Viral fever',
  medicines: [Medicine(name: 'Paracetamol', dosage: '500 mg')],
  followUp: 'Review in 5 days',
);

const _explanation = Explanation(
  condition: 'A mild viral fever.',
  dangerSigns: ['Trouble breathing'],
);

void main() {
  testWidgets('shows editable seeded fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ReviewScreen(extraction: _extraction, explanation: _explanation),
    ));

    // Fields near the top of the lazy list are rendered; danger-sign seeding
    // (off-screen here) is covered by review_controller_test.
    expect(find.text('Viral fever'), findsOneWidget);
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Confirm & continue'), findsOneWidget);
  });

  testWidgets('editing then confirming yields the edited result',
      (tester) async {
    ConfirmedReview? captured;

    await tester.pumpWidget(MaterialApp(
      home: ReviewScreen(
        extraction: _extraction,
        explanation: _explanation,
        onConfirmed: (r) => captured = r,
      ),
    ));

    await tester.enterText(find.text('Viral fever'), 'Dengue fever');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm & continue'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.extraction.diagnosis, 'Dengue fever');
  });
}
