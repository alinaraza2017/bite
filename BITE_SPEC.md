# Bite: Spec, Design System and Cursor Prompts

> Pakistani macro and gym tracker. Offline. No ads. No sign-up. No AI.
> Tagline idea: **"Log it the way you eat it."**

---

## 1. Scope: what is in and what is cut

"Perfect" for a lab mid means: **fewer features, zero bugs, beautiful, smooth, easy to demo.**
Build the MVP below fully before touching anything in the stretch list.

### MVP (must ship)
1. Onboarding (3 steps) producing calorie and macro targets
2. Pakistani food database (about 60 to 100 dishes) with household units
3. Food logging with live macros and the Light / Medium / Heavy oil chips
4. Today dashboard: calorie ring, macro bars, meals, net calories (eaten minus burned)
5. Gym log: workouts, sets, previous values shown
6. Progress: 7-day trend, weight log
7. Settings and custom foods (limit 10 on free tier)

### Stretch (only after MVP is solid)
Recipe builder (premium), PR tracking, adaptive target, full history, favourites,
water tracker, home-screen widget, Urdu labels. **Cut for good: dark mode** (4-colour rule).

### Module map (course rule: 3 to 4 modules, 2 to 3 core)
| Module | Type | Covers |
|---|---|---|
| 1. Food Log | Core | Food database, units, oil chips, meals, Today dashboard |
| 2. Gym Log | Core | Workouts, sets, previous values, burned calories |
| 3. Targets & Progress | Core | Onboarding, BMR/TDEE targets, charts, weight log |
| 4. Account & Premium | Supporting | Settings, paywall, export |

### Premium: fake it safely
No real billing for the lab. Add a local `isPremium` flag and a polished paywall screen.
Premium-gated items show a lock chip that opens the paywall. A hidden "Unlock for demo"
toggle in Settings lets you show both states. Say this clearly in your report.

---

## 2. Design system (you are the UI/UX lead, so own this)

**Personality:** warm, appetising, confident. Not clinical like most fitness apps.

**Course rule: maximum 4 colours in the UI.** Your whole palette is exactly these four:

| Role | Colour | Used for |
|---|---|---|
| 1. Primary | `#C2410C` masala orange (dark enough for readable cream text) | buttons, calorie ring, active tab, calories |
| 2. Accent | `#2F7D4F` deep green | protein, success, "goal reached" |
| 3. Surface | `#FFF8F0` warm cream | all backgrounds and cards |
| 4. Ink | `#2B2118` dark brown-black | all text, icons, fat bars |

How to still tell macros apart with so few colours: **Protein = green, Calories/Carbs = orange
(carbs use a lighter 40% tint), Fat = ink (60% tint)**, and always add a text label or icon.
Never rely on colour alone. Warnings (over target) use the primary colour with a different icon,
not red. Ask sir once if tints of the same 4 colours are fine, and mention the 4-colour palette in
your report. Build the `ColorScheme` by hand from these four (no `fromSeed`, it generates extra hues).

- **Type:** one family, bundled in `assets/fonts/` (e.g. Plus Jakarta Sans or Poppins). Never use
  `google_fonts` at runtime: it needs internet. Scale: Display 32, Title 22, Body 16, Label 13.
- **Spacing:** 4-pt grid (4, 8, 12, 16, 24, 32). **Radius:** 16 cards, 28 sheets, full for chips.
- **Elevation:** flat cards with a 1 px outline (ink at 12% opacity), no heavy shadows.
- **Icons:** Material Icons (built in). Food category emoji as visual anchors
  (🫓 roti, 🍛 curry, 🍚 rice, 🥛 drinks) so you ship zero image assets and have **no copyright risk**.
  Emoji have their own colours, so use them sparingly and only inside category chips and list tiles.
- **Whitespace:** about 50% of every screen stays empty (course rule). One main action per screen,
  generous padding (16 to 24), no more than 3 cards visible at once.
- **Type less, select more:** onboarding is all pickers and cards; logging is search + chips + stepper;
  gym uses steppers. The only real typing is search, custom food names and exercise names.

### Signature interactions (this is where the "amazing" comes from)
1. **Calorie ring** on Today animates from 0 to value on open (600 ms, easeOutCubic) and
   smoothly re-animates when you log. Past 100% of target the ring switches to a bold outline and an
   info icon with "Over by 120 kcal" (no extra colour).
2. **Log sheet:** tap a food, a draggable bottom sheet rises. Quantity stepper (+ / − in 0.5 steps),
   unit chips (1 roti, 1 pyali, 1 karchi, 1 glass), oil chips (Light, Medium, Heavy). The macro numbers
   count up/down live as you change anything (`TweenAnimationBuilder`). Big "Add to Lunch" button
   shows the final kcal inside it.
3. **Search that understands:** typing "chapati" shows roti and tandoori roti. Results highlight the
   matching text. Recents appear before you type.
4. **Swipe to delete** a log entry with an Undo snackbar. Long-press to edit quantity.
5. **Haptics:** light tick on stepper, medium on add, success pattern on hitting protein target.
6. **Milestone moment:** when daily protein target is hit, the protein bar pulses once and a small
   confetti-free check animation plays. Subtle beats gimmicky.
7. **Gym set rows** pre-fill with last session's weight and reps (shown greyed as "Last: 60 kg x 8").
   One tap to confirm same as last time.
8. **Shared-element transitions** (Hero) from food list tile to log sheet header emoji.
9. **Skeleton shimmer** only if a screen takes longer than 150 ms. Otherwise show content directly.
10. **Empty states** with a friendly line and one clear action ("Nothing logged yet. Add your first roti 🫓").

### Navigation
Bottom `NavigationBar` with 4 tabs: **Today, Gym, Progress, Settings**. Center-docked
extended FAB on Today: **"+ Log food"**. Preserve tab state with `StatefulShellRoute`.

---

## 3. Screens (course rule: 10 to 15 screens, this is 13)
Count: Onboarding x3 (1 to 3), Today (4), Log food (5), Food detail sheet (6), Add custom food (7),
Gym (8), Exercise picker (9), Progress (10), Add weight (11), Settings (12), Paywall (13).

1. **Onboarding** (PageView, 3 steps, progress dots, no keyboard where possible)
   - Step 1: sex, age (wheel picker), height, weight
   - Step 2: activity level (4 cards with one-line descriptions) and goal (Lose / Maintain / Gain)
   - Step 3: your targets shown with animated numbers, "Edit" link, "Start tracking" button
2. **Today:** date strip (swipe to change day), calorie ring with eaten / burned / remaining,
   three macro bars, meal sections (Breakfast, Lunch, Dinner, Snacks) each with "+" button,
   gym summary card (net calories).
3. **Log food:** search bar, category filter chips, recents, results list, custom food entry.
4. **Food detail sheet:** described above.
5. **Gym:** today's workout, add exercise (search + muscle group), set rows, rest timer chip,
   finish workout -> estimated calories burned.
6. **Progress:** 7 / 30 day toggle, calorie bar chart vs target line, weight line chart,
   weekly averages, streak counter.
7. **Settings:** edit profile and targets, units (kg/lb),
   export data as JSON to share (offline, via share sheet), reset data, about, demo premium toggle.
8. **Paywall:** benefits list, plan cards ($2.49 / month, $17.99 / year with "7-day trial" badge), not wired to billing.

---

## 4. Data model (SQLite via sqflite, plain SQL)

```
Foods        id, name, aliases (comma text), category, emoji, kcal100, protein100, carbs100, fat100,
             isCustom, isFavorite, createdAt
FoodUnits    id, foodId -> Foods, label ("roti", "pyali"), grams, isDefault
LogEntries   id, date (yyyy-MM-dd), meal, foodId, unitLabel, quantity, oilLevel (0 none,1,2,3),
             grams, kcal, protein, carbs, fat   <- SNAPSHOT values, so editing a food never rewrites history
Exercises    id, name, muscleGroup, isCustom
Workouts     id, date, name, durationMin, burnedKcal
SetEntries   id, workoutId, exerciseId, setNo, weightKg, reps
WeightLogs   date (unique), kg
```
Indexes: `LogEntries(date)`, `Foods(name)`, `SetEntries(exerciseId)`, `Foods(category)`.
Profile and settings in `shared_preferences` (small, simple).

### Seed data
`assets/data/foods.json` loaded once on first launch inside a transaction.
Each food has a list of units with gram weights.
**The nutrition numbers are your biggest accuracy risk.** Have Cursor generate a first draft, mark every
value `"verified": false`, then **you verify** against a real source (for example a national food
composition table or a reliable nutrition database) and write the source in your report.
Cover at minimum: roti, tandoori roti, paratha, naan, daal chawal, plain rice, biryani, pulao, nihari,
haleem, karahi chicken, chicken qorma, aloo gosht, chana masala, daal mash, daal masoor, sabzi, raita,
lassi, chai with milk and sugar, egg (boiled, fried, omelette), samosa, pakora, chapli kebab, seekh kebab, halwa puri.

---

## 5. Logic (all in `domain/`, all unit-tested)

**BMR (Mifflin-St Jeor):** `10*kg + 6.25*cm - 5*age + 5` (male) or `- 161` (female).
**TDEE:** BMR x activity (1.2, 1.375, 1.55, 1.725).
**Goal:** Lose = TDEE - 500, Maintain = TDEE, Gain = TDEE + 300. Clamp to a safe floor
(for example never below BMR, and show a gentle note if clamped).
**Macros:** protein 1.8 g/kg (editable), fat 25% of kcal, carbs = remaining kcal / 4.
Energy: protein 4, carbs 4, fat 9 kcal per gram.
**Food entry:** `grams = unitGrams * quantity`; macros = per100 * grams / 100.
**Oil chips:** added oil grams: Light 5 g, Medium 10 g, Heavy 20 g (**assumption, make these constants
and editable**). Oil adds `grams * 9` kcal and `grams` of fat. "None" = 0.
**Net calories:** `eaten - burned`. Remaining = target - net.
**Burned (gym):** `MET * weightKg * hours`, with MET about 5 for weight training (**assumption, state it**).
Tests: boundary cases (0 quantity, tiny and huge values, rounding that always sums correctly).

---

## 6. Performance and size checklist
- `const` constructors, `ListView.builder`, `RepaintBoundary` around the ring and charts.
- Use `Selector` / `context.select` from `provider` so only the needed widget rebuilds.
- After every write, the repository tells its `ChangeNotifier` to reload Today, so the UI updates instantly.
- Debounce search 150 ms; limit results to 50; SQL `LIKE` over name and aliases with indexes.
- Compress nothing you do not need: no images, only vector icons and emoji, one font family
  with only the weights you use (400, 600, 700).
- Release build: `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols`.
- Cold start target under 1.5 s on a mid phone. Check with `flutter run --profile` and DevTools.
- Remove the INTERNET permission from the release manifest if nothing needs it (proves "100% offline").

---

## 7. How to use Cursor well here (and not vibe-code)
Sir's rule: AI may build it, but **no vibe coding; the code must be humanized**. In practice that means
you stay in control and can explain everything:
- **Read every diff** before accepting. If you cannot explain a block, ask Cursor
  "explain this line by line like I'm a beginner", or ask it to simplify.
- **Commit after every phase** with your own message. Git history shows real, incremental work.
- **Write some code yourself**: the colour theme, one screen's layout, and one calculator test. Even 20%
  makes the project clearly yours.
- Keep the "How it works" notes Cursor writes. They become your viva answers and report text.
- Rename things to match how you think. Delete anything you do not need.
- Prepare to answer: "Why sqflite?", "Where is the BMR formula?", "What happens when I tap Add?"
Setup steps:
1. Put `AGENTS.md` in the project root. Put this file beside it. Run `flutter create bite` first.
2. Use **Plan mode** for each phase: read the plan, fix it, then let the agent build.
3. Paste **one phase prompt at a time**. Do not ask for the whole app at once: quality drops.
4. After each phase: run the app, tap everything, run `flutter analyze` and `flutter test`,
   then **commit to git**. A clean commit per phase means you can always roll back.
5. If the agent breaks something: do not argue in a long chat. Revert, open a fresh chat, and paste
   the phase prompt plus the exact error.
6. Add `@AGENTS.md` and `@BITE_SPEC.md` to the context of each new chat.

---

## 8. Phase prompts
**Use `CURSOR_PROMPTS.md` instead.** It has the updated prompts (sqflite, provider, 4 colours, no vibe coding) and extra phases for billing and store listing. The older prompts below are kept only for reference.

### Phase 0: Project setup
```
Read @AGENTS.md and @BITE_SPEC.md. Set up the Flutter project "bite": add the listed dependencies
with `flutter pub add`, create the folder structure from AGENTS.md, bundle a font in assets/fonts
and register it, implement a light theme using ONLY the 4-colour palette from section 2 (build the
ColorScheme by hand, no dark mode), set up go_router with a 4-tab StatefulShellRoute bottom
NavigationBar (Today, Gym, Progress, Settings) with placeholder screens. Make sure analyze is clean.
Do not build any features yet.
```

### Phase 1: Domain logic first (no UI)
```
Implement section 5 as pure Dart in lib/domain/: models, targets_calc.dart (BMR, TDEE, goal, macros),
nutrition_calc.dart (food entry macros incl. oil level), burn_calc.dart. Add thorough unit tests in test/.
Constants for oil grams and MET must be named, documented, and easy to change. Run the tests.
```

### Phase 2: Database and seed
```
Implement section 4 with sqflite and plain SQL: a DatabaseHelper that creates the tables and indexes,
and a FoodRepository and LogRepository. Keep the SQL readable and commented.
Create assets/data/foods.json with roughly 60 Pakistani foods from the section 4 list, each with
household units and gram weights, aliases (e.g. roti: chapati, phulka), and "verified": false.
Load the seed once inside a transaction on first launch. Write repository tests using an in-memory database.
Implement search over name and aliases, ranked: exact, prefix, contains.
```

### Phase 3: Onboarding and profile
```
Build the 3-step onboarding from section 3 using the domain calculators. Persist the profile in
shared_preferences. Animated target numbers on step 3. Redirect to Today when onboarding is done
and to onboarding when it is not (go_router redirect). Wheel pickers instead of keyboards where possible.
```

### Phase 4: Today dashboard
```
Build the Today screen: date strip, animated calorie ring (CustomPainter, wrapped in RepaintBoundary),
macro bars using the 4-colour palette (green protein, orange carbs tint, ink fat tint) with text labels, meal sections with entries, net calories card. Drive it with a ChangeNotifier
(provider) that reloads after every write so it updates live. Add swipe-to-delete with Undo and empty states.
```

### Phase 5: Log food + signature sheet
```
Build the Log food screen (search with 150 ms debounce, recents, category chips, highlight matches)
and the draggable food detail bottom sheet exactly as in section 2 point 2: quantity stepper, unit chips,
oil chips, live count-up macros via TweenAnimationBuilder, haptics, "Add to <meal>" button showing kcal.
Hero emoji transition. Writes a snapshot LogEntry. Add custom food creation with the free-tier limit of 10.
```

### Phase 6: Gym
```
Build the Gym tab: start workout, exercise picker (search + muscle group chips), set rows prefilled from
the last session for that exercise (show "Last: 60 kg x 8"), one-tap "same as last", rest timer chip,
finish workout computing burned kcal with burn_calc. Burned kcal feeds net calories on Today.
```

### Phase 7: Progress
```
Build Progress with fl_chart: 7/30 day toggle, calorie bars with a target line, weight line chart with
add-weight dialog, weekly averages, streak counter. Animate charts on first show. Handle no-data states.
```

### Phase 8: Settings, paywall, polish
```
Build Settings (profile edit recalculating targets, kg/lb, JSON export via share sheet, reset with
confirm dialog, demo premium toggle) and the paywall screen with gating chips. Then a polish pass:
consistent spacing, transitions, empty/error states everywhere, accessibility labels, 1.3x text scale,
a colour audit (only the 4 palette colours and their tints), whitespace audit (about 50% empty), remove unused code.
```

### Phase 9: Performance, size, release
```
Audit performance (rebuilds, jank in DevTools profile mode), reduce APK size, remove the INTERNET
permission from the release manifest, set app name and icon, run a release build with --split-per-abi,
report the APK size, and list any remaining known issues honestly.
```

---

## 9. Final QA (do this yourself, not the AI)
- [ ] Fresh install -> onboarding -> first log works with no crash
- [ ] Airplane mode: everything still works
- [ ] Log 3 meals, delete one, Undo it, totals correct each time
- [ ] "chapati" finds roti; "nehari" or "nihari" both find nihari (add alias)
- [ ] Oil chip changes kcal by the expected amount (check with a calculator)
- [ ] Change day, change profile, targets update, old log entries unchanged
- [ ] 1.3x text, 360x640 screen: no overflow
- [ ] Count colours on every screen: only the 4 palette colours and their tints
- [ ] Count screens (must be 10 to 15) and check each is about half empty
- [ ] Explain any file Cursor wrote, out loud, without looking (viva test)
- [ ] Kill and reopen app: data persists
- [ ] Release APK size under 20 MB
- [ ] 20 nutrition values spot-checked against a source, source cited in your report

## 10. Demo script (3 minutes, for the evaluator)
1. Open (ring animates). "Global apps think a pyali is a cup. Bite doesn't."
2. Search "chapati", find roti, set 2 roti, add a pyali of daal, tap **Heavy** oil: watch kcal jump.
3. Log it. Ring and macros animate. Swipe-delete, Undo.
4. Gym: start workout, show prefilled last values, finish, show net calories change.
5. Progress charts, then flip airplane mode on: "100% offline, no sign-up, no ads."
6. Flash the paywall: "Premium is how the business works."

---

## 11. Publishing and revenue plan (this is what your grade depends on)

Your notes say: **published app = 100 marks, plus 4 GPA if it generates revenue.** Publishing has a
built-in waiting time, so start it NOW, in parallel with coding.

### Step 0: Do this today
1. Create a Google Play Console developer account (one-time US$25 fee, identity verification needed).
2. **Check the testing rule:** a *personal* account created after 13 Nov 2023 must run a **closed test
   with at least 12 testers opted in for 14 continuous days** before it can apply for production access.
   (Organisation accounts are exempt but need business verification, which can take longer.)
   Source: Google Play Console Help, "Testing requirements for new personal developer accounts". Confirm the
   current numbers in your own Console, because Google has changed them before (it started at 20 testers).
3. Recruit 15 to 20 testers (classmates, your UI/UX team) so you still have 12 if some drop out.
   Testers must stay opted in for all 14 days; anyone who leaves can break the count.
4. Ask sir: **what counts as "published" for the mid?** Closed testing, or live on production? And
   what is the exact deadline? If the 14 days do not fit, he needs to know now.
5. Policy check your notes ask for (iOS and Android): Android is your target. iOS needs a paid Apple
   Developer account, so say in the report that iOS is future scope.

### Step 1: Get a first installable build into closed testing early
Do not wait for a perfect app. After Phase 5 (you can log food), upload that build to the closed track so
the 14 days start. Keep uploading improved builds during the 14 days (updates do not reset the clock
as long as testing stays continuous and you do not pause the track).

### Step 2: Store listing checklist (all your own work, no copyrighted images)
- [ ] App name: **Bite**. Short description with search words (ASO), e.g. "Pakistani calorie and gym tracker: log roti, pyali, nihari."
- [ ] Full description naming real foods people search: roti calories, biryani calories, nihari, haleem, daal chawal
- [ ] 512 x 512 icon and 1024 x 500 feature graphic you design yourself (you are the UI/UX lead!)
- [ ] 4 to 8 screenshots taken from your own app
- [ ] **Privacy policy URL** (required even for offline apps; a simple page on GitHub Pages is fine)
- [ ] Data safety form: "no data collected, all data stays on device" (true if you add no analytics)
- [ ] Content rating questionnaire, target audience 18+, ads declaration = no ads
- [ ] Health disclaimer in app and listing: "Bite gives estimates, not medical advice."
- [ ] Target a recent Android API level as Play currently requires (check Console warnings)

### Step 3: Revenue (the 4 GPA part)
- Real subscriptions need Google Play Billing (`in_app_purchase` package) and a **payments profile that
  can receive payouts in Pakistan. I could not verify that Pakistan is a supported payout country,
  so check Play Console > Payments profile / supported countries today, or ask sir.**
  If payouts are not possible for you, tell sir early and ask what he accepts as revenue (for example
  a team member abroad as the account holder, or a proof-of-concept with live subscription products).
- Your own deck's math: about 7 annual subscribers = $100 after Google's 15%. Plan how you get them:
  your UI/UX community, gym groups, university WhatsApp groups, TikTok/Instagram reels of the roti and
  oil-chip demo, and local fitness creators.
- Only wire real billing AFTER the free app is stable in closed testing. Until then keep the demo paywall.
