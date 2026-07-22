/// Builds the extraction prompt for the on-device LLM.
///
/// Kept as a pure function so the prompt can be unit-tested and iterated
/// without touching the model. The instruction is deliberately strict about
/// JSON-only output and about *not inventing* details — the model runs small
/// (Gemma 3 2B INT4) and its draft is reviewed by the doctor, so a faithful
/// "I didn't hear that" (empty field) beats a confident hallucination.
String buildExtractionPrompt(String transcript) {
  return '''
You are a clinical scribe. From the doctor–patient consultation transcript
below, extract the plan into JSON. The transcript may mix Malayalam and English.

Rules:
- Output ONLY a single JSON object. No prose, no markdown, no code fences.
- Use this exact shape:
{
  "diagnosis": "",
  "medicines": [
    { "name": "", "dosage": "", "frequency": "", "duration": "" }
  ],
  "follow_up": ""
}
- If something was not clearly stated, leave that field as an empty string
  (or an empty medicines array). Do NOT guess or add anything not in the
  transcript.
- "follow_up" is when/whether to return (e.g. "Review in 5 days").

Transcript:
"""
$transcript
"""

JSON:''';
}
