# Bite: Agent Rules (read before every task)

Bite is an offline-first Flutter app: a calorie, macro and gym tracker built around
Pakistani food (roti, pyali, karchi, glass; oil level in tadka). Full spec is in
`BITE_SPEC.md`. Follow it. If the spec and a request conflict, ask before coding.

## Hard constraints
- Flutter (stable), Dart null-safety, Android first. Material 3.
- 100% offline. No network calls, no analytics, no ads, no paid AI. Bundle all fonts and assets.
- Release APK/AAB under 20 MB. Check with `flutter build apk --release --split-per-abi`.
- No sign-up. Data lives on device (SQLite).

## Stack (add with `flutter pub add`, never hand-pin old versions)
Chosen to be simple enough that the student can explain every line in a viva.
- State: `provider` (ChangeNotifier). No code generation anywhere.
- DB: `sqflite` + `path` with plain SQL in repository classes (no ORM, no build_runner)
- Routing: `go_router`
- Charts: `fl_chart`
- Misc: `intl`, `HapticFeedback` (built in), `shared_preferences`
- Tests: `flutter_test`

## Architecture (feature-first)
```
lib/
  core/        theme/, widgets/ (shared), utils/, constants/
  data/        db/ (database helper, table SQL), seed/ (foods.json loader), repositories/
  domain/      pure Dart: models, nutrition_calc.dart, targets_calc.dart, units.dart
  features/    onboarding/, today/, log_food/, gym/, progress/, settings/
  app.dart, main.dart
assets/        data/foods.json, fonts/
test/          domain tests first, then repository and widget tests
```

## Human-written-style code (course rule: NO vibe coding)
The student must understand and be able to explain all code. So:
- Simple, readable, beginner-friendly Dart. Clear names (`todayCalories`, not `tc`).
- No clever one-liners, no heavy generics, no advanced patterns when a plain one works.
- Short comments that explain WHY, written in plain English like a student would.
- Small files and small functions (one job each). Max about 150 lines per widget file.
- After each task, add a "How it works" paragraph (5 lines max) so the student can learn it.
- Never generate large unrelated changes. Keep each diff small enough to read fully.
- When asked "explain", explain line by line without jargon.

## Code rules
- All nutrition, target and unit math lives in `domain/` as pure functions with unit tests.
  No math inside widgets.
- Widgets are small and `const` wherever possible. Use `ListView.builder` for any list.
- Every screen needs: loading state, empty state, and error state. No blank screens.
- Never hardcode colors, spacing or text styles. Use theme tokens from `core/theme/`.
- **Maximum 4 colours in the whole UI** (see palette in `BITE_SPEC.md`). Tints (lighter or
  transparent versions) of those 4 are allowed. Never introduce a 5th hue.
- Keep about 50% of every screen as empty space. Prefer taps, chips, steppers and pickers over typing.
- Debounce food search (150 ms). Query SQLite with indexes; do not filter big lists in widgets.
- Store energy as integer kcal x10 or double with one rounding rule, used everywhere.
  Round only at display time.
- No `print`. No unused imports. No TODOs left in finished tasks.

## UX rules
- Tap targets at least 48x48 dp. Respect system text scale up to 1.3x without overflow.
- Every tap that changes data gives feedback: haptic + animation or snackbar with Undo.
- Light theme only for the MVP (dark mode is cut to respect the 4-colour rule). Contrast at least WCAG AA.
- Images: use none, or only assets the student made. No copied or copyrighted images.
- Animations 150 to 350 ms, easing curves from the theme. Respect reduced-motion setting.

## Definition of done (for every task)
1. `flutter analyze` returns no issues.
2. `flutter test` passes, with new tests for new domain logic.
3. App runs on a 360x640 emulator and a large phone with no overflow stripes.
4. 1.3x text scale checked, and only the 4 palette colours are used.
5. Short summary of what changed and what to test by hand.

## Working style
- Do one phase at a time from `BITE_SPEC.md` section 8. Do not start the next phase.
- Prefer the simplest thing that is correct. Explain any new dependency before adding it.
- If something is a guess (nutrition values, formulas), mark it clearly in code comments.
