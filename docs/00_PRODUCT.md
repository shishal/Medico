# Product — university-exam MBBS companion

Medico is an **India-focused MBBS university-exam** app: previous-year theory
questions (PYQs), textbook page citations, optional sample answers, topic
reference links, and MCQ practice.

It is **not** a NEET-PG mock-test product. The timed sectional engine still
exists in the codebase for MCQ practice sessions only. Mini / Subject / Mock /
Grand catalog tests are **retired** from the student-facing IA (not merely
hidden). Practice sessions still create `tests` / `attempts` rows internally.

## Universities

Students pick their **affiliating university** at onboarding and can change it
on Profile (university, college, MBBS year, batch).

**v1 content bank** is **Kerala University of Health Sciences (KUHS)** —
code `KUHS`, `universities.is_fallback = true`. Other universities are listed
so the picker is real; if that university has no tagged papers yet, the app
shows the KUHS bank with a banner: “Showing default PYQs until [University]
papers are added.” Adding another university later is new sheet rows, not a
schema rewrite.

Curriculum (year → subject → topic → lesson) is **shared** across universities
and is how we **tag** questions for revision. PYQs are
**university-owned** via `exam_papers.university_id` → appearances. A real
university paper mixes many topics in one sitting — see
`docs/10_INDIA_MBBS_EXAMS.md`.

## Content hierarchy

- **Exam unit (what the student sits):** university + subject + year + paper
  (Paper I / Paper II / …) → questions in that paper, several chapters.
- **Syllabus tags (shared):** Year (MBBS phase) → Subject → Topic → Lesson.
  A lesson is a syllabus unit, not a PYQ count. Used to group questions.
- **Question kinds** on a lesson or paper: theory PYQ and/or MCQ.

## Question kinds

| Kind | What it is | Player |
|---|---|---|
| `pyq_theory` | University / internal written stem (essay / short note / VSA by marks) | PYQ reader — not scored |
| `mcq` | Four-option recall item | PYQ reader **DA** / **EX**, **or** the existing tutor/exam practice player |

## Sample answers and reference links

- **Direct answer (DA)** is `sample_answer_text` for theory or MCQ, collapsed
  until the student taps **DA**. Pro-gated (separate table). Missing content
  shows “No direct answer yet” — never invent text in the client. MCQ DA also
  shows the correct option.
- **Explanation (EX)** is `explanation_text` plus textbook citations and
  “More on this topic” links, for either kind. Collapsed until **EX**. Do not
  put the MCQ key on teasers.
- **Textbook refs** are citations (book + edition + page). Never store PDFs.
- **Lesson resources** are https “read more” links. `is_free` links are
  visible without Pro.

## UX direction

Visual language follows GeckoMed’s study apps (dark charcoal canvas, coral
orange CTAs, indigo-purple chrome, gold Pro chips) while keeping **Docci** and
the Medico name. Theme is **System / Light / Dark**, persisted, **Light default**.

Home is a PYQ dashboard (coverage banner, year + university, subject cards).
Opening a subject starts with **exam years**, then that year’s paper outline
(LAQ / Short notes / MCQ tabs). Chapter and Paper I/II live in Filters.
Topic → lesson is for grouping, not the first tap.

## Monetization

Signup grants **Pro for 4 days**, then effective plan falls back to `free`
via existing `current_plan()`. Free users keep a teaser slice
(`required_plan = 'free'`). Paid plans stay on the **website Razorpay
checkout**, not Play/App Store IAP.

## Out of v1

In-app notes / charts / viva / drug cards, offline packs, campus-ambassador
CRM, phone OTP, Internship/PG stages, group-discount checkout, NEET-PG mode
in the UI.
