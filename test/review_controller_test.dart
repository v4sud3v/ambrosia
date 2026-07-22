import 'package:ambrosia/pipeline/explanation.dart';
import 'package:ambrosia/pipeline/extraction.dart';
import 'package:ambrosia/pipeline/review_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _extraction = Extraction(
  diagnosis: 'Viral fever',
  medicines: [Medicine(name: 'Paracetamol', dosage: '500 mg')],
  followUp: 'Review in 5 days',
);

const _explanation = Explanation(
  condition: 'A mild viral fever.',
  recovery: 'Rest and fluids.',
  avoid: ['Cold drinks'],
  dangerSigns: ['Trouble breathing'],
);

ReviewController build() =>
    ReviewController(extraction: _extraction, explanation: _explanation);

void main() {
  test('seeds fields from the extraction and explanation', () {
    final c = build();
    expect(c.diagnosis.text, 'Viral fever');
    expect(c.medicines.single.name.text, 'Paracetamol');
    expect(c.avoid.single.text, 'Cold drinks');
    expect(c.dangerSigns.single.text, 'Trouble breathing');
    expect(c.confirmed, isFalse);
    c.dispose();
  });

  test('confirm returns the edited result and sets confirmed', () {
    final c = build();
    c.diagnosis.text = 'Dengue fever';
    c.avoid.single.text = 'Aspirin';

    final result = c.confirm();

    expect(c.confirmed, isTrue);
    expect(result.extraction.diagnosis, 'Dengue fever');
    expect(result.explanation.avoid, ['Aspirin']);
    c.dispose();
  });

  test('editing after confirm invalidates the confirmation', () {
    final c = build();
    c.confirm();
    expect(c.confirmed, isTrue);

    c.recovery.text = 'Drink extra fluids';
    expect(c.confirmed, isFalse);
    c.dispose();
  });

  test('drops blank medicines and empty list items on build', () {
    final c = build();
    c.addMedicine(); // blank row
    c.addAvoid(); // empty item

    final result = c.confirm();
    expect(result.extraction.medicines.length, 1);
    expect(result.extraction.medicines.single.name, 'Paracetamol');
    expect(result.explanation.avoid, ['Cold drinks']);
    c.dispose();
  });

  test('supports adding and removing medicines', () {
    final c = build();
    c.addMedicine();
    c.medicines.last.name.text = 'ORS';
    expect(c.medicines.length, 2);

    c.removeMedicine(0); // remove Paracetamol
    final result = c.confirm();
    expect(result.extraction.medicines.single.name, 'ORS');
    c.dispose();
  });
}
