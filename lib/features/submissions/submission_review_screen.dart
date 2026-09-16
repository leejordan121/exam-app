import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/answer_grid_editor.dart';
import '../auth/auth_providers.dart';
import '../exams/exam_model.dart';
import '../grading/grading_service.dart';
import 'submission_repository.dart';

class SubmissionReviewScreen extends ConsumerStatefulWidget {
  final Exam exam;
  final File photo;
  final String studentName;
  final String? rollNumber;
  final Map<String, String> detectedAnswers;

  const SubmissionReviewScreen({
    super.key,
    required this.exam,
    required this.photo,
    required this.studentName,
    required this.rollNumber,
    required this.detectedAnswers,
  });

  @override
  ConsumerState<SubmissionReviewScreen> createState() => _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState extends ConsumerState<SubmissionReviewScreen> {
  late Map<String, String> _answers;
  late GradingResult _result;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _answers = Map.of(widget.detectedAnswers);
    _recompute();
  }

  void _recompute() {
    _result = GradingService.grade(answerKey: widget.exam.answerKey, studentAnswers: _answers);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final teacherId = ref.read(currentUserProvider)!.id;
      final repo = ref.read(submissionRepositoryProvider);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.studentName.replaceAll(' ', '_')}.jpg';
      final photoPath = await repo.uploadPhoto(
        teacherId: teacherId,
        examId: widget.exam.id,
        photo: widget.photo,
        fileName: fileName,
      );
      await repo.createSubmission(
        examId: widget.exam.id,
        studentName: widget.studentName,
        rollNumber: widget.rollNumber,
        photoPath: photoPath,
        detectedAnswers: widget.detectedAnswers,
        finalAnswers: _answers,
        score: _result.correctCount,
        totalQuestions: _result.totalQuestions,
      );
      if (!mounted) return;
      context.go('/exams/${widget.exam.id}');
    } catch (e) {
      setState(() => _error = 'Could not save this submission: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Score', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${_result.correctCount} / ${_result.totalQuestions}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check the answers we read off the photo below and fix anything that looks wrong — green means correct, red means incorrect or empty.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AnswerGridEditor(
            initialAnswers: _answers,
            initialQuestionCount: widget.exam.totalQuestions,
            referenceAnswers: widget.exam.answerKey,
            onChanged: (answers) => setState(() {
              _answers = answers;
              _recompute();
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Submission'),
          ),
        ],
      ),
    );
  }
}
