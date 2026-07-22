import 'package:flutter/widgets.dart';

import 'explanation.dart';
import 'extraction.dart';

/// The doctor-confirmed result of the review step. It only exists once the
/// doctor has explicitly confirmed — the pipeline must not build a PDF from
/// anything else. This is the product's accuracy safety net.
@immutable
class ConfirmedReview {
  const ConfirmedReview({required this.extraction, required this.explanation});
  final Extraction extraction;
  final Explanation explanation;
}

/// Editable text fields for one medicine row.
class MedicineDraft {
  MedicineDraft({String name = '', String dosage = '', String frequency = '', String duration = ''})
      : name = TextEditingController(text: name),
        dosage = TextEditingController(text: dosage),
        frequency = TextEditingController(text: frequency),
        duration = TextEditingController(text: duration);

  MedicineDraft.from(Medicine m)
      : this(name: m.name, dosage: m.dosage, frequency: m.frequency, duration: m.duration);

  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController frequency;
  final TextEditingController duration;

  Medicine toMedicine() => Medicine(
        name: name.text.trim(),
        dosage: dosage.text.trim(),
        frequency: frequency.text.trim(),
        duration: duration.text.trim(),
      );

  bool get isBlank => name.text.trim().isEmpty;

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
  }
}

/// Holds the editable draft of the extraction + explanation and gates
/// progression on an explicit [confirm]. Editing after a confirm clears it, so
/// the doctor can never advance a stale/unreviewed change.
class ReviewController extends ChangeNotifier {
  ReviewController({
    required Extraction extraction,
    required Explanation explanation,
  })  : diagnosis = TextEditingController(text: extraction.diagnosis),
        followUp = TextEditingController(text: extraction.followUp),
        condition = TextEditingController(text: explanation.condition),
        recovery = TextEditingController(text: explanation.recovery),
        medicines = extraction.medicines.map(MedicineDraft.from).toList(),
        avoid = explanation.avoid.map((t) => TextEditingController(text: t)).toList(),
        dangerSigns =
            explanation.dangerSigns.map((t) => TextEditingController(text: t)).toList() {
    _wireInvalidation();
  }

  final TextEditingController diagnosis;
  final TextEditingController followUp;
  final TextEditingController condition;
  final TextEditingController recovery;
  final List<MedicineDraft> medicines;
  final List<TextEditingController> avoid;
  final List<TextEditingController> dangerSigns;

  bool _confirmed = false;
  bool get confirmed => _confirmed;

  /// Any edit after a confirmation invalidates it — the doctor must re-confirm.
  void _wireInvalidation() {
    for (final c in _allControllers()) {
      c.addListener(_onEdited);
    }
  }

  void _onEdited() {
    if (_confirmed) {
      _confirmed = false;
      notifyListeners();
    }
  }

  Iterable<TextEditingController> _allControllers() sync* {
    yield diagnosis;
    yield followUp;
    yield condition;
    yield recovery;
    for (final m in medicines) {
      yield m.name;
      yield m.dosage;
      yield m.frequency;
      yield m.duration;
    }
    yield* avoid;
    yield* dangerSigns;
  }

  void addMedicine() {
    final draft = MedicineDraft();
    draft.name.addListener(_onEdited);
    draft.dosage.addListener(_onEdited);
    draft.frequency.addListener(_onEdited);
    draft.duration.addListener(_onEdited);
    medicines.add(draft);
    _onEdited();
    notifyListeners();
  }

  void removeMedicine(int index) {
    medicines.removeAt(index).dispose();
    _onEdited();
    notifyListeners();
  }

  void addAvoid() => _addItem(avoid);
  void removeAvoid(int index) => _removeItem(avoid, index);
  void addDangerSign() => _addItem(dangerSigns);
  void removeDangerSign(int index) => _removeItem(dangerSigns, index);

  void _addItem(List<TextEditingController> list) {
    final c = TextEditingController()..addListener(_onEdited);
    list.add(c);
    _onEdited();
    notifyListeners();
  }

  void _removeItem(List<TextEditingController> list, int index) {
    list.removeAt(index).dispose();
    _onEdited();
    notifyListeners();
  }

  /// Mark the review confirmed and return the doctor-approved result.
  ConfirmedReview confirm() {
    _confirmed = true;
    notifyListeners();
    return ConfirmedReview(
      extraction: buildExtraction(),
      explanation: buildExplanation(),
    );
  }

  Extraction buildExtraction() => Extraction(
        diagnosis: diagnosis.text.trim(),
        medicines: medicines
            .where((m) => !m.isBlank)
            .map((m) => m.toMedicine())
            .toList(),
        followUp: followUp.text.trim(),
      );

  Explanation buildExplanation() => Explanation(
        condition: condition.text.trim(),
        recovery: recovery.text.trim(),
        avoid: _nonEmpty(avoid),
        dangerSigns: _nonEmpty(dangerSigns),
      );

  List<String> _nonEmpty(List<TextEditingController> list) => list
      .map((c) => c.text.trim())
      .where((t) => t.isNotEmpty)
      .toList(growable: false);

  @override
  void dispose() {
    for (final c in _allControllers()) {
      c.dispose();
    }
    super.dispose();
  }
}
