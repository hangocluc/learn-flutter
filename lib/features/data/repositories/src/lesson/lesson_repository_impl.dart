import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';
import 'package:learn_flutter/features/domain/repositories/src/lesson/lesson_repository.dart';

import '../../../../../core/base/src/api_response.dart';
import 'package:learn_flutter/features/data/models/quiz_model/quiz_model.dart';
import 'package:learn_flutter/features/data/models/quiz_model/question_model.dart';

class LessonRepositoryImpl implements LessonRepository {
  final LessonService lessonService;

  LessonRepositoryImpl({required this.lessonService});

  @override
  Future<ApiResponse<List<LessonEntity>>?> getAllLessons() async {
    try {
      final response = await lessonService.getAllLessons();
      if (response.isSuccessResponse && response.data != null) {
        final entities = response.data!
            .map((m) => LessonEntity(
                  id: m.id,
                  title: m.title,
                  totalTopic: m.totalTopic,
                  learnCount: m.learnCount,
                  quiz: m.quiz != null ? _mapQuizModelToEntity(m.quiz!) : null,
                  topics: m.topics,
                ))
            .toList();
        return ApiResponse(entities, 200, 'Success', true);
      } else {
        throw Exception(response.message);
      }
    } catch (error) {
      rethrow;
    }
  }

  QuizEntity _mapQuizModelToEntity(QuizModel model) {
    return QuizEntity(
      id: model.id,
      lessonId: model.lessonId,
      name: model.name,
      questions:
          model.questions.map((q) => _mapQuestionModelToEntity(q)).toList(),
    );
  }

  QuestionEntity _mapQuestionModelToEntity(QuestionModel model) {
    return QuestionEntity(
      id: model.id,
      quizId: model.quizId,
      stt: model.stt,
      content: model.content,
      answers: model.answers,
      correctAnswer: model.correctAnswer,
    );
  }
}
