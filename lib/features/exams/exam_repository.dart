import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import 'exam_model.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) => ExamRepository());

class ExamRepository {
  Future<List<Exam>> listExams(String teacherId) async {
    final rows = await supabase
        .from('mcq_exams')
        .select()
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Exam.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<Exam> getExam(String examId) async {
    final row = await supabase.from('mcq_exams').select().eq('id', examId).single();
    return Exam.fromMap(row);
  }

  Future<Exam> createExam({required String teacherId, required String title}) async {
    final row = await supabase
        .from('mcq_exams')
        .insert({'teacher_id': teacherId, 'title': title})
        .select()
        .single();
    return Exam.fromMap(row);
  }

  /// Uploads a file to `mcq-question-papers` (public bucket) and stores its
  /// path on the exam row.
  Future<String> uploadQuestionPaper({
    required String teacherId,
    required String examId,
    required File file,
    required String fileName,
  }) async {
    final path = '$teacherId/$examId/$fileName';
    await supabase.storage.from('mcq-question-papers').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    await supabase.from('mcq_exams').update({'question_paper_path': path}).eq('id', examId);
    return path;
  }

  /// Uploads a file to the private `mcq-answer-keys` bucket and stores its path.
  Future<String> uploadAnswerKeyFile({
    required String teacherId,
    required String examId,
    required File file,
    required String fileName,
  }) async {
    final path = '$teacherId/$examId/$fileName';
    await supabase.storage.from('mcq-answer-keys').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    await supabase.from('mcq_exams').update({'answer_key_path': path}).eq('id', examId);
    return path;
  }

  String questionPaperPublicUrl(String path) {
    return supabase.storage.from('mcq-question-papers').getPublicUrl(path);
  }

  Future<String> answerKeySignedUrl(String path) {
    return supabase.storage.from('mcq-answer-keys').createSignedUrl(path, 60 * 60);
  }

  Future<void> confirmAnswerKey({
    required String examId,
    required Map<String, String> answerKey,
  }) async {
    await supabase.from('mcq_exams').update({
      'answer_key': answerKey,
      'total_questions': answerKey.length,
      'status': 'ready',
    }).eq('id', examId);
  }

  Future<void> startExam(String examId) async {
    await supabase.from('mcq_exams').update({
      'status': 'active',
      'started_at': DateTime.now().toIso8601String(),
    }).eq('id', examId);
  }

  Future<void> closeExam(String examId) async {
    await supabase.from('mcq_exams').update({
      'status': 'closed',
      'closed_at': DateTime.now().toIso8601String(),
    }).eq('id', examId);
  }
}
