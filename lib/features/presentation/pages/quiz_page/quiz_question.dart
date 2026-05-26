import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    required bool isCorrect,
    required VoidCallback onNext,
  }) {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      enableDrag: false,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                isCorrect ? '🎉 Đáp án chính xác!' : 'Đáp án sai !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 42),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // đóng bottom sheet
                  onNext(); // gọi callback chuyển câu tiếp theo
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCorrect ? Colors.green : Colors.red, // màu theo kết quả
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
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
        );
      },
    );
  }
}
