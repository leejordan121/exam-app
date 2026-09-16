import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/answer_grid_editor.dart';
import 'exam_repository.dart';

class AnswerKeyReviewScreen extends ConsumerStatefulWidget {
  final String examId;
  final Map<String, String> detectedAnswers;

  const AnswerKeyReviewScreen({super.key, required this.examId, required this.detectedAnswers});

  @override
  ConsumerState<AnswerKeyReviewScreen> createState() => _AnswerKeyReviewScreenState();
}

class _AnswerKeyReviewScreenState extends ConsumerState<AnswerKeyReviewScreen> {
  late Map<String, String> _answers;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _answers = Map.of(widget.detectedAnswers);
  }

  int get _initialCount {
    if (_answers.isEmpty) return 20;
    final maxQ = _answers.keys.map((k) => int.tryParse(k) ?? 0).reduce((a, b) => a > b ? a : b);
    return maxQ.clamp(1, 300);
  }

  Future<void> _confirm() async {
    if (_answers.isEmpty) {
      setState(() => _error = 'Mark at least one answer before continuing');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(examRepositoryProvider).confirmAnswerKey(examId: widget.examId, answerKey: _answers);
      if (!mounted) return;
      context.pushReplacement('/exams/${widget.examId}');
    } catch (e) {
      setState(() => _error = 'Could not save answer key: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Answer Key')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.detectedAnswers.isEmpty
                ? 'We could not read answers automatically from that file. Please set the correct option for each question.'
                : 'We read these answers from your file automatically. Please check them and fix anything that looks wrong before continuing.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AnswerGridEditor(
            initialAnswers: _answers,
            initialQuestionCount: _initialCount,
            onChanged: (answers) => _answers = answers,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _confirm,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Confirm & Save Answer Key'),
          ),
        ],
      ),
    );
  }
}
