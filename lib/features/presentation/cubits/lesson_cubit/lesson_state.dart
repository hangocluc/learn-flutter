import 'package:equatable/equatable.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';

sealed class LessonState extends Equatable {
  const LessonState();

  @override
  List<Object?> get props => [];
}

class LessonStateInitial extends LessonState {}

class LessonStateLoading extends LessonState {}

class LessonStateFailure extends LessonState {
  final String message;
  const LessonStateFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class LessonStateSuccess extends LessonState {
  final List<LessonEntity> lessons;
  const LessonStateSuccess(this.lessons);

  @override
  List<Object?> get props => [lessons];
}
