import 'package:flutter/material.dart';
import 'package:learn_flutter/features/data/models/quiz_model/topic_model.dart';
import 'package:learn_flutter/features/presentation/widgets/lesson_feedback_sheet.dart';
import 'package:learn_flutter/features/presentation/widgets/topic_video_card.dart';

/// Full lesson content for one topic (opened from the lessons list).
class TopicLessonDetailPage extends StatelessWidget {
  const TopicLessonDetailPage({
    super.key,
    required this.topic,
    required this.topicIndex,
    required this.lessonTitle,
    this.lessonId,
  });

  final Topics topic;
  final int topicIndex;
  final String lessonTitle;
  final String? lessonId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = topic.content?.trim() ?? '';
    final feedbackParams = LessonFeedbackParams(
      lessonId: lessonId ?? topic.lessonId,
      topicId: topic.sId,
      lessonTitle: lessonTitle,
      topicTitle: topic.title,
      defaultErrorType: content.isEmpty ? 'content' : 'other',
      errorDetail: content.isEmpty ? 'Chưa có nội dung bài học' : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          topic.title ?? 'Chi tiết bài học',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Báo lỗi bài học',
            onPressed: () => LessonFeedbackSheet.showLesson(
              context,
              params: feedbackParams,
            ),
            icon: const Icon(Icons.feedback_outlined),
          ),
        ],
      ),
      backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.35),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (topic.hasVideo) ...[
              TopicVideoCard(
                videoLink: topic.videoLink!,
                topicTitle: topic.title ?? 'Video bài học',
                lessonId: lessonId ?? topic.lessonId,
                topicId: topic.sId,
                lessonTitle: lessonTitle,
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? scheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lessonTitle.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lessonTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      topic.title ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 20),
                    if (content.isEmpty) ...[
                      Text(
                        'Chưa có nội dung bài học.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      LessonFeedbackErrorBanner(
                        params: feedbackParams,
                        message:
                            'Bài học này chưa có nội dung. Bạn có thể gửi phản hồi để team bổ sung.',
                      ),
                    ] else
                      SelectableText(
                        content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              color: scheme.onSurface.withOpacity(0.9),
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
