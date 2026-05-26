import 'package:dartz/dartz.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';
import 'package:learn_flutter/features/domain/repositories/src/lesson/lesson_repository.dart';
import '../../../../core/base/src/base_usecase.dart';

class LessonUseCase extends BaseUseCase<List<LessonEntity>, NoParams> {
  final LessonRepository repository;

  LessonUseCase({required this.repository});

  @override
  Future<Either<Exception, List<LessonEntity>>> call(NoParams params) async {
    try {
      final response = await repository.getAllLessons();
      if (response != null &&
          response.isSuccessResponse &&
          response.data != null) {
        return Right(response.data!);
      }
      return Left(Exception(response?.message ?? 'Failed to load lessons'));
    } on Exception catch (error) {
      return Left(error);
    }
  }
}
