import 'package:dartz/dartz.dart';
import 'package:learn_flutter/features/domain/entities/src/chat/chat_entity.dart';
import 'package:learn_flutter/features/domain/repositories/src/chat/chat_repository.dart';

class ChatUsecase {
  final ChatRepository repository;

  ChatUsecase({required this.repository});

  Future<Either<Exception, List<ChatEntity>>> getCommentsByQuestion(
      String questionId) async {
    try {
      final response = await repository.getCommentsByQuestion(questionId);
      if (response?.success == true && response?.data != null) {
        return Right(response!.data!);
      }
      return Left(Exception(response?.message ?? 'Failed to get comments'));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  Future<Either<Exception, List<ChatEntity>>> likeComment(
      String commentId, String userId) async {
    try {
      final response = await repository.likeComment(commentId, userId);
      if (response?.success == true && response?.data != null) {
        return Right(response!.data!);
      }
      return Left(Exception(response?.message ?? 'Failed to like comment'));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
