import 'package:learn_flutter/features/domain/entities/src/chat/chat_entity.dart';
import 'package:learn_flutter/core/base/src/api_response.dart';

abstract class ChatRepository {
  Future<ApiResponse<List<ChatEntity>>?> getCommentsByQuestion(
      String questionId);
  Future<ApiResponse<List<ChatEntity>>?> likeComment(
      String commentId, String userId);
}
