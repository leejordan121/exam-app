import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../submissions/submission_model.dart';
import '../submissions/submission_repository.dart';
import 'exam_model.dart';
import 'exam_repository.dart';

class ExamDetailScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamDetailScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends ConsumerState<ExamDetailScreen> {
  late Future<(Exam, List<Submission>)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dataFuture = _fetch();
  }

  Future<(Exam, List<Submission>)> _fetch() async {
    final exam = await ref.read(examRepositoryProvider).getExam(widget.examId);
    final submissions = await ref.read(submissionRepositoryProvider).listSubmissions(widget.examId);
    return (exam, submissions);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _dataFuture;
  }

  Future<void> _startExam() async {
    await ref.read(examRepositoryProvider).startExam(widget.examId);
    _refresh();
  }

  Future<void> _closeExam() async {
    await ref.read(examRepositoryProvider).closeExam(widget.examId);
    _refresh();
  }

  void _copyLink(Exam exam) {
    if (exam.questionPaperPath == null) return;
    final url = ref.read(examRepositoryProvider).questionPaperPublicUrl(exam.questionPaperPath!);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Details')),
      body: FutureBuilder<(Exam, List<Submission>)>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final (exam, submissions) = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(exam.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('${exam.totalQuestions} questions · Status: ${exam.status}'),
                const SizedBox(height: 16),
                if (exam.status == 'draft')
                  FilledButton(
                    onPressed: () => context.push('/exams/${exam.id}/answer-key', extra: exam.answerKey),
                    child: const Text('Finish setting up answer key'),
                  ),
                if (exam.status != 'draft') ...[
                  OutlinedButton.icon(
                    onPressed: () => _copyLink(exam),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy paper link to share with students'),
                  ),
                  const SizedBox(height: 12),
                  if (exam.status == 'ready')
                    FilledButton.icon(
                      onPressed: _startExam,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Exam'),
                    ),
                  if (exam.status == 'active') ...[
                    FilledButton.icon(
                      onPressed: () async {
                        await context.push('/exams/${exam.id}/submissions/new', extra: exam);
                        _refresh();
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Add Student Paper'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _closeExam,
                      icon: const Icon(Icons.stop),
                      label: const Text('Close Exam'),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                Text('Submissions (${submissions.length})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (submissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No student papers uploaded yet.'),
                  )
                else
                  ...submissions.map((s) => Card(
                        child: ListTile(
                          title: Text(s.studentName),
                          subtitle: Text(s.rollNumber == null ? '' : 'Roll: ${s.rollNumber}'),
                          trailing: Text(
                            '${s.score?.toStringAsFixed(0) ?? '-'} / ${s.totalQuestions}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}
