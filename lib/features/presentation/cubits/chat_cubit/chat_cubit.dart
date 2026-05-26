import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/features/domain/entities/src/chat/chat_entity.dart';
import 'package:learn_flutter/features/domain/usecases/src/chat/chat_usecase.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences_key.dart';

// States
abstract class ChatState {}

class ChatStateInitial extends ChatState {}

class ChatStateLoading extends ChatState {}

class ChatStateLoaded extends ChatState {
  final List<ChatEntity> comments;

  ChatStateLoaded({required this.comments});
}

class ChatStateError extends ChatState {
  final String message;

  ChatStateError({required this.message});
}

class ChatStateLiked extends ChatState {
  final List<ChatEntity> comments;

  ChatStateLiked({required this.comments});
}

// Cubit
class ChatCubit extends Cubit<ChatState> {
  final ChatUsecase chatUsecase;
  final AppSharedPreferences sharedPreferences;

  ChatCubit({
    required this.chatUsecase,
    required this.sharedPreferences,
  }) : super(ChatStateInitial());

  Future<void> loadComments(String questionId) async {
    emit(ChatStateLoading());

    final result = await chatUsecase.getCommentsByQuestion(questionId);
    result.fold(
      (error) => emit(ChatStateError(message: error.toString())),
      (comments) => emit(ChatStateLoaded(comments: comments)),
    );
  }

  Future<void> likeComment(String commentId) async {
    final String? userId =
        sharedPreferences.get(AppSharedPreferencesKey.userId) as String?;
    if (userId == null || userId.isEmpty) {
      emit(ChatStateError(message: 'User not logged in'));
      return;
    }

    final result = await chatUsecase.likeComment(commentId, userId);
    result.fold(
      (error) => emit(ChatStateError(message: error.toString())),
      (comments) => emit(ChatStateLiked(comments: comments)),
    );
  }

  void clearState() {
    emit(ChatStateInitial());
  }
}
