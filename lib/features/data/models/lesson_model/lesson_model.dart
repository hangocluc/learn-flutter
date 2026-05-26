import 'package:json_annotation/json_annotation.dart';
import 'package:learn_flutter/features/data/models/quiz_model/topic_model.dart';
import '../quiz_model/quiz_model.dart';

part 'lesson_model.g.dart';

@JsonSerializable()
class LessonModel {
  @JsonKey(name: '_id')
  final String id;
  final String title;
  final int totalTopic;
  @JsonKey(name: 'count')
  final int learnCount;
  final QuizModel? quiz;
  @JsonKey(name: 'topic')
  final List<Topics> topics;

  const LessonModel({
    required this.id,
    required this.title,
    required this.totalTopic,
    required this.learnCount,
    this.quiz,
    required this.topics,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);
  Map<String, dynamic> toJson() => _$LessonModelToJson(this);
}
