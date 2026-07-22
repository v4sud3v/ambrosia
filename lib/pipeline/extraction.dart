import 'package:meta/meta.dart';

/// One prescribed medicine. Fields are optional because a doctor may not state
/// every detail aloud — the review card (Module 5) is where gaps get filled.
@immutable
class Medicine {
  const Medicine({
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
  });

  final String name;
  final String dosage; // e.g. "500 mg"
  final String frequency; // e.g. "twice daily"
  final String duration; // e.g. "5 days"

  /// A single human-readable line, skipping empty parts.
  String get summary => [name, dosage, frequency, duration]
      .where((p) => p.trim().isNotEmpty)
      .join(' · ');
}

/// Structured output of Module 3 — what the doctor decided, pulled from the
/// transcript. This is an unverified first draft: the doctor reviews and edits
/// it (Module 5) before anything is shared.
@immutable
class Extraction {
  const Extraction({
    this.diagnosis = '',
    this.medicines = const [],
    this.followUp = '',
  });

  final String diagnosis;
  final List<Medicine> medicines;
  final String followUp; // follow-up plan, e.g. "Review in 5 days"

  bool get isEmpty =>
      diagnosis.trim().isEmpty && medicines.isEmpty && followUp.trim().isEmpty;
}
