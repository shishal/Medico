# Product — university-exam MBBS companion

Medico is an **India-focused MBBS university-exam** app: previous-year theory
questions (PYQs), textbook page citations, optional sample answers, topic
reference links, MCQ practice, and exam trackers.

It is **not** a NEET-PG mock-test product. The timed sectional engine still
exists in the codebase for MCQ practice sessions only. Do not surface Mini /
Subject / Mock / Grand catalog tests in the primary IA.

## v1 university (locked)

**Kerala University of Health Sciences (KUHS)** — code `KUHS`, state Kerala.

Why this one: GeckoMed’s deepest archives are RGUHS / KNRUHS / TNMGRMU. KUHS
is in their “non-tier-1” set (shallower papers). One affiliating university,
all MBBS years/subjects — depth over seven hubs.

Swap later by adding a `universities` row and sheet tabs. Schema does not
hardcode KUHS except in seed data.

## Content hierarchy

Year (MBBS phase) → Subject → Topic → Lesson → questions (theory PYQ and/or MCQ)

## Question kinds

| Kind | What it is | Player |
|---|---|---|
| `pyq_theory` | University / internal written stem (LAQ/SAQ) | PYQ reader — not scored |
| `mcq` | Four-option recall item | Existing tutor/exam practice player |

## Sample answers and reference links

- **Sample answer** (~250 words) is optional per theory PYQ, collapsed until
  the student taps “Show sample answer.” Pro-gated (separate table). Missing
  content shows “No sample answer yet” — never invent text in the client.
- **Textbook refs** are citations (book + edition + page). Never store PDFs.
- **Lesson resources** are https “read more” links for a longer topic
  explanation. `is_free` links are visible without Pro.

## Monetization

Signup grants **Pro for 4 days**, then effective plan falls back to `free`
via existing `current_plan()`. Free users keep a teaser slice
(`required_plan = 'free'`). Paid plans stay on the **website Razorpay
checkout**, not Play/App Store IAP.

## Out of v1

In-app notes / charts / viva / drug cards, offline packs, campus-ambassador
CRM, seven-university SEO, phone OTP, NEET-PG mode in the UI.
