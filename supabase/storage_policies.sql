-- Run this AFTER creating the 3 storage buckets from the Supabase dashboard
-- (Storage tab > New bucket), named exactly:
--   mcq-question-papers  (Public bucket: ON)
--   mcq-answer-keys       (private)
--   mcq-submissions       (private)
--
-- Prefixed with mcq- because this Supabase project's storage is shared with
-- another, unrelated app.
--
-- The app uploads every file under a "<teacher_id>/<exam_id>/<filename>" path,
-- so these policies scope read/write to the folder matching the signed-in
-- teacher's own id.

-- mcq-question-papers: anyone can read (so the student share link works with
-- no login), but only the owning teacher can upload/replace/delete.
create policy "public can read mcq question papers"
  on storage.objects for select
  using (bucket_id = 'mcq-question-papers');

create policy "teacher manages own mcq question papers"
  on storage.objects for insert
  with check (bucket_id = 'mcq-question-papers' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "teacher updates own mcq question papers"
  on storage.objects for update
  using (bucket_id = 'mcq-question-papers' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "teacher deletes own mcq question papers"
  on storage.objects for delete
  using (bucket_id = 'mcq-question-papers' and (storage.foldername(name))[1] = auth.uid()::text);

-- mcq-answer-keys: fully private, owning teacher only.
create policy "teacher manages own mcq answer keys"
  on storage.objects for all
  using (bucket_id = 'mcq-answer-keys' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'mcq-answer-keys' and (storage.foldername(name))[1] = auth.uid()::text);

-- mcq-submissions: fully private, owning teacher only.
create policy "teacher manages own mcq submissions"
  on storage.objects for all
  using (bucket_id = 'mcq-submissions' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'mcq-submissions' and (storage.foldername(name))[1] = auth.uid()::text);
