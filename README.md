# OCR Expense Tracker

Android Flutter app for personal expense tracking with **on-device OCR** (Google ML Kit), **heuristic regex parsing**, **sqflite** storage, and **CustomPainter** charts.

## Features

- Live camera capture with flash, tap-to-focus, and crop overlay
- Offline text recognition via `google_mlkit_text_recognition`
- Regex heuristics for amount (VND), merchant, and date (`DD/MM/YYYY`)
- Interactive review/edit before save
- Local SQLite persistence + full receipt image and thumbnail
- Categories: Food, Study, Travel, Devices, Entertainment
- Donut (by category) and weekly bar (Mon–Sun) charts drawn with `CustomPainter`

## Prerequisites

- Flutter 3.x / Dart 3
- Android device or emulator (minSdk 26+)
- Camera permission on device

If Flutter is not on your PATH, this machine was set up with:

```text
C:\src\flutter\bin
```

Add that folder to your user PATH, or prefix commands with it.

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
flutter analyze
```

## Project layout

```text
lib/
  core/           theme + VND helpers
  features/
    expenses/     models, sqflite, home UI
    scan/         camera, crop, OCR
    parser/       receipt regex heuristics
    review/       edit-before-save screen
    analytics/    CustomPainter charts
  shell/          bottom navigation
tasks/
  prd-ocr-expense-tracker.md
```

## Demo flow

1. Open **Scan** → allow camera → frame receipt in overlay
2. Toggle flash / tap to focus → **Capture**
3. Review parsed merchant, amount, date → pick category → **Save**
4. See entry on **Home**; open **Analytics** for charts
