# Ambrosia

On-device mobile app for doctors. Records a 2–3 min consultation, transcribes
and extracts a diagnosis/medicine/follow-up plan with local LLMs, and turns
it into a plain-language visual PDF for the patient. Built with **Flutter**
(cross-platform, iOS + Android); on-device inference runs through platform
channels into native backends — see `docs/platform.md` for the rationale.

## The Non-Negotiable Rule

**Nothing leaves the device. Ever.** No backend, no cloud API calls, no
analytics/crash reporting SDKs that phone home, no database that syncs.
This is the entire product's trust model — a doctor uses this specifically
*because* it can't leak patient conversations. Any change that introduces
a network call touching audio, transcript, extracted JSON, or the PDF is
a critical bug, not a style violation. The only permitted network activity
is the one-time model weight download on first install.

If you (Claude) are about to add `fetch`, `axios`, `URLSession`, retrofit,
an SDK with telemetry, or any networking call — stop and ask first, even
if it looks read-only or diagnostic.

## Pipeline

```
record → Whisper (on-device STT) → transcript
       → Gemma 3 2B INT4 (on-device) → structured extraction (diagnosis, meds, follow-up)
       → Gemma → plain-language explanation (condition, recovery, avoid, danger signs)
       → doctor reviews/edits card (~5 sec)
       → render visual PDF
       → share via WhatsApp intent (OS share sheet, not an API call)
       → immediately delete audio, transcript, and JSON
```

Deletion is not "eventually" or "on app close" — it happens right after the
PDF is generated and handed off. If you're touching this flow, the deletion
step must remain in place and be easy to find in code review; don't bury it
behind a settings flag.

## Structure

```
/app or /src        # UI screens: record, review card, PDF preview
/models              # Whisper small + Gemma 3 2B INT4 (bundled or downloaded once)
/pipeline            # STT -> extraction -> explanation -> PDF, in that order
/finetune            # MLX scripts for later fine-tuning on doctor corrections (offline, not shipped in-app)
```
(Adjust paths above once the platform/framework is chosen — this is the
intended shape, not a guarantee of current file names.)

## Models

- **Whisper small** — on-device STT. Must handle noisy clinic audio.
- **Gemma 3 2B INT4** — extraction + explanation generation. Chosen for
  size/latency on-device, not accuracy ceiling — outputs are reviewed by
  the doctor before anything is sent, so a wrong first draft is expected
  and acceptable; a network call to fix it is not.
- Later: MLX fine-tuning on real doctor corrections, targeting
  Malayalam-English code-mixed speech specifically (the main failure mode
  in early testing). Fine-tuning is offline/local to the dev machine, not
  a runtime app dependency.

## Working Instructions

- Doctor correction step is the product's accuracy safety net — never
  auto-send the PDF without the review screen being shown, even in test
  builds or "quick" flows.
- When in doubt about a UX shortcut vs. the review step, keep the review
  step. It exists because model output is unverified.
- No env vars, config flags, or build variants that silently point the
  app at a remote endpoint "for testing" — use local test fixtures instead.

## Quirks / Known Traps

- Gemma 3 2B INT4 on-device inference is memory- and battery-sensitive;
  don't assume desktop-class latency when reasoning about UX timing.
- Code-mixed (Malayalam-English) input degrades both STT and extraction
  quality today — this is the known gap the fine-tuning phase targets,
  not a bug to "fix" by adding cloud fallback.