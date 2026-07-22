import 'extraction.dart';

/// Builds the explanation prompt from the structured plan.
///
/// Pure function, so it's unit-testable and easy to iterate. The instruction
/// pushes for plain, reassuring, patient-facing language (the reader is a
/// patient, not a clinician) and — as with extraction — forbids inventing
/// medical advice the plan doesn't support. Danger signs are the one place we
/// want completeness, so the prompt asks for the common ones for the condition.
String buildExplanationPrompt(Extraction extraction) {
  final meds = extraction.medicines.isEmpty
      ? '(none noted)'
      : extraction.medicines.map((m) => '- ${m.summary}').join('\n');

  return '''
You are explaining a doctor's plan to a patient who has no medical training.
Write in short, simple, reassuring sentences. Avoid jargon. Do not invent a
diagnosis or treatment beyond what the plan says.

The plan:
Diagnosis: ${extraction.diagnosis.isEmpty ? '(not stated)' : extraction.diagnosis}
Medicines:
$meds
Follow-up: ${extraction.followUp.isEmpty ? '(not stated)' : extraction.followUp}

Output ONLY a single JSON object, no prose, no markdown, no code fences, with
this exact shape:
{
  "condition": "",
  "recovery": "",
  "avoid": [""],
  "danger_signs": [""]
}

Guidance:
- "condition": one or two plain sentences on what this is.
- "recovery": what getting better looks like and how to take the medicines.
- "avoid": a few things to avoid while recovering (short items).
- "danger_signs": clear signs that mean the patient should see a doctor again
  or go to a hospital. List the common ones for this condition.

JSON:''';
}
