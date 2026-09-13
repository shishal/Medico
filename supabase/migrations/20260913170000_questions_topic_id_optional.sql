-- Topic is a syllabus tag, not the exam unit. Editors can upload a PYQ
-- before the chapter is known; lesson_id was already nullable.
alter table public.questions
  alter column topic_id drop not null;

comment on column public.questions.topic_id is
  'Optional syllabus tag. Null until the editor fills topic_name on the sheet.';
