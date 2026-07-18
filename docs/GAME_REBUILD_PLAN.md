# Building Competition - Game Understanding and Rebuild Plan

## 1. Product vision

Rebuild the project as an Arabic-first, moderator-led strategy game that combines cultural questions with city planning. The board should be the star of the experience: teams should immediately understand what they own, what each building earns, how factories and complexes change nearby buildings, what happened this round, and what choices are available next.

The target experience is closer to a polished live game show plus a light city-building board game than an administrative spreadsheet.

Primary platform: desktop/web for the moderator and a second large spectator display. Mobile team participation can be added later without blocking the core rebuild.

## 2. Rules understood from the PDF

The source document defines the following game:

1. The map is a 10 x 10 grid containing 100 squares.
2. Teams construct one building per occupied square.
3. There are six building types:

| Building | Build cost | Base income each round |
|---|---:|---:|
| House - بيت | 100 | 200 |
| Grocery - بقالة | 200 | 350 |
| Market - سوق | 300 | 400 |
| Hotel - فندق | 400 | 450 |
| Factory - مصنع | 1,000 | 600 |
| Complex - مجمع | 1,000 | 600 |

4. Each team may build once in odd rounds 1, 3, and 5, and twice in even rounds 2, 4, and 6. This gives each team a maximum of nine buildings over six rounds.
5. A correct cultural-question answer adds 100 points to the team's total.
6. A complex changes the round income of adjacent buildings:

| Adjacent building | Income near a complex | Change from base |
|---|---:|---:|
| House | 350 | +150 |
| Hotel | 600 | +150 |
| Grocery | 200 | -150 |
| Market | 250 | -150 |

7. A factory changes the round income of adjacent buildings in the opposite direction:

| Adjacent building | Income near a factory | Change from base |
|---|---:|---:|
| House | 50 | -150 |
| Hotel | 300 | -150 |
| Grocery | 500 | +150 |
| Market | 550 | +150 |

8. After every two rounds, a movement/physical mini-game is played. Its winner may use one of four cards:

| Card | PDF effect |
|---|---|
| Freeze - تجميد | Stop a team from building for one round |
| Demolish - حذف | Remove any opponent building from the map |
| Control - سيطرة | Take ownership of any opponent building |
| Income stop - إيقاف عائد | Stop an opponent building's income for one round |

9. The example map indicates that the number beside a building is the owning team number, the number below is that building's current income, yellow squares show factory influence, and blue squares show complex influence.
10. “Adjacent” appears to mean all eight surrounding squares, including diagonals. This matches the 3 x 3 influence areas in the example and the current implementation.

## 3. Rules that are currently ambiguous

These decisions must be written into Rulebook v2 before the game engine is treated as final:

- Are points both the currency used to build and the score used to win, or is build cost only a score deduction?
- Must a team have enough points before it can build, or may its balance become negative?
- Does influence affect every nearby building regardless of owner? The strategic recommendation is yes.
- When both a factory and a complex influence the same square, do they cancel? Since every effect is exactly ±150, cancellation to the base income is the cleanest rule.
- Do two factories or two complexes stack? The recommendation is no; each influence type applies at most once per building.
- Does a newly built building produce income immediately in the same round? The recommendation is yes, because that matches the existing app.
- Can a building be replaced or upgraded? The recommendation is no unless a specific card or future upgrade rule allows it.
- What happens when two teams choose the same square? A visible turn order should prevent this conflict.
- Can cards target factory/complex buildings, the last-place team, or a building created in the current round?
- Does “income stop” target one building or every building owned by the opponent? The wording refers to one building; the rebuild should use that interpretation.
- How is the winner decided after round six, and how are ties broken?

## 4. What the current app already does well

- Represents a configurable grid and five color-coded teams.
- Includes the six correct building costs and base incomes.
- Calculates eight-direction adjacency.
- Implements the complex and factory income tables.
- Treats simultaneous factory and complex influence as cancellation to base income.
- Charges a build cost once and then pays income in later rounds.
- Provides save/load, round undo/redo, manual score adjustment, statistics, and a spectator screen.
- Has a useful starting set of rule tests. All seven current tests pass.

These pieces are valuable references, but the game should be rebuilt around a formal game engine rather than extending the current screen-by-screen logic.

## 5. Current gaps and risks

### Gameplay gaps

- There is no six-round limit or end-game state.
- Odd/even build limits are not enforced.
- Questions and correct-answer rewards are not modeled; the moderator can only adjust a score manually.
- Mini-games and all four cards are absent.
- There is no turn/initiative system, no placement validation, and no confirmation of a team's remaining actions.
- There are no rules for debt, ties, card targeting, replacement, or competing for a square.
- A team can freely change any cell's owner and building type at any time.
- There is no round ledger explaining income, costs, bonuses, penalties, and card effects.

### Logic defects or fragile behavior

- Empty cells still contain a default `house` building type internally.
- Removing a cell owner does not remove its building. A deleted factory or complex can therefore continue influencing neighbors while visually appearing unowned.
- Cell edits are not added to the undo history; only round settlement and manual score edits are undoable.
- A nullable custom income override cannot reliably be cleared through the current `copyWith` implementation.
- Ownership transfer is inferred from editing a team ID; it is not modeled as a card action with explicit cost/effect rules.
- Settings changes reset the game immediately.
- Save files have no schema version or migration strategy.
- The current spectator sync relies on browser messaging/local storage or desktop file polling instead of a reliable session protocol.

### UX and visual gaps

- The 10 x 10 board is too small relative to the surrounding panels, especially on a 1280 x 720 display.
- Empty squares are visually noisy and buildings are generic Material icons, so the board does not feel like a city.
- Strategic influence is invisible until a cell is inspected.
- The moderator edits raw owner/building dropdowns instead of following a guided round flow.
- There is no visual phase, active team, available build count, card inventory, question result, or event history.
- The spectator view shows state but does not tell the story of what just happened.
- Team identity relies mainly on color, which is weak for accessibility and projection quality.
- The app uses a generic dark dashboard aesthetic rather than a distinctive Arabic city-building identity.

### Code health

- The game controller mixes rules, persistence, history, synchronization, and UI notifications.
- The main dashboard is over 1,100 lines and combines navigation, layout, board cells, scoring, dialogs, and editing.
- The analyzer currently reports 28 warnings/info items, including deprecated Flutter/web APIs and unsafe async context usage.
- Tests cover the basic income table but not rule limits, invalid actions, cards, save migrations, end-game behavior, or spectator synchronization.

## 6. Recommended Rulebook v2

### 6.1 Core structure

- Keep six rounds.
- Support 3-6 teams, with five as the default.
- Use an 8 x 8 board as the recommended competitive map for five teams. Nine buildings per team fill 45 of 64 squares, creating meaningful adjacency and conflict. Keep 10 x 10 as a “spacious/classic” preset.
- Use all eight neighboring squares for influence.
- Factory and complex effects apply to any team's adjacent building.
- Effects of the same type do not stack. One factory plus one complex cancels to base income.
- Empty cells contain no building. Buildings cannot exist without an owner.
- A normal build must target an empty square; normal replacement is not allowed.

### 6.2 Round sequence

Every round should be resolved through an explicit phase machine:

1. Round intro: show round number, build allowance, initiative order, and any ongoing effects.
2. Quiz phase: moderator records correct/incorrect answers and the app applies the configured reward.
3. Build phase: teams place one building in odd rounds or two in even rounds.
4. Influence preview: the app previews all factory/complex changes before confirmation.
5. Income phase: settle building income and show an itemized animated ledger.
6. Mini-game/card phase: after rounds 2, 4, and 6, record the mini-game winner and resolve one card.
7. Recap: show ranking changes, biggest income, and the next round's initiative.

For fair placement, use a rotating snake order. In a two-build round, teams act from first to last for the first build, then last to first for the second. Rotate the starting team each round.

### 6.3 Economy recommendation

The original values make property income much larger than the 100-point question reward. A single early building can earn thousands over six rounds, so cultural knowledge quickly becomes secondary.

Use two selectable presets during prototyping:

**Classic preset:** preserve the PDF's costs/incomes and the single points balance. This ensures backward compatibility.

**Balanced preset (recommended):** use separate concepts for treasury and victory progress:

- Correct answer: +100 treasury and one Knowledge Star.
- Building costs and income use treasury.
- Knowledge Stars are the main victory measure.
- City achievements and final treasury contribute secondary victory points at a reduced conversion rate.
- The final result screen explains every scoring source.

This preserves the cultural purpose while keeping economic strategy meaningful. Exact conversion and income values should be finalized only after simulation and live playtests, not by intuition alone.

If a single-score system must be retained, increase question rewards and reduce recurring building income until quiz performance accounts for roughly 40-60% of a typical final score.

### 6.4 Card rebalance

The PDF's cards are not equal. Permanent control and unrestricted demolition are far stronger than stopping one round of income.

Recommended first balance pass:

| Card | Recommended effect |
|---|---|
| Freeze | Remove one build action from the target team next round, not the entire round if it normally has two actions |
| Demolish | Remove one basic building; the owner receives 50% of its build cost as compensation |
| Control | Take the income from one opponent building for one income phase; ownership then returns |
| Income stop | Disable one chosen building for the next income phase, including its influence if it is a factory/complex |

Additional safeguards:

- A card must be used immediately or held for at most one round.
- A building constructed this round cannot be targeted until the next round.
- The same team cannot be targeted by consecutive mini-game cards.
- The UI previews the exact score impact before the moderator confirms.
- Card rules should be configurable so the original event rules can still be used as a “Classic cards” preset.

### 6.5 End game and ties

- End automatically after the round-six income and final card resolution.
- Show a full result breakdown instead of only the largest number.
- Recommended tie-breakers: Knowledge Stars, then final-round income, then number of distinct building types, then a single tie-break question.

## 7. Strategic depth to add without making the game hard to learn

- Influence zones: hover/selecting a factory or complex highlights its 3 x 3 area.
- Placement forecast: before building, show expected immediate income and the effect on all nearby buildings, separated into “your gain,” “opponent gain,” and “opponent loss.”
- District objectives: reveal two or three simple goals per game, such as owning three different building types in one district or surrounding a landmark. These create alternative strategies.
- Map presets: classic empty board, dense 8 x 8 board, and landmark map with a few neutral blocked squares.
- Rotating initiative: prevents one team from always taking the best cells.
- Catch-up design: mini-game targeting safeguards and objectives should create comeback paths without directly awarding points to the last-place team.
- Clear counterplay: a factory helps commerce and hurts residential buildings; a complex does the reverse. Players can defend by spacing, countering with the opposite influence, or choosing a different district.

Avoid adding a technology tree, loans, trading, or many building upgrades in the first release. The factory/complex relationship already supplies a strong strategic core when the board is dense enough and previews are clear.

## 8. New visual direction

### Identity

Use a modern Arabic city-planning theme: warm sandstone, deep indigo, turquoise, copper/gold highlights, geometric Islamic patterns used sparingly, and bright team colors. The tone should feel energetic and competitive, not corporate.

Use a bundled Arabic font so the event works fully offline. Team identity should combine color, emblem, and pattern so it remains clear for color-blind players and on projectors.

### Board

- Make the board occupy 65-75% of the moderator game screen.
- Use clean top-down or light 2.5D illustrated buildings rather than generic icons.
- Show ownership as a colored plot border/flag, not a heavy full-cell tint.
- Display factory zones with a subtle amber grid overlay and complex zones with a cyan overlay.
- Overlap should visually neutralize or use a split pattern.
- Show income only when relevant; otherwise keep the city readable.
- Add zoom, pan, fit-to-board, and a strategic overlay toggle.

### Moderator screen

- Top bar: round, current phase, active team, timer, undo, and session health.
- Center: large board and placement preview.
- Side panel: context-sensitive action flow rather than permanent raw dropdowns.
- Bottom/event rail: recent answers, builds, cards, and income changes.
- Primary button always describes the next safe action, such as “Confirm Team 3 build” or “Settle round income.”

### Spectator screen

- Large readable board, standings ribbon, current phase, and active team.
- Animated event ticker: “Team 2 built a market,” “Factory increased market income by 150,” etc.
- Short income animations and rank movement after settlement.
- No moderator controls and no small explanatory text.
- Designed first for 1920 x 1080 projection, then made responsive.

### Motion and sound

- Building rises into place with a 250-400 ms animation.
- Influence zone pulses once when created or changed.
- Coins/points travel to the team's score during settlement.
- Card effects use distinctive but short animations.
- Sound is optional, globally controllable, and never required to understand an event.

## 9. Product flows

### New game setup

1. Choose Classic or Balanced rules.
2. Choose team count and edit team names, colors, emblems, and order.
3. Choose board preset and verify the spectator display.
4. Show a one-screen rules summary.
5. Start round one.

### Moderator build flow

1. App highlights the active team and remaining builds.
2. Moderator selects a building card.
3. Valid squares are highlighted; invalid squares explain why.
4. Hovering a square previews cost, income, and all influence changes.
5. Moderator confirms once; an event is added to the ledger.
6. App advances to the next team according to snake order.

### Round settlement

1. Lock editing.
2. Show a pre-settlement audit for unanswered questions, unused build actions, and unresolved cards.
3. Calculate a deterministic settlement.
4. Present itemized income and effects.
5. Commit the round as one atomic event, with one-click undo.

## 10. Technical rebuild architecture

Keep Flutter, but separate the rules engine from Flutter widgets.

```text
lib/
  app/                 navigation, theme, localization
  domain/
    entities/          Game, Team, Board, Cell, Building, Card, Round
    rules/             RuleSet, EconomyRules, InfluenceRules, CardRules
    engine/            validate action, preview action, resolve phase/round
    events/            AnswerRecorded, BuildingPlaced, CardPlayed, RoundSettled
  application/         session controller and use cases
  infrastructure/      save repository, sync transport, migrations
  presentation/
    moderator/         setup, game, settlement, results
    spectator/         projector display
    shared/            board, team badge, event ledger
```

Key principles:

- Immutable game state.
- Every change is a typed game action/event, never a direct cell mutation.
- One deterministic pure-Dart engine is used by moderator UI, spectator UI, tests, saves, and future multiplayer clients.
- All actions pass validation before they can alter state.
- Undo works by reversing/replaying events or restoring a full immutable snapshot.
- Saved sessions include a schema version, rule-set version, event log, and migration support.
- Rule values are data-driven so Classic and Balanced presets use the same engine.
- Bundle fonts and essential art for offline event use.
- Replace wildcard browser messaging/file polling with a small authenticated local session transport when multi-device spectator mode is added. Same-window dual-screen mode can remain as a fallback.

## 11. Testing and balance plan

### Automated rules tests

- Every building's base income and build cost.
- All four neighbor types under factory, complex, both, multiple same-type influences, board edges, and corners.
- Influence only from owned, active buildings.
- Odd/even build limits and rotating snake order.
- Insufficient funds/debt policy.
- Question reward and manual correction.
- All card durations, legal targets, expiry, and undo.
- Six-round completion and tie-breakers.
- Save/load equivalence and migration from old saves.
- Deterministic replay: the same event list always produces the same result.

### UI tests

- Arabic RTL layout at 1280 x 720, 1440 x 900, and 1920 x 1080.
- Projector-safe contrast and color-blind team identification.
- Full moderator happy path for six rounds.
- Invalid placement, skipped action, correction, undo, reconnect, and spectator refresh.
- Golden-image tests for the board, overlays, settlement, and final results.

### Balance tests

- Run thousands of seeded simulations using simple strategies: highest immediate income, long-term income, aggressive opponent disruption, residential cluster, commercial cluster, and random placement.
- Measure first-player advantage, runaway-leader frequency, card impact, quiz-vs-property score contribution, and how often each building is worth choosing.
- Conduct at least three live playtest waves: rules comprehension, balance/fun, then event-operation reliability.
- Record decisions in a balance changelog so numbers are adjusted deliberately.

## 12. Phased implementation plan

### Phase 0 - Rulebook and prototype decisions

- Approve the ambiguous-rule decisions.
- Define Classic and first Balanced preset data.
- Produce wireframes for setup, moderator board, settlement, spectator, and results.
- Build a small spreadsheet/simulation for economy and card impact.

Exit condition: a versioned Rulebook v2 with no unresolved engine behavior.

### Phase 1 - Pure game engine

- Create immutable domain models and phase state machine.
- Implement action validation, placement previews, influences, settlement, questions, build limits, cards, and end game.
- Add event log, deterministic undo/replay, save schema, and comprehensive unit tests.

Exit condition: a complete six-round game can run in tests without Flutter UI.

### Phase 2 - Moderator experience

- Build new theme and reusable board renderer.
- Implement setup wizard, guided round flow, build preview, round audit, settlement ledger, corrections, and recovery.
- Add offline persistence and automatic checkpoints.

Exit condition: a moderator can run a full game without manual arithmetic or raw data editing.

### Phase 3 - Spectator and presentation polish

- Build projector-first spectator layout.
- Add event animations, ranking transitions, influence overlays, sound controls, fullscreen, and reconnect state.
- Create final-results ceremony and exportable game summary.

Exit condition: the game is readable, exciting, and stable on a second display.

### Phase 4 - Balance and content

- Add rule simulations and telemetry that remains local by default.
- Run live playtests and tune the Balanced preset.
- Add map presets, district objectives, rule tutorial, and optional question-bank import.

Exit condition: no dominant building/card strategy and new players can explain the core rules after one guided round.

### Phase 5 - Optional team devices

- Add QR/session-code joining, hidden team choices, and moderator approval.
- Use a local-network host so the event can run without internet.
- Keep the moderator able to perform every action if a team device disconnects.

Exit condition: mobile participation improves speed without making the live event dependent on phones or internet.

## 13. Definition of done for the rebuild

- Every PDF rule is either implemented, intentionally revised, or disabled by a named rule preset.
- The app prevents illegal moves instead of relying on moderator memory.
- Every score change has an understandable ledger entry.
- A full game can be completed, undone, saved, restored, and replayed deterministically.
- Moderator and spectator screens work offline and remain synchronized.
- Arabic RTL typography and interaction are polished at all target resolutions.
- Strategy is visible before confirmation, including factory/complex effects.
- Questions matter materially to winning.
- No single building or card is dominant across balance simulations and live playtests.
- The project has zero analyzer errors/warnings targeted by the team and strong engine/UI test coverage.

## 14. Recommended immediate next step

Do not begin with visual coding. First approve the ten ambiguous rules in section 3 and select whether the first playable rebuild uses Classic economy or the recommended Balanced economy. Then implement Phase 1 as a standalone tested engine while the visual system and screen wireframes are designed in parallel.
