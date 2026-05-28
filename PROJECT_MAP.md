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
