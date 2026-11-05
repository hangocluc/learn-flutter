import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/features/data/services/ai_chat_service.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';
import '../../cubits/quiz_cubit/quiz_cubit.dart';
import '../../cubits/quiz_cubit/quiz_state.dart';

class QuizQuestion extends StatefulWidget {
  const QuizQuestion({super.key, required this.state});
  final QuizStateQuestion state;

  @override
  State<QuizQuestion> createState() => _QuizQuestionState();
}

class _QuizQuestionState extends State<QuizQuestion> {
  @override
  Widget build(BuildContext context) {
    final question =
        widget.state.quiz.questions[widget.state.currentQuestionIndex];
    final selectedAnswer =
        widget.state.userAnswers[widget.state.currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (widget.state.currentQuestionIndex + 1) /
                widget.state.quiz.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),

          // Question counter
          Text(
            'Câu hỏi ${widget.state.currentQuestionIndex + 1} trên ${widget.state.quiz.questions.length}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              question.content,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: question.answers.length,
              itemBuilder: (context, index) {
                final answer = question.answers[index];
                final isSelected = selectedAnswer == answer;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      context.read<QuizCubit>().selectAnswer(answer);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue[600]!
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.blue[600]
                                  : Colors.grey[300],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              answer,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.blue[800]
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Next/Finish button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16, bottom: 24),
            child: ElevatedButton(
              onPressed: selectedAnswer == null
                  ? null
                  : () {
                      final cubit = context.read<QuizCubit>();
                      showResultBottomSheet(
                        context,
                        question: question,
                        isCorrect: cubit.isCorrectAnswer(
                          question,
                          selectedAnswer,
                        ),
                        onNext: () {
                          cubit.nextQuestion();
                        },
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Chọn',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showResultBottomSheet(
    BuildContext context, {
    required QuestionEntity question,
    required bool isCorrect,
    required VoidCallback onNext,
  }) {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ResultBottomSheet(
        question: question,
        isCorrect: isCorrect,
        onNext: onNext,
      ),
    );
  }
}

class _ResultBottomSheet extends StatefulWidget {
  const _ResultBottomSheet({
    required this.question,
    required this.isCorrect,
    required this.onNext,
  });

  final QuestionEntity question;
  final bool isCorrect;
  final VoidCallback onNext;

  @override
  State<_ResultBottomSheet> createState() => _ResultBottomSheetState();
}

class _ResultBottomSheetState extends State<_ResultBottomSheet> {
  final _ai = AiChatService();
  String? _hint;
  bool _loadingHint = false;
  String? _hintError;

  Future<void> _loadHint() async {
    setState(() {
      _loadingHint = true;
      _hintError = null;
    });
    try {
      final ai = _ai;
      final prompt =
          'Câu hỏi quiz: "${widget.question.content}"\n'
          'Các đáp án: ${widget.question.answers.join(", ")}\n\n'
          'Tôi đã trả lời sai. Hãy giải thích ngắn gọn gợi ý để tôi hiểu '
          'đúng hướng (đừng nói thẳng đáp án, chỉ gợi ý để tôi tự tìm ra).';
      final hint = await ai.sendMessage(userMessage: prompt);
      if (mounted) setState(() => _hint = hint);
    } catch (e) {
      if (mounted) setState(() => _hintError = 'Không lấy được gợi ý: $e');
    } finally {
      if (mounted) setState(() => _loadingHint = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isCorrect ? Icons.check_circle : Icons.cancel,
                color: widget.isCorrect ? Colors.green : Colors.red,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                widget.isCorrect ? '🎉 Đáp án chính xác!' : 'Đáp án sai!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Phần gợi ý AI — chỉ hiện khi sai
              if (!widget.isCorrect) ...[
                const SizedBox(height: 20),
                if (_hint != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb,
                                color: Colors.amber[700], size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Gợi ý từ AI',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_hint!, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ] else if (_hintError != null) ...[
                  Text(_hintError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _loadingHint ? null : _loadHint,
                    icon: _loadingHint
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lightbulb_outline),
                    label: Text(_loadingHint ? 'Đang lấy gợi ý...' : 'Gợi ý từ AI'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      foregroundColor: Colors.amber[800],
                      side: BorderSide(color: Colors.amber[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNext();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isCorrect ? Colors.green : Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
