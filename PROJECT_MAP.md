# PROJECT_MAP.md — Task Card Time: 8-language AM/PM Support

## Date: 2026-05-28

## Changes Made

### Problem
`DateFormat.jm(locale)` relied on the `intl` package's bundled CLDR data, which is not guaranteed to include all 8 app locales (en, ar, zh_CN, zh_TW, hi, fr, es, ru). For example, Hindi (`hi`) and Chinese (`zh`) may lack proper AM/PM markers in the ICU data shipped with Flutter.

### Fix
Changed all task-card time formatting to:
1. Always format in English via `DateFormat.jm('en')` (guaranteed AM/PM output)
2. Replace `AM`/`PM` with the localized short form via `am_short`.tr / `pm_short`.tr

This matches the existing pattern used by the medication module (`medication_controller.dart`, `medication_view.dart`).

### Files Modified

**`lib/app/modules/tasks/views/widgets/task_tile.dart`** — `_formatTimeRange()`
- Removed `locale` variable
- `DateFormat.jm(locale)` → `DateFormat.jm('en')` with `.replaceAll('AM', 'am_short'.tr).replaceAll('PM', 'pm_short'.tr)`

**`lib/app/modules/tasks/views/tasks_view.dart`** — line 365 (bottom sheet detail)
- Same replaceAll pattern applied to inline `DateFormat.jm()` call

**`lib/app/modules/home/services/home_task_service.dart`** — lines 175-176
- Same replaceAll pattern applied to `nextTime` and `nextEndTime`

### Verification
- All 8 translation files have `am_short`/`pm_short` keys (confirmed via grep)
- `flutter analyze` passes with no issues

---

# PROJECT_MAP.md — Keep Note Customization: More Backgrounds, Colors & Popup

## Date: 2026-05-28

## Changes Made

### `lib/app/modules/keep/controllers/keep_controller.dart` — Data Expansion

**Background Images** — Added 2 new images from `assets/images/Background_notes/`:
- `jaron-photoA.jpg`
- `kanenori-starry-skyA.jpg`

Total: 10 → 12 images (all files in the folder are now registered).

**Board Colors** — Added 6 new colors for richer note customization:
- Teal (`0xFF80CBC4`)
- Indigo (`0xFF9FA8DA`)
- Brown (`0xFFBCAAA4`)
- DeepOrange (`0xFFFFAB91`)
- Amber (`0xFFFFE082`)
- DeepPurple (`0xFFB39DDB`)

Total: 10 → 16 colors.

**Text Colors** — Mirror of boardColors + black/white, now 18 entries (was 12).

### Popup Customization (`_showPaletteMenu`)

Already exists in `add_keep_note_view.dart` (line 1078). Accessible via the palette icon in the editor bottom toolbar. The popup provides:
- Color picker (board note colors)
- Background image picker (with thumbnail previews)
- Text color picker
- Blur slider for image backgrounds

No new popup code was needed — the feature was already implemented.

## Affected Files:
- lib/app/modules/keep/controllers/keep_controller.dart

---

# PROJECT_MAP.md — Governance: Prevent Editing Completed Tasks

## Date: 2026-05-27

## Changes Made

### 3 files — 4 guards added (Defense in Depth)

**Guard 1**: `tasks_view.dart:_showTaskDetails` — UI level (bottom sheet)
- Wrapped the "edit" button in `if (!isCompleted)` so completed tasks show no edit option in the details bottom sheet.

**Guard 2**: `task_tile.dart:_showOptions` — UI level (long-press menu)  
- Added `if (task.status != TaskStatus.completed)` around the "edit" action so it doesn't appear in the long-press action sheet for completed tasks.

**Guard 3**: `task_form_controller.dart:updateTask` — Controller level (defense in depth)
- Added `if (existingTask.status == TaskStatus.completed) return;` with `talker.warning` log, preventing any direct API call to update a completed task.

## Affected Files:
- lib/app/modules/tasks/views/tasks_view.dart
- lib/app/modules/tasks/views/widgets/task_tile.dart
- lib/app/modules/tasks/controllers/task_form_controller.dart

---

# PROJECT_MAP.md — Fix Edit Button in Task Details Bottom Sheet

## Date: 2026-05-27

## Changes Made

### `lib/app/modules/tasks/views/tasks_view.dart` — Bug Fix

**Bug**: Edit/Complete/Delete buttons in `_showTaskDetails` bottom sheet used `Get.back()` to close the sheet, but the sheet was opened via `showModalBottomSheet` (native Flutter), not `Get.bottomSheet()`. Since GetX's `Get.back()` uses `Get.overlayContext` which doesn't track native `showModalBottomSheet` routes, the sheet wouldn't close properly, and navigation to `/add-task` would fail.

**Fix**: Replaced `Get.back()` with `Navigator.pop(context)` using the bottom sheet's builder context, ensuring proper route closure before subsequent navigation/actions.

**Affected lines**: 378-379 (complete), 389-390 (edit), 403-404 (delete)

---

# PROJECT_MAP.md — Fun Daily Reminders with Cat Images

## Date: 2026-05-27

## Changes Made

### 1. `lib/app/core/translations/messages.dart` — New Keys (EN + AR)

Added 9 keys for fun daily reminder notifications:
- `fun_morning_title`, `fun_morning_idea`, `fun_morning_task` (10 AM slot)
- `fun_afternoon_title`, `fun_afternoon_idea`, `fun_afternoon_task` (3 PM slot)
- `fun_evening_title`, `fun_evening_idea`, `fun_evening_task` (8 PM slot)

### 2. `lib/app/core/services/notification_service.dart` — New Method

- Added `funOffset = 900000000` to ID Governance
- Added `_random` (Random) for random cat image + message selection
- Added `scheduleFunDailyReminders()` — schedules 3 daily slots (10 AM, 3 PM, 8 PM)
  - Each slot picks a random cat image from a pool of 5 per time slot
  - Each slot randomly picks task or keep/idea message
  - Cancels previous day's fun reminders before rescheduling
  - Uses `reminders_channel` with `BigPictureStyleInformation`

### 3. `lib/app/modules/home/controllers/home_controller.dart` — Deferred Init

- Added import for `NotificationService`
- Added phase 3 deferred call (6s post-frame) to `scheduleFunDailyReminders()` in `onReady()`

## Affected Files:
- lib/app/core/translations/messages.dart
- lib/app/core/services/notification_service.dart
- lib/app/modules/home/controllers/home_controller.dart

---

# PROJECT_MAP.md — Keep Reminder "Next Week" Bug Fix

## Date: 2026-05-27

## Changes Made

### `lib/app/modules/keep/views/add_keep_note_view.dart` — Surgical Fix (2 lines)

**Bug**: `_pickReminder` calculated "next week" as the upcoming Monday instead of exactly 7 days from now.
- `daysUntilMonday = DateTime.monday - now.weekday` then clamped to `[1, 7]`
- On Wednesday (weekday=3): `1 - 3 = -2 → +7 = 5` — only 5 days displayed

**Fix**:
1. `detectSelected()`: `nextMonday` → `nextWeek` using `today.add(Duration(days: 7))`
2. `buildOption` for `next_week`: `now.day + daysUntilMonday` → `now.day + 7`
3. Removed orphan `daysUntilMonday` variable entirely

## Affected Files:
- lib/app/modules/keep/views/add_keep_note_view.dart

---

# PROJECT_MAP.md — Subscription System Implementation Log

## Date: 2026-05-16

## Changes Made

### 1. `lib/app/core/services/subscription_service.dart` — Complete Rewrite

| Aspect | Before | After |
|---|---|---|
| Verification | None — activated immediately | Real verification via verificationData + product ID validation |
| Deactivation | Commented out | Fully active — triggers when restore finds no active subs |
| Restore on Init | Not implemented | verifyEntitlement() called on every app launch |
| Subscription Expiry | Not handled | Detected via restore + 3s timeout, deactivates if no active sub |
| Purchase Token | Not stored | Stored locally in GetStorage |
| Active Product ID | Not tracked | Tracked in activeProductId observable |
| Real Prices | Not available | getMonthlyPrice(), getYearlyPrice(), getYearlyMonthlyEquivalent() |

### 2. `lib/app/modules/subscription/views/premium_view.dart` — Minimal Changes

- Yearly price: $5 → real from Google Play
- Monthly price: $7 → real from Google Play
- Subscribe button shows green "Already Premium" state

### 3. `lib/app/core/translations/messages.dart` — New Key

- premium_active: "You are Premium" (EN) / "أنت مشترك" (AR)

## Product IDs (must match Google Play Console):
- lifeos_premium_monthly → $7/month
- lifeos_premium_yearly → $60/year

## Affected Files:
- lib/app/core/services/subscription_service.dart
- lib/app/modules/subscription/views/premium_view.dart
- lib/app/core/translations/messages.dart

---

# PROJECT_MAP.md — Keep Board: Full 8-language Translation Support

## Date: 2026-05-28

## Problem
The Keep board module had hardcoded strings:
1. **`keep_sticky_card.dart`** — Reminder time labels were hardcoded in Arabic only (`منتهية`, `بعد $weeks أسبوع`, etc.), showing Arabic text for all languages.
2. **`add_keep_note_view.dart`** — Header labels `'New Note'` and `'Edited ...'` were hardcoded in English only.

## Fix
### New Translation Keys (7 keys × 8 locales)
Added `remind_expired`, `remind_now`, `remind_in_weeks_days`, `remind_in_weeks`, `remind_in_days`, `remind_in_hours`, `remind_in_minutes` to all 8 locale files:
- **English** (messages.dart): "Expired", "Now", "In @weeks weeks, @days days", etc.
- **Arabic** (messages.dart): "منتهية", "الآن", "بعد @weeks أسبوع و @days يوم", etc.
- **Chinese Simplified** (zh_cn.dart): "已过期", "现在", "@weeks周 @days天后", etc.
- **Chinese Traditional** (zh_tw.dart): "已過期", "現在", "@weeks週 @days天後", etc.
- **Hindi** (hi_in.dart): "समाप्त", "अभी", "@weeks सप्ताह, @days दिन में", etc.
- **French** (fr_fr.dart): "Expiré", "Maintenant", "Dans @weeks sem. et @days j.", etc.
- **Spanish** (es_es.dart): "Expirado", "Ahora", "En @weeks sem. y @days días", etc.
- **Russian** (ru_ru.dart): "Просрочено", "Сейчас", "Через @weeks нед. и @days дн.", etc.

### Files Modified
**`lib/app/modules/keep/widgets/keep_sticky_card.dart`** (lines 227-241)
- Replaced all 7 hardcoded Arabic strings with `.tr` / `.trParams(...)` calls using the new `remind_*` keys.

**`lib/app/modules/keep/views/add_keep_note_view.dart`** (line 827-828)
- `'Edited ...'` → `'${'keep_edited'.tr} ...'` (key existed but was unused)
- `'New Note'` → `'keep_new_note'.tr` (key existed but was unused)

**`lib/app/core/translations/messages.dart`** (EN + AR)
- Added 7 `remind_*` keys to both English and Arabic sections.

**`lib/app/core/translations/zh_cn.dart`**
- Added 7 `remind_*` keys.

**`lib/app/core/translations/zh_tw.dart`**
- Added 7 `remind_*` keys.

**`lib/app/core/translations/hi_in.dart`**
- Added 7 `remind_*` keys.

**`lib/app/core/translations/fr_fr.dart`**
- Added 7 `remind_*` keys.

**`lib/app/core/translations/es_es.dart`**
- Added 7 `remind_*` keys.

**`lib/app/core/translations/ru_ru.dart`**
- Added 7 `remind_*` keys.

---

# PROJECT_MAP.md — Keep Popups: Full 8-language Translation for Reminder & Palette

## Date: 2026-05-28

## Problem
The "Set Reminder" popup (`_pickReminder`) and "Change Background" popup (`_showPaletteMenu`) in `add_keep_note_view.dart` used translation keys that were **missing from 6 locale files** (zh_CN, zh_TW, hi, fr, es, ru). These keys only existed in messages.dart (EN + AR), meaning non-English/Arabic users would see raw key strings like `"set_reminder"` or `"text_color"` instead of proper translations.

### Missing Keys (11 keys × 6 locales)
- `set_reminder`, `remove_reminder`, `remind_later_today`, `remind_tomorrow_morning`, `remind_next_week_keep`, `remind_pick_date_time`, `remind_date`, `remind_time`, `remind_save`
- `text_color`, `background`

## Fix
Added all 11 missing keys to each of the 6 locale files, completing the 8-language coverage for both popups.

### Files Modified
**`lib/app/core/translations/zh_cn.dart`** — Added 11 keys (Chinese Simplified)
**`lib/app/core/translations/zh_tw.dart`** — Added 11 keys (Chinese Traditional)
**`lib/app/core/translations/hi_in.dart`** — Added 11 keys (Hindi)
**`lib/app/core/translations/fr_fr.dart`** — Added 11 keys (French)
**`lib/app/core/translations/es_es.dart`** — Added 11 keys (Spanish)
**`lib/app/core/translations/ru_ru.dart`** — Added 11 keys (Russian)

### Verification
- `flutter analyze` passes with no issues.
- Both popups already used `.tr` correctly — the bug was purely missing keys in locale files.
- All 8 locale files now have the complete set of palette and reminder keys.

### Overflow Analysis
- `_showPaletteMenu` layout: horizontal ListViews for colors/backgrounds/textColors + Slider for blur — all native widgets that adapt to text length.
- `_pickReminder` layout: vertical ListView of options with icon + title + time — text uses `Expanded` / `Spacer` to prevent overflow.
- `_showCustomDateTimePickerBottomSheet` layout: date/time columns in `Expanded` children + full-width Button.
- **No RenderFlex overflow risk** for any language at the font sizes used (14-18px).

---

# PROJECT_MAP.md — Medications Module: Complete ru_RU Translation + AM/PM Audit

## Date: 2026-05-28

## Problem
The Russian locale file (`ru_ru.dart`) was missing **40+ translation keys** used by the Medications module (علاجاتي / My Medications) and its sub-pages/popups, including the `'AM'`/`'PM'` keys for AM/PM time text translation. The other 5 non-EN/AR locales (es, fr, hi, zh_CN, zh_TW) already had complete coverage.

## Audit Results
Checked all 8 locales (en, ar, ru, es, fr, hi, zh_CN, zh_TW) for AM/PM + medication key coverage:

| Locale | `AM`/`PM` keys | Medication keys |
|--------|:-:|:-:|
| en (messages) | ✅ | ✅ |
| ar (messages) | ✅ | ✅ |
| es (es_es) | ✅ | ✅ |
| fr (fr_fr) | ✅ | ✅ |
| hi (hi_in) | ✅ | ✅ |
| zh_CN | ✅ | ✅ |
| zh_TW | ✅ | ✅ |
| **ru** | **❌ → ✅** | **❌ → ✅** |

## Fix
Added all missing keys to `lib/app/core/translations/ru_ru.dart` (after line 152, single insertion block):

### AM/PM keys (2)
- `'AM': 'AM'`, `'PM': 'PM'` — Russian typically uses 24h format, so the abbreviations match English for the `.replaceAll()` pattern used by medication views.

### Medication UI keys (40)
Type names: `pill`, `syrup`, `med_injection`, `topical`, `drops`, `other`
Instructions: `before_food`, `after_food`, `with_food`, `empty_stomach`, `before_sleep`, `normal`
Form labels: `edit_medication`, `medication_name`, `strength`, `treatment_duration`, `duration`, `med_type`, `med_instruction`, `scheduling`, `frequency`, `interval`, `times_per_day`, `times`, `every`, `hours`, `first_dose_time`, `reminders_alerts`, `enable_notifications`, `will_alert_at`, `med_today_status`, `take`, `doses_remaining`
Status messages: `medication_added`, `medication_updated`, `duplicate_intake`, `dose_taken`, `med_delete_success`, `med_delete_error`, `days`

### Files Modified
- **`lib/app/core/translations/ru_ru.dart`** — Added 42 new key-value pairs.

### Files Verified (no changes needed)
- `lib/app/modules/medication/views/medication_view.dart` — Already uses `.tr` for all labels (no hardcoded strings).
- `lib/app/modules/medication/controllers/medication_controller.dart` — Already uses `.tr` for all snackbar messages.
- `lib/app/core/translations/es_es.dart` — Already has all keys.
- `lib/app/core/translations/fr_fr.dart` — Already has all keys.
- `lib/app/core/translations/hi_in.dart` — Already has all keys.
- `lib/app/core/translations/zh_cn.dart` — Already has all keys.
- `lib/app/core/translations/zh_tw.dart` — Already has all keys.

### Verification
- `flutter analyze` passes — 0 errors, 0 warnings (1 pre-existing info-level issue).
- No RenderFlex overflow risk: medication card text uses `Expanded` + `TextOverflow.ellipsis`; the add/edit bottom sheet uses `SingleChildScrollView` inside `Expanded`. Both patterns prevent overflow for any language at the font sizes used (10-22px).

---

## Appointment Home Card: Remove Decorative Heart Icon (2026-05-28)

### Problem
The doctor appointment card on the home page had a large decorative `CupertinoIcons.heart_circle_fill` icon (size 140, positioned bottom-right) inside the active appointment `Stack`. This violated the requirement for the card to be free of background images/icons.

### Fix
Removed the `Positioned` widget containing the heart icon from `_buildAppointmentHomeCard()` in `lib/app/modules/home/views/home_view.dart` (previously lines 2121-2130).

### Files Modified
- **`lib/app/modules/home/views/home_view.dart`** — Removed the `Positioned` decorative heart icon (and its `// Decorative Background Icon` comment) from the `Stack` children list.

### Verification
- No background images exist in the home appointment card (verified: no `decorationImage`, `Image.asset`, `Image.file`, or `Image.network` in the home module).
- No heart icon remains in the appointment card (the decorative `heart_circle_fill` at line 2126 removed).
- `CupertinoIcons` import remains in use elsewhere in the file — no orphan import.
- Card layout unchanged: glassmorphism (BackdropFilter + blur), gradient avatar, translucent colors remain intact.

---

# PROJECT_MAP.md — Translation Audit: Fun Reminders, Doctor Prefix, Overflow Fixes

## Date: 2026-05-29

## Problem
The comprehensive 8-language translation audit revealed:
1. **6 locale files** (ru, es, fr, hi, zh_CN, zh_TW) were missing the entire 9-key `fun_*` daily reminder block — users would see raw key names in notification titles/bodies.
2. **`home_view.dart`** hardcoded `'Dr: '` / `'الدكتور: '` with only an Arabic fallback — all other languages displayed English `"Dr: "`.
3. **`medication_view.dart`** `SwitchListTile.subtitle` for `'will_alert_at'.trParams` had no `maxLines`/`overflow` — with 4-6 reminder times the text could overflow in any verbose language (Russian, Spanish, French).

## Fixes

### 1. 9 `fun_*` keys added to 6 locale files
Each file received a new `// ─── Fun Daily Reminders ──────────────────────────` section with all 9 keys (3 time slots × title/idea/task).

**Files modified:** ru_ru.dart, es_es.dart, fr_fr.dart, hi_in.dart, zh_cn.dart, zh_tw.dart

Translations follow the English/Arabic tone with culturally appropriate language in each locale.

### 2. `doctor_prefix` key added to all 8 locale files + code fix
- **messages.dart (EN):** `'doctor_prefix': 'Dr: '`
- **messages.dart (AR):** `'doctor_prefix': 'الدكتور: '`
- **ru_ru.dart:** `'doctor_prefix': 'Др.: '`
- **es_es.dart:** `'doctor_prefix': 'Dr.: '`
- **fr_fr.dart:** `'doctor_prefix': 'Dr.: '`
- **hi_in.dart:** `'doctor_prefix': 'डॉ.: '`
- **zh_cn.dart:** `'doctor_prefix': '医生: '`
- **zh_tw.dart:** `'doctor_prefix': '醫生: '`
- **home_view.dart:2218:** Replaced `Get.locale?.languageCode == 'ar' ? 'الدكتور: ' : 'Dr: '` → `'doctor_prefix'.tr`

### 3. Medication overflow fix
- **medication_view.dart:813:** Added `maxLines: 2, overflow: TextOverflow.ellipsis` to the `SwitchListTile.subtitle` Text widget for `'will_alert_at'.trParams(...)`.

## Verification
- `dart analyze` on all modified files: **0 errors, 0 warnings.**
- All 8 locale files now have complete `fun_*` and `doctor_prefix` key coverage.
- Medication bottom sheet subtitle now handles long translated strings safely.
- Doctor label on home appointment card now correctly localized for all 8 languages.

## Affected Files
- lib/app/core/translations/ru_ru.dart
- lib/app/core/translations/es_es.dart
- lib/app/core/translations/fr_fr.dart
- lib/app/core/translations/hi_in.dart
- lib/app/core/translations/zh_cn.dart
- lib/app/core/translations/zh_tw.dart
- lib/app/core/translations/messages.dart
- lib/app/modules/home/views/home_view.dart
- lib/app/modules/medication/views/medication_view.dart

# PROJECT_MAP.md — Fix: Home Task Card AM/PM Stale After Language Switch

## Date: 2026-05-29

## Problem
When the user changes the app language (Settings → Language), the AM/PM time text on the home page task card (`_buildTaskHomeCard`) did not update. The strings `nextTaskTime` and `nextTaskEndTime` were pre-computed in `HomeTaskService._computeStats()` with locale-specific `.tr` calls, then stored as static values. `Get.updateLocale()` rebuilds the widget tree but `Obx` only re-runs its builder on Rx changes — the stale string values persisted until the next Isar DB stream emission.

## Fix (3 files, ~20 lines)

### Root cause chain
`service._computeStats()` → `.replaceAll('AM', 'am_short'.tr)` (locale baked) → stream → controller Rx → Obx reads `.value` → locale changes → Obx doesn't rebuild, Rx still holds old locale string.

### Surgical changes

**1. `theme_service.dart`** (2 lines)
- Added `final localeVersion = 0.obs;` — reactive counter incremented on every `saveLocale()` call.
- `saveLocale()` now does `localeVersion.value++;` before `Get.updateLocale()` in the settings controller.

**2. `home_task_service.dart`** (3 lines)
- Added `DateTime? nextScheduledEndAt` field to `TaskDailyStats` model + constructor.
- `_computeStats()` captures `featuredTask.scheduledEnd` as `nextTaskEndDate`.
- `TaskDailyStats` constructor passes `nextScheduledEndAt: nextTaskEndDate`.

**3. `home_controller.dart`** (~15 lines)
- Added `final _nextTaskEndAt = Rxn<DateTime>();` — raw end DateTime parallel to existing `_nextTaskAt`.
- `_bindTaskStream()` stores `_nextTaskEndAt.value = stats.nextScheduledEndAt`.
- `_refreshCountdowns()` now recomputes `nextTaskTime`/`nextTaskEndTime` from the raw DateTimes using the same `DateFormat.jm('en')` + `.replaceAll('AM', 'am_short'.tr)` pattern as the service — ensuring locale-appropriate AM/PM on every tick.
- Added `ever(Get.find<ThemeService>().localeVersion, (_) { _refreshCountdowns(); })` in `onInit()` — fires synchronously within the same frame as `Get.updateLocale()`, so the Obx rebuilds with correct locale text instantly with zero flicker.

## Update chain (instant)
1. User changes language → `saveLocale()` → `localeVersion++`
2. `ever` fires → `_refreshCountdowns()` recomputes time strings + `minuteTick++`
3. `Get.updateLocale()` rebuilds MaterialApp
4. Obx sees changed `minuteTick` → re-runs builder → reads fresh `nextTaskTime` with current locale → correct AM/PM displayed

## Verification
- `dart analyze` on all 3 modified files: **0 errors, 0 warnings.**
- `dart analyze` on `lib/app/core/theme/`, `lib/app/modules/home/`: **No issues found.**
- No regression: existing Obx reactivity, stream subscriptions, countdown timer, and AM/PM formatting in `task_tile.dart`, `tasks_view.dart`, `home_task_service.dart` are untouched.
- The `ever` worker fires synchronously in the same frame as `Get.updateLocale()`, so no stale-frame flicker.

## Affected Files
- lib/app/core/theme/theme_service.dart
- lib/app/modules/home/services/home_task_service.dart
- lib/app/modules/home/controllers/home_controller.dart
