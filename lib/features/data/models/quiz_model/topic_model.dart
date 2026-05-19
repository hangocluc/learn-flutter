class Topics {
  String? sId;
  String? lessonId;
  String? title;
  String? content;
  String? videoLink;

  Topics({
    this.sId,
    this.lessonId,
    this.title,
    this.content,
    this.videoLink,
  });

  bool get hasVideo =>
      videoLink != null && videoLink!.trim().isNotEmpty;

  Topics.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    lessonId = json['lessonId'];
    title = json['title'];
    content = json['content'];
    videoLink = json['videoLink'] as String? ??
        json['video_link'] as String? ??
        json['video'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['lessonId'] = lessonId;
    data['title'] = title;
    data['content'] = content;
    data['videoLink'] = videoLink;
    return data;
  }
}
