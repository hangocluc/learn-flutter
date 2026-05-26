import 'package:learn_flutter/core/base/src/api_response.dart';
import 'package:learn_flutter/features/data/providers/chat_service/chat_service.dart';
import 'package:learn_flutter/features/domain/repositories/src/chat/chat_repository.dart';
import 'package:learn_flutter/features/domain/entities/src/chat/chat_entity.dart';
// Removed wrong/duplicate ApiResponse import

class ChatRepositoryImpl implements ChatRepository {
  final ChatService chatService;

  ChatRepositoryImpl({required this.chatService});

  @override
  Future<ApiResponse<List<ChatEntity>>?> getCommentsByQuestion(
      String questionId) async {
    try {
      final response = await chatService.getCommentsByQuestion(questionId);
      if (response.success == true && response.data != null) {
        final entities = response.data!
            .map((model) => (model).toEntity())
            .toList();
        return ApiResponse(entities, 200, 'Success', true);
      } else {
        throw Exception(response.message ?? 'Failed to get comments');
      }
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<ApiResponse<List<ChatEntity>>?> likeComment(
      String commentId, String userId) async {
    try {
      final response = await chatService.likeComment(commentId, userId);
      if (response.success == true && response.data != null) {
        final entities = response.data!
            .map((model) => (model).toEntity())
            .toList();
        return ApiResponse(entities, 200, 'Success', true);
      } else {
        throw Exception(response.message ?? 'Failed to like comment');
      }
    } catch (error) {
      rethrow;
    }
  }
}
