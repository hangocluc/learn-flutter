import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';
import 'package:learn_flutter/features/data/models/lesson_model/progress_request_model.dart';
import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences_key.dart';
import 'package:learn_flutter/core/storage/storage_manager.dart';
import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  final LessonService lessonService;
  final AppSharedPreferences sharedPreferences;

  QuizCubit({required this.lessonService, required this.sharedPreferences})
      : super(QuizStateInitial());

  void startQuiz(QuizEntity quiz) {
    emit(QuizStateQuestion(
      quiz: quiz,
      currentQuestionIndex: 0,
      userAnswers: List.filled(quiz.questions.length, null),
      isLastQuestion: quiz.questions.length == 1,
    ));
  }

  void selectAnswer(String answer) {
    final currentState = state;
    if (currentState is QuizStateQuestion) {
      final newAnswers = List<String?>.from(currentState.userAnswers);
      newAnswers[currentState.currentQuestionIndex] = answer;

      emit(QuizStateQuestion(
        quiz: currentState.quiz,
        currentQuestionIndex: currentState.currentQuestionIndex,
        userAnswers: newAnswers,
        isLastQuestion: currentState.isLastQuestion,
      ));
    }
  }

  void nextQuestion() {
    final currentState = state;
    if (currentState is QuizStateQuestion) {
      final nextIndex = currentState.currentQuestionIndex + 1;
      if (nextIndex < currentState.quiz.questions.length) {
        emit(QuizStateQuestion(
          quiz: currentState.quiz,
          currentQuestionIndex: nextIndex,
          userAnswers: currentState.userAnswers,
          isLastQuestion: nextIndex == currentState.quiz.questions.length - 1,
        ));
      } else {
        _finishQuiz(currentState.quiz, currentState.userAnswers);
      }
    }
  }

  void _finishQuiz(QuizEntity quiz, List<String?> userAnswers) {
    int correctAnswers = 0;

    for (int i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      final userAnswer = userAnswers[i];

      if (userAnswer != null && isCorrectAnswer(question, userAnswer)) {
        correctAnswers++;
      }
    }

    final score = (correctAnswers / quiz.questions.length) * 100;
    _submitProgress(quiz.lessonId, score.round());

    emit(QuizStateSummary(
      quiz: quiz,
      userAnswers: userAnswers,
      correctAnswers: correctAnswers,
      score: score,
    ));
  }

  Future<void> _submitProgress(String lessonId, int mark) async {
    try {
      final String? userId =
          sharedPreferences.get(AppSharedPreferencesKey.userId) as String?;
      String? effectiveUserId = userId;
      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        // Fallback to StorageManager if not set in shared preferences
        effectiveUserId = await StorageManager.getUserId();
      }
      if (effectiveUserId == null || effectiveUserId.isEmpty) {
        // ignore: avoid_print
        print('updateProcess skipped: empty userId');
        return;
      }
      // Debug log request payload
      // ignore: avoid_print
      print(
          'updateProcess request -> userId=$effectiveUserId, lessonId=$lessonId, mark=$mark');
      final request = ProgressRequestModel(
        userId: effectiveUserId,
        lessonId: lessonId,
        status: 1,
        quizStatus: 1,
        quizMarked: mark,
      );
      await lessonService.updateProcess(request);
      // ignore: avoid_print
      print('updateProcess success');
    } catch (e) {
      // Log error to help diagnose API failures
      // ignore: avoid_print
      print('updateProcess failed: ' + e.toString());
    }
  }

  bool isCorrectAnswer(QuestionEntity question, String userAnswer) {
    // 1) Try numeric index (API may return "1".."n")
    try {
      final correctIndex = int.parse(question.correctAnswer) - 1;
      if (correctIndex >= 0 && correctIndex < question.answers.length) {
        if (userAnswer == question.answers[correctIndex]) return true;
      }
    } catch (_) {}

    // 2) Fallback: compare by text (API may return exact answer text)
    normalized(String s) => s.trim().toLowerCase();
    final target = normalized(question.correctAnswer);
    if (target.isNotEmpty) {
      if (normalized(userAnswer) == target) return true;
    }
    return false;
  }

  void restartQuiz() {
    emit(QuizStateInitial());
  }
}
