-- Theory PYQs have no A–D key. Phase 1 left questions_correct_option_check as
-- `correct_option in ('A','B','C','D')`, which rejects both NULL and ''.
-- questions_kind_shape already requires a key when kind = mcq.

alter table public.questions drop constraint if exists questions_correct_option_check;
alter table public.questions add constraint questions_correct_option_check
  check (correct_option is null or correct_option in ('A', 'B', 'C', 'D'));
