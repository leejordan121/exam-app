# Exam Grader

Teacher-only Android app: create an MCQ exam, share a download link with
students, then photograph each completed paper and get an auto-computed
score.

Teachers only sign up/sign in — there is no student account or login.
Students receive a public download link to the question paper and fill it
in on paper; the teacher photographs each completed paper afterwards and
uploads it under the exam.

## How grading works

The question paper and answer key are uploaded as whatever file the teacher
already has (PDF or photo) — there's no fixed template, so the app can't
rely on pixel-exact bubble positions. Instead, on-device OCR
(`google_mlkit_text_recognition`) reads lines like `1. A`, `Q2) C` off the
answer key image and off each student photo, and auto-computes a score.
Because photo OCR isn't perfect, both the answer key and every submission
go through a quick editable review screen before being saved as final —
this keeps grading fast while avoiding silently-wrong scores.

## One-time Supabase setup

This app shares a Supabase project with another, unrelated app, so every
table/bucket/trigger name here is prefixed with `mcq_`/`mcq-` to avoid
collisions. Note that `auth.users` (and therefore signups) is still shared
across both apps on this project — the profile trigger only writes to
`mcq_teachers`, so it's harmless for the other app's users, but if full
isolation ever matters, move this app to its own Supabase project instead.

1. Create a project at [supabase.com](https://supabase.com) and grab the
   **Project URL** and **anon/publishable key** from Settings → API.
2. Fill them into `lib/core/supabase_config.dart` (copy from
   `supabase_config.example.dart` if that file doesn't exist yet — it's
   gitignored so your keys never get committed).
3. Open the SQL Editor in the Supabase dashboard and run
   [`supabase/migration.sql`](supabase/migration.sql) — creates the
   `mcq_teachers` / `mcq_exams` / `mcq_submissions` tables, the auto-profile
   trigger, and Row Level Security policies.
4. Open the Storage tab and create 3 buckets with these exact names:
   - `mcq-question-papers` — **Public bucket: ON** (students need to
     download without logging in)
   - `mcq-answer-keys` — Public bucket: OFF
   - `mcq-submissions` — Public bucket: OFF
5. Back in the SQL Editor, run
   [`supabase/storage_policies.sql`](supabase/storage_policies.sql) — scopes
   read/write on each bucket to the owning teacher (except public reads on
   `mcq-question-papers`).

## Running the app

```
flutter pub get
flutter run
```

Android SDK/tooling is already configured on this machine
(`D:\Android\Sdk`, `D:\flutter`).

## Project structure

```
lib/
  core/            Supabase client/config, router, theme
  features/
    auth/          Teacher sign up / sign in
    exams/         Create exam, upload files, answer-key review, exam detail
    submissions/   Capture a student's paper, OCR review, save score
    grading/       OCR parsing + score comparison, independent of Supabase/UI
  widgets/         Shared UI (the editable answer grid)
supabase/
  migration.sql          Tables, trigger, RLS
  storage_policies.sql   Storage bucket access policies
```
