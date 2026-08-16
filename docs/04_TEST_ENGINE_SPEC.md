# Test Engine Spec

This is the most detail-dense, highest-risk part of the app — get this wrong and either a student loses a real test attempt, or the scoring is exploitable. Read fully before implementing any part of Phase 5/6.

## 1. Question palette states

| State | Meaning | Convention (matches what NEET candidates already know from the real exam UI) |
|---|---|---|
| Not Visited | Never opened during this attempt | Grey |
| Not Answered | Opened, no option selected | Red |
| Answered | An option is currently selected | Green |
| Marked for Review (unanswered) | Flagged, no option selected | Purple |
| Answered & Marked for Review | Flagged, has an option selected | Purple with a small green checkmark/dot |

Tapping any palette cell navigates directly to that question, regardless of current state (except for questions in a section already locked by the section timer — see §3).

## 2. Actions and their state transitions

| Action | Effect |
|---|---|
| Select an option | Question becomes **Answered** (or **Answered & Marked** if it was already marked) |
| "Clear Response" | Removes the selected option; question reverts to **Not Answered** (or **Marked for Review** if it was marked) |
| "Mark for Review & Next" | Sets the marked flag (keeping current answered/unanswered state), advances to next question |
| "Save & Next" | No explicit save action needed beyond normal autosave (§4) — this button just advances to the next question; naming it "Save & Next" is a UI convention students expect from the real exam, not a distinct technical operation |
| Navigating away from a question (any method) without selecting anything | Question becomes **Not Answered** if it was **Not Visited** |

## 3. Timer and sectional behavior

**Non-sectional tests** (mini/subject/mock, `is_sectional = false`): one countdown from `total_duration_minutes`, starting the instant the attempt is created. Reaching zero auto-submits immediately with whatever is saved.

**Sectional tests** (grand tests, `is_sectional = true`): the real NEET-PG 2026 shape is 5 sections × 36 questions × 42 minutes each (180 total, 210 minutes) — seed data and any hardcoded assumptions should match this, but read `section_count`/`questions_per_section`/`section_duration_minutes` from the `tests` row rather than hardcoding, since the exact numbers can change year to year.

- Each section has its own countdown, starting the moment the student enters that section.
- **Default rule (documented decision, easy to change if it doesn't match the real exam software you're mimicking)**: a student can move to the next section early via an explicit "Submit Section & Continue" action (with a confirmation dialog showing how many questions in that section are still unanswered), **or** the section auto-advances when its timer hits zero — whichever comes first.
- **Once a section is exited (by either path), it is permanently locked** — no palette or navigation control may return to it. This matches how students already expect grand tests to behave and is non-negotiable, not a style choice.
- The final section reaching zero (or being manually submitted) triggers full test submission, not just section advance.

**Critical anti-cheat requirement — read carefully**: the timer's source of truth is **wall-clock elapsed time since `started_at`** (a server timestamp), never a purely local countdown value. Concretely:

- On resume after the app was force-killed or backgrounded for a long time, compute remaining time as `duration - (now - started_at)` (or the equivalent per-section calculation using a stored section-start timestamp), not from a saved "remaining seconds" value.
- If this calculation shows the test/section should already have ended, **auto-submit immediately on resume** using whatever answers were saved locally — don't let a force-quit function as a pause button.
- Store `started_at` (and each section's start timestamp) both locally and, as soon as connectivity allows, on the `attempts` row server-side, so the check can't be defeated by changing the device clock while offline (validate against the Supabase timestamp when connectivity returns; if local and server clocks disagree by more than a couple of minutes, trust the server).

## 4. Autosave and offline resilience

- Every state-changing action (answer selected, cleared, marked, navigation) triggers a debounced (~500ms) rewrite of a local JSON file at `attempt_<attempt_id>.json` via `path_provider`, containing: `attempt_id`, `test_id`, `started_at`, section start timestamps, current question index, and the full per-question answer/mark/time-spent state.
- Track `time_spent_seconds` per question: start a stopwatch when a question becomes visible, accumulate the delta into that question's total whenever the student navigates away from it.
- **The test must be fully usable with zero connectivity** once its questions are downloaded at attempt start — this is a real-world requirement given patchy mobile internet, not a nice-to-have. Only the final submission needs a network call.
- If submission fails due to connectivity, mark local status `pending_submit`, keep the full local answer state, and retry with exponential backoff — including retrying automatically the next time the app opens, not just in the background of the current session.
- On app open, if a local `pending_submit` or `in_progress` attempt file exists: reconcile against the server (query that attempt's `status` — someone might have submitted from another device, unlikely but check anyway), then either resume, auto-submit (per §3's elapsed-time rule), or complete the pending submission.
- Allow only one `in_progress` attempt per `(user_id, test_id)` — if a student tries to start a test they already have in progress, take them straight to resume rather than creating a second attempt row.

## 5. Scoring (must run server-side — see build plan 6.1 for why)

For each question belonging to the test:

```
if attempt_answers row is missing OR selected_option is null:
    → unattempted; score contribution = tests.unattempted_marks (default 0)
elif selected_option == questions.correct_option:
    → correct; score contribution = tests.correct_marks (default +4)
else:
    → incorrect; score contribution = tests.incorrect_marks (default -1)
```

`total_score` = sum of all contributions. `correct_count`/`incorrect_count`/`unattempted_count` are simple tallies. Run `calculate_percentile()` (from `02_DATABASE_SCHEMA.md` §6) immediately after and store the result on the same `attempts` row.

## 6. Validation checklist (go through every line by hand before considering Phase 5/6 done)

- [ ] Answer a question, confirm palette turns green immediately
- [ ] Mark a question for review without answering, confirm it's purple (not green, not red)
- [ ] Answer *and* mark the same question, confirm the combined visual state
- [ ] Use "Clear Response" on an answered question, confirm it reverts correctly (to red if unmarked, purple if marked)
- [ ] Let a non-sectional test's timer run to zero (use a short test duration for this test, don't wait out a real 3.5-hour timer) — confirm auto-submit fires exactly once, not multiple times
- [ ] In a sectional test, let one section's timer hit zero with unanswered questions remaining — confirm it locks and auto-advances, and that the locked section's questions are no longer reachable via the palette
- [ ] Force-quit the app mid-test (not graceful close — actually kill the process), reopen, confirm all previously entered answers are intact
- [ ] Force-quit the app, wait past when the test *should* have ended (adjust a test's duration to something short for this check), reopen — confirm it auto-submits on resume rather than resuming a dead timer
- [ ] Enable airplane mode mid-test, continue answering questions normally, confirm no crash and no data loss; disable airplane mode, confirm any pending submission completes automatically
- [ ] Try to start a test that already has an `in_progress` attempt for that user — confirm you're routed to resume, not a fresh duplicate attempt
- [ ] Submit a test with a deliberately known mix of correct/incorrect/unattempted answers, hand-calculate the expected score against the test's actual marking scheme, confirm the stored `total_score` matches exactly — do this for both a simple test and the sectional grand test
- [ ] Confirm the score shown to the user was computed server-side (check by inspecting network traffic — the client should be sending answers and *receiving* a score, not sending a pre-computed score)
