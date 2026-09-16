-- Run this in the Supabase SQL Editor (Project > SQL Editor > New query) once,
-- after creating the project. Then create the 3 storage buckets described in
-- the README (bucket creation/policies aren't included here since they're
-- simplest to set up from the Storage tab in the dashboard).
--
-- Table/function/trigger names are prefixed with mcq_ because this Supabase
-- project is shared with another, unrelated app.

-- Teacher profile, mirrors auth.users. One row per signed-up teacher.
create table mcq_teachers (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  created_at timestamptz default now()
);

-- Auto-create a mcq_teachers row whenever someone signs up.
-- NOTE: auth.users is shared with your other project on this same Supabase
-- instance, so this trigger fires for every signup from either app. It only
-- inserts into mcq_teachers (harmless no-op for the other app's users).
create function public.handle_new_mcq_teacher()
returns trigger as $$
begin
  insert into public.mcq_teachers (id, email) values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created_mcq_teacher
  after insert on auth.users
  for each row execute procedure public.handle_new_mcq_teacher();

create table mcq_exams (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid references mcq_teachers(id) not null,
  title text not null,
  question_paper_path text,
  answer_key_path text,
  answer_key jsonb not null default '{}',
  total_questions int not null default 0,
  status text not null default 'draft' check (status in ('draft', 'ready', 'active', 'closed')),
  created_at timestamptz default now(),
  started_at timestamptz,
  closed_at timestamptz
);

create table mcq_submissions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid references mcq_exams(id) not null,
  student_name text not null,
  roll_number text,
  photo_path text,
  detected_answers jsonb not null default '{}',
  final_answers jsonb not null default '{}',
  score numeric,
  total_questions int not null default 0,
  graded boolean not null default false,
  created_at timestamptz default now()
);

-- Row Level Security: a teacher can only see/edit their own exams and the
-- submissions that belong to their own exams.
alter table mcq_teachers enable row level security;
alter table mcq_exams enable row level security;
alter table mcq_submissions enable row level security;

create policy "teacher reads own profile" on mcq_teachers
  for select using (id = auth.uid());
create policy "teacher updates own profile" on mcq_teachers
  for update using (id = auth.uid());

create policy "teacher owns exam" on mcq_exams
  for all using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

create policy "teacher owns submissions" on mcq_submissions
  for all using (exam_id in (select id from mcq_exams where teacher_id = auth.uid()))
  with check (exam_id in (select id from mcq_exams where teacher_id = auth.uid()));
