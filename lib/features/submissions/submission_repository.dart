import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import 'submission_model.dart';

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) => SubmissionRepository());

class SubmissionRepository {
  Future<List<Submission>> listSubmissions(String examId) async {
    final rows = await supabase
        .from('mcq_submissions')
        .select()
        .eq('exam_id', examId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Submission.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<String> uploadPhoto({
    required String teacherId,
    required String examId,
    required File photo,
    required String fileName,
  }) async {
    final path = '$teacherId/$examId/$fileName';
    await supabase.storage.from('mcq-submissions').upload(
          path,
          photo,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<Submission> createSubmission({
    required String examId,
    required String studentName,
    String? rollNumber,
    required String photoPath,
    required Map<String, String> detectedAnswers,
    required Map<String, String> finalAnswers,
    required num score,
    required int totalQuestions,
  }) async {
    final row = await supabase
        .from('mcq_submissions')
        .insert({
          'exam_id': examId,
          'student_name': studentName,
          'roll_number': rollNumber,
          'photo_path': photoPath,
          'detected_answers': detectedAnswers,
          'final_answers': finalAnswers,
          'score': score,
          'total_questions': totalQuestions,
          'graded': true,
        })
        .select()
        .single();
    return Submission.fromMap(row);
  }

  Future<String> photoSignedUrl(String path) {
    return supabase.storage.from('mcq-submissions').createSignedUrl(path, 60 * 60);
  }
}
