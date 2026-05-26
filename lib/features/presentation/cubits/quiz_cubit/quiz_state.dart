import 'package:equatable/equatable.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';

sealed class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizStateInitial extends QuizState {}

class QuizStateLoading extends QuizState {}

class QuizStateFailure extends QuizState {
  final String message;
  const QuizStateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class QuizStateQuestion extends QuizState {
  final QuizEntity quiz;
  final int currentQuestionIndex;
  final List<String?> userAnswers;
  final bool isLastQuestion;

  const QuizStateQuestion({
    required this.quiz,
    required this.currentQuestionIndex,
    required this.userAnswers,
    required this.isLastQuestion,
  });

  @override
  List<Object?> get props =>
      [quiz, currentQuestionIndex, userAnswers, isLastQuestion];
}

class QuizStateSummary extends QuizState {
  final QuizEntity quiz;
  final List<String?> userAnswers;
  final int correctAnswers;
  final double score;

  const QuizStateSummary({
    required this.quiz,
    required this.userAnswers,
    required this.correctAnswers,
    required this.score,
  });

  @override
  List<Object?> get props => [quiz, userAnswers, correctAnswers, score];
}
