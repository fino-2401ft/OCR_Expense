# PRD: OCR Expense Tracker (Flutter & Dart)

## 1. Introduction / Overview

OCR Expense Tracker is a personal finance Android app that lets students and club treasurers capture supermarket receipts, extract key fields offline with on-device OCR, review/edit them, and store expenses locally with category-based analytics.

The app solves slow, error-prone manual spreadsheet entry by combining Google ML Kit Text Recognition, heuristic regex parsing (amount, merchant, date), sqflite persistence, and CustomPainter charts (no third-party chart libraries).

**Confirmed decisions**
- Database: `sqflite`
- Platform: Android only
- UI language: English
- Currency: VND (`150.000 đ`, `150,000 VND`)

## 2. Goals

- Capture and crop receipt photos from a live camera preview
- Extract receipt text offline with `google_mlkit_text_recognition` (target under 100ms on-device; no cloud OCR fees)
- Parse total amount, merchant name, and transaction date via heuristic regex
- Allow manual review/edit before saving
- Persist expenses and receipt thumbnails locally with category classification
- Visualize spending with CustomPainter pie/donut (by category) and bar (weekly) charts
- Meet course prerequisites: Flutter 3.x, Dart 3, Google ML Kit, sqflite, CustomPainter

## 3. User Stories

### US-001: Create Flutter Android project scaffold
**Description:** As a developer, I need a runnable Flutter 3.x / Dart 3 Android app with folder structure and dependencies so feature work can start.

**Acceptance Criteria:**
- [ ] Flutter project created targeting Android
- [ ] Dependencies declared: `camera`, `google_mlkit_text_recognition`, `sqflite`, `path_provider`, `path`, `image` (or equivalent crop helper), `intl`
- [ ] App launches on Android emulator/device with a bottom navigation shell (Home / Scan / Analytics)
- [ ] `flutter analyze` passes with no errors

### US-002: Live camera capture with flash, tap-to-focus, and crop overlay
**Description:** As a user, I want to photograph a receipt with flash control, tap-to-focus, and a crop frame so the OCR region is clear.

**Acceptance Criteria:**
- [ ] Live camera preview on Scan screen
- [ ] Flash toggle (on / off / auto if supported)
- [ ] Tap-to-focus on preview
- [ ] Semi-transparent crop overlay frame guides framing
- [ ] Capture produces an image cropped (or marked) to the overlay region
- [ ] Denied camera permission shows an English error message with open-settings guidance

### US-003: On-device OCR text extraction
**Description:** As a user, I want receipt text recognized offline so I do not need internet or pay for cloud OCR.

**Acceptance Criteria:**
- [ ] Uses `google_mlkit_text_recognition` on the captured/cropped image
- [ ] Returns full recognized text string to the parser pipeline
- [ ] Works offline after ML Kit model is available on device
- [ ] Loading indicator shown during recognition
- [ ] Failure shows English error; user can retry or enter fields manually

### US-004: Heuristic regex receipt parser
**Description:** As a user, I want the app to guess total, merchant, and date from OCR text so I rarely type them from scratch.

**Acceptance Criteria:**
- [ ] Amount patterns cover at least: `150,000 VND`, `150.000 đ`, `150000`, `Total: 150.000`, case-insensitive labels (`TOTAL`, `SUM`, `AMOUNT`, `TỔNG`, `THANH TOÁN`)
- [ ] Date patterns cover `DD/MM/YYYY` and common variants (`DD-MM-YYYY`, `DD.MM.YYYY`)
- [ ] Merchant heuristic: prefer top lines / lines near store-like keywords; fallback to first non-empty line
- [ ] Parser returns nullable fields with confidence notes or null when unmatched
- [ ] Unit tests cover representative Vietnamese supermarket receipt samples

### US-005: Interactive review / edit before save
**Description:** As a user, I want to correct OCR mistakes before saving so my ledger stays accurate.

**Acceptance Criteria:**
- [ ] Review screen shows: merchant, amount (VND), date, category, notes (optional), receipt thumbnail
- [ ] All fields are editable
- [ ] Category picker with: Food, Study, Travel, Devices, Entertainment
- [ ] Validation: amount > 0, date parseable, merchant non-empty before save
- [ ] Cancel discards without writing to DB
- [ ] Save navigates to Home / transaction list

### US-006: Local persistence with sqflite + thumbnail storage
**Description:** As a user, I want expenses and receipt thumbnails stored on device so data survives app restarts.

**Acceptance Criteria:**
- [ ] sqflite schema includes: `id`, `merchant`, `amount` (integer VND), `date` (ISO or epoch), `category`, `notes`, `thumbnail_path`, `created_at`, `ocr_raw_text` (optional)
- [ ] Thumbnail saved under app documents/support directory
- [ ] CRUD: create, list, read detail, update, delete
- [ ] Home screen lists expenses newest-first with category label and formatted VND amount
- [ ] Deleting a transaction also deletes its thumbnail file if present

### US-007: Home / transaction lifecycle UI
**Description:** As a user, I want to browse, open, edit, and delete past expenses.

**Acceptance Criteria:**
- [ ] List shows merchant, date, category, amount
- [ ] Tap opens detail/edit
- [ ] Swipe or explicit delete with confirmation dialog
- [ ] Empty state copy in English when no expenses exist
- [ ] Total spent for current month shown on Home header

### US-008: CustomPainter category donut chart
**Description:** As a user, I want a pie/donut chart of spending by category so I can see where money goes.

**Acceptance Criteria:**
- [ ] Drawn with `CustomPainter` only (no fl_chart / charts_flutter / syncfusion)
- [ ] Segments map to Food, Study, Travel, Devices, Entertainment
- [ ] Legend with category name, color, and amount or percentage
- [ ] Handles zero-data empty state
- [ ] Updates when underlying expense data changes

### US-009: CustomPainter weekly bar chart
**Description:** As a user, I want a weekly bar chart of spending so I can spot recent spending trends.

**Acceptance Criteria:**
- [ ] Drawn with `CustomPainter` only
- [ ] Seven bars for the current week (Mon–Sun or Sun–Sat; document choice in code)
- [ ] Y-axis scale adapts to max daily total
- [ ] Empty/zero days render as zero-height or minimal baseline
- [ ] Tap/highlight optional but at least labels are readable

### US-010: Analytics screen composition
**Description:** As a user, I want one Analytics tab combining both charts and a short summary.

**Acceptance Criteria:**
- [ ] Analytics screen shows donut + weekly bars
- [ ] Summary line: total this week and total this month (formatted VND)
- [ ] English UI labels throughout

## 4. Functional Requirements

- **FR-1:** The app must run as an Android Flutter application (Flutter 3.x, Dart 3).
- **FR-2:** Scan flow must provide live preview, flash toggle, tap-to-focus, and a crop overlay before capture.
- **FR-3:** After capture, the app must run on-device text recognition via Google ML Kit Text Recognition.
- **FR-4:** A custom heuristic regex parser must extract candidate `amount` (VND), `merchant`, and `date` (`DD/MM/YYYY` family).
- **FR-5:** Review screen must prefill parsed fields and allow full manual edit, including category selection.
- **FR-6:** Categories must be exactly: Food, Study, Travel, Devices, Entertainment.
- **FR-7:** Saved expenses must persist in sqflite; receipt thumbnails must persist in app local storage.
- **FR-8:** Users must be able to list, view, edit, and delete expenses.
- **FR-9:** Analytics must render category donut and weekly bar charts using CustomPainter only.
- **FR-10:** All user-facing strings must be English; amounts must display in VND formatting (thousands separators + `đ` or `VND`).
- **FR-11:** Camera and storage-related permission failures must surface clear English errors without crashing.

## 5. Non-Goals (Out of Scope)

- iOS / web / desktop support
- Cloud OCR, Firebase, or any paid recognition API
- Multi-currency wallets or FX conversion
- User accounts, sync, or multi-device backup
- Budgets, recurring expenses, or bill reminders
- Third-party chart libraries
- Bank statement import / PDF parsing
- Vietnamese UI localization (may add later; not in this release)
- Isar database

## 6. Design Considerations

- **Navigation:** Bottom nav — Home (list), Scan (camera), Analytics (charts)
- **Visual tone:** Clean finance utility; clear hierarchy; high-contrast amounts; avoid decorative clutter
- **VND display:** Prefer `150.000 đ` in UI lists; parser must still accept `150,000 VND`
- **Review screen:** Thumbnail on top or side; form fields below; primary Save CTA
- **Charts:** Distinct category colors; accessible contrast; legend always visible
- **Empty states:** Short English guidance (“No expenses yet. Scan a receipt to start.”)

## 7. Technical Considerations

- **Stack:** Flutter 3.x, Dart 3, Android
- **OCR:** `google_mlkit_text_recognition` (Latin script sufficient for VND receipts with Latin/Vietnamese text)
- **DB:** `sqflite` + `path` / `path_provider`
- **Camera:** `camera` plugin; handle lifecycle (pause/resume) to avoid preview freezes
- **Images:** Persist compressed JPEG thumbnail (e.g. max edge ~800px) to limit storage
- **Parsing pipeline:** `raw OCR text → ReceiptParser → ParsedReceipt → Review UI → ExpenseRepository`
- **Charts:** `CustomPaint` + painters under `lib/features/analytics/painters/`
- **Architecture suggestion:** feature-first folders (`scan`, `review`, `expenses`, `analytics`, `core`)
- **Testing:** unit tests for `ReceiptParser`; widget tests optional for list empty state
- **Performance note:** OCR “under 100ms” is a target on mid-range devices for cropped receipts; measure on real hardware and document if slower on low-end emulators

### Suggested data model

```dart
class Expense {
  final int? id;
  final String merchant;
  final int amountVnd; // store as integer đồng
  final DateTime date;
  final ExpenseCategory category;
  final String? notes;
  final String? thumbnailPath;
  final String? ocrRawText;
  final DateTime createdAt;
}

enum ExpenseCategory { food, study, travel, devices, entertainment }
```

### Amount regex examples (illustrative)

- `(?i)(total|sum|amount|tổng|thanh\\s*toán)[^\\d]{0,20}([\\d.,]+)\\s*(vnd|đ|d)?`
- Standalone money-like tokens near the bottom of the receipt scored higher

## 8. Success Metrics

- End-to-end path works offline: capture → OCR → parse → edit → save → list → charts
- Parser correctly fills amount on ≥ majority of sample supermarket receipts used in demos
- Manual edit always available when OCR/parse fails
- Charts render without third-party chart packages
- `flutter analyze` clean; parser unit tests pass
- Suitable for course demo: flash, focus, crop overlay, OCR, regex, sqflite, CustomPainter all demonstrable

## 9. Resolved Decisions / Open Questions

**Resolved**
- Crop: on capture using overlay frame (no separate post-crop editor)
- Weekly bars: Monday–Sunday
- Images: keep both full-resolution receipt and thumbnail
- Implementation: approved to proceed after PRD

**Still open**
- Minimum Android SDK / target SDK required by the course lab machines? (default to Flutter/Android plugin minimums)

## 10. Implementation Order (after PRD approval)

1. Project scaffold + navigation shell (US-001)
2. sqflite repository + Home list CRUD UI (US-006, US-007)
3. Camera capture UX (US-002)
4. ML Kit OCR + Review screen wiring (US-003, US-005)
5. ReceiptParser + unit tests (US-004)
6. CustomPainter charts + Analytics (US-008, US-009, US-010)
7. Polish: permissions, empty states, VND formatting, demo sample data toggle

---

**Status:** Draft ready for approval  
**Next step:** Confirm open questions (or accept defaults), then begin implementation starting at US-001.
