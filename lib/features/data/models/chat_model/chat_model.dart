import 'package:json_annotation/json_annotation.dart';
import 'package:learn_flutter/features/domain/entities/src/chat/chat_entity.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class ChatModel {
  @JsonKey(name: '_id')
  final String id;
  @JsonKey(name: 'userId')
  final String userId;
  @JsonKey(name: 'questionId')
  final String questionId;
  @JsonKey(name: 'quizId')
  final String quizId;
  @JsonKey(name: 'username')
  final String username;
  @JsonKey(name: 'message')
  final String message;
  @JsonKey(name: 'imageUrl')
  final String? imageUrl;
  @JsonKey(name: 'vote')
  final int vote;
  @JsonKey(name: 'userLiked')
  final List<String> userLiked;

  const ChatModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.quizId,
    required this.username,
    required this.message,
    this.imageUrl,
    required this.vote,
    required this.userLiked,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  ChatEntity toEntity() {
    return ChatEntity(
      id: id,
      userId: userId,
      questionId: questionId,
      quizId: quizId,
      username: username,
      message: message,
      imageUrl: imageUrl,
      vote: vote,
      userLiked: userLiked,
    );
  }

  factory ChatModel.fromEntity(ChatEntity entity) {
    return ChatModel(
      id: entity.id,
      userId: entity.userId,
      questionId: entity.questionId,
      quizId: entity.quizId,
      username: entity.username,
      message: entity.message,
      imageUrl: entity.imageUrl,
      vote: entity.vote,
      userLiked: entity.userLiked,
    );
  }
}
