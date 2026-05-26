class LessonFeedbackRequestModel {
  const LessonFeedbackRequestModel({
    this.userId,
    this.lessonId,
    this.topicId,
    this.lessonTitle,
    this.topicTitle,
    required this.errorType,
    required this.message,
    this.errorDetail,
  });

  final String? userId;
  final String? lessonId;
  final String? topicId;
  final String? lessonTitle;
  final String? topicTitle;
  final String errorType;
  final String message;
  final String? errorDetail;

  Map<String, dynamic> toJson() => {
        if (userId != null) 'userId': userId,
        if (lessonId != null) 'lessonId': lessonId,
        if (topicId != null) 'topicId': topicId,
        if (lessonTitle != null) 'lessonTitle': lessonTitle,
        if (topicTitle != null) 'topicTitle': topicTitle,
        'errorType': errorType,
        'message': message,
        if (errorDetail != null && errorDetail!.isNotEmpty)
          'errorDetail': errorDetail,
      };
}
