class SystemFeedbackRequestModel {
  const SystemFeedbackRequestModel({
    this.userId,
    required this.category,
    required this.message,
    this.appVersion,
    this.platform,
  });

  final String? userId;
  final String category;
  final String message;
  final String? appVersion;
  final String? platform;

  Map<String, dynamic> toJson() => {
        if (userId != null) 'userId': userId,
        'category': category,
        'message': message,
        if (appVersion != null) 'appVersion': appVersion,
        if (platform != null) 'platform': platform,
      };
}
