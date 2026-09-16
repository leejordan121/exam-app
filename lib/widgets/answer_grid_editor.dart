import 'package:flutter/material.dart';

/// Editable grid of question-number -> answer-letter, seeded from OCR
/// output. Lets the teacher fix misreads before a score is treated as final.
class AnswerGridEditor extends StatefulWidget {
  final Map<String, String> initialAnswers;
  final int initialQuestionCount;
  final Map<String, String>? referenceAnswers; // if set, highlights correct/incorrect
  final ValueChanged<Map<String, String>> onChanged;

  const AnswerGridEditor({
    super.key,
    required this.initialAnswers,
    required this.initialQuestionCount,
    required this.onChanged,
    this.referenceAnswers,
  });

  @override
  State<AnswerGridEditor> createState() => _AnswerGridEditorState();
}

class _AnswerGridEditorState extends State<AnswerGridEditor> {
  late Map<String, String> _answers;
  late int _questionCount;
  late final TextEditingController _countController;

  static const _options = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _answers = Map.of(widget.initialAnswers);
    _questionCount = widget.initialQuestionCount;
    _countController = TextEditingController(text: _questionCount.toString());
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _setCount(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 1 || parsed > 300) return;
    setState(() => _questionCount = parsed);
    widget.onChanged(_answers);
  }

  void _select(String question, String? letter) {
    setState(() {
      if (letter == null) {
        _answers.remove(question);
      } else {
        _answers[question] = letter;
      }
    });
    widget.onChanged(_answers);
  }

  @override
  Widget build(BuildContext context) {
    final reference = widget.referenceAnswers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: TextField(
            controller: _countController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Total questions'),
            onChanged: _setCount,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_questionCount, (i) {
            final q = (i + 1).toString();
            final selected = _answers[q];
            final refAnswer = reference?[q];
            final showResult = reference != null && refAnswer != null;
            final isCorrect = showResult && selected == refAnswer;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: !showResult
                      ? Theme.of(context).dividerColor
                      : (isCorrect ? Colors.green : Colors.red),
                  width: showResult ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Q$q', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _options.map((letter) {
                      final isSelected = selected == letter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: Text(letter),
                          selected: isSelected,
                          onSelected: (sel) => _select(q, sel ? letter : null),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
