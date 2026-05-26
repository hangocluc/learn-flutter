import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:learn_flutter/features/presentation/pages/quiz_page/quiz_question.dart';
import 'package:learn_flutter/features/presentation/pages/quiz_page/quiz_summary.dart';
import 'package:learn_flutter/features/presentation/widgets/lesson_feedback_sheet.dart';
import '../../cubits/quiz_cubit/quiz_cubit.dart';
import '../../cubits/quiz_cubit/quiz_state.dart';
import '../../cubits/chat_cubit/chat_cubit.dart';
import '../../../domain/entities/src/lesson/lesson_entity.dart';

class QuizPage extends StatelessWidget {
  final QuizEntity quiz;
  final bool isFromQuiz;

  const QuizPage({super.key, required this.quiz, required this.isFromQuiz});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.instance.get<QuizCubit>()..startQuiz(quiz),
        ),
        BlocProvider(
          create: (context) => GetIt.instance.get<ChatCubit>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(quiz.name),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<QuizCubit, QuizState>(
          builder: (context, state) {
            if (state is QuizStateLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is QuizStateFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<QuizCubit>().startQuiz(quiz),
                        child: const Text('Thử lại'),
                      ),
                      LessonFeedbackErrorBanner(
                        params: LessonFeedbackParams(
                          lessonId: quiz.lessonId,
                          topicTitle: quiz.name,
                          defaultErrorType: 'quiz',
                          errorDetail: state.message,
                        ),
                        message: 'Quiz gặp lỗi? Gửi phản hồi để team kiểm tra.',
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is QuizStateQuestion) {
              return QuizQuestion(state: state);
            }

            if (state is QuizStateSummary) {
              return QuizSummary(
                state: state,
                isFromQuiz: isFromQuiz,
              );
            }

            return const Center(child: Text('Không có dự liệu'));
          },
        ),
      ),
    );
  }
}
