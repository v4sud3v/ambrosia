import 'package:meta/meta.dart';

/// Plain-language explanation for the patient — the output of Module 4.
///
/// This is what a patient (not a clinician) reads: what the condition is, how
/// recovery looks, what to avoid, and when to seek help. Like the extraction,
/// it's an unverified draft the doctor reviews (Module 5) before it becomes a
/// PDF.
@immutable
class Explanation {
  const Explanation({
    this.condition = '',
    this.recovery = '',
    this.avoid = const [],
    this.dangerSigns = const [],
  });

  /// What the condition is, in plain words.
  final String condition;

  /// What getting better looks like / what to expect.
  final String recovery;

  /// Things to avoid while recovering.
  final List<String> avoid;

  /// Signs that mean "come back / go to a hospital".
  final List<String> dangerSigns;

  bool get isEmpty =>
      condition.trim().isEmpty &&
      recovery.trim().isEmpty &&
      avoid.isEmpty &&
      dangerSigns.isEmpty;
}
