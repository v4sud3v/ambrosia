# Platform decision

**Chosen: Flutter (cross-platform, iOS + Android).**

Doctors in the target setting (Kerala clinics) are split across iOS and
Android, and a single UI codebase lets the record → review → PDF flow ship
to both without duplicating screens.

## Trade-off we're accepting

On-device inference (Whisper STT, Gemma 3 2B INT4) has no pure-Dart story.
Those stages will run through **platform channels** into native inference
backends (e.g. whisper.cpp / MediaPipe LLM Inference on Android, WhisperKit /
MLX on iOS). Flutter owns the UI and orchestration; the heavy models stay
native. This is more glue than a single-platform native app, but keeps the
doctor-facing surface unified.

The non-negotiable rule is unaffected: platform channels are in-process, not
network calls. Nothing leaves the device.

## Structure (Flutter)

```
lib/
  main.dart            app entry
  theme/               visual identity
  recorder/            Module 1 — record → local temp file   ← built
  pipeline/            STT → extraction → explanation → PDF   (later modules)
ios/ android/          native hosts (+ future inference channels)
models/                Whisper small + Gemma 3 2B INT4 (bundled/downloaded once)
```
