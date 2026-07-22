# Ambrosia — Modules

## 1. Recorder
- Tap to start/stop mic recording
- Save audio locally (temp file)
- Show recording state + duration

## 2. STT (Whisper on-device)
- Input: audio file
- Output: raw transcript text
- Runs fully on-device, no network

## 3. Extractor (Gemma 3 2B)
- Input: transcript
- Output: structured JSON — diagnosis, medicines, follow-up
- On-device inference only

## 4. Explainer (Gemma 3 2B)
- Input: structured JSON
- Output: plain-language text — what it is, recovery, avoid, danger signs

## 5. Review Card (UI)
- Show extracted JSON + explanation, editable
- Doctor edits/confirms (~5 sec)
- Blocks next step until confirmed

## 6. PDF Generator
- Input: confirmed JSON + explanation
- Output: visual PDF file

## 7. Share
- Send PDF via WhatsApp (OS share sheet)
- No custom API call

## 8. Cleanup
- Delete audio, transcript, JSON immediately after share
- Runs every time, no toggle to disable

## 9. Fine-tune (offline, separate from app)
- Input: doctor corrections logged during review
- MLX script → new Gemma checkpoint
- Output copied into /models for next build