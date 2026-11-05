import 'package:flutter/material.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/utils/lesson_progress_utils.dart';
import 'package:learn_flutter/features/data/models/quiz_model/topic_model.dart';
import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';
import 'package:learn_flutter/features/presentation/widgets/lesson_feedback_sheet.dart';
import 'package:learn_flutter/features/presentation/widgets/topic_video_card.dart';
import 'package:learn_flutter/main.dart';

/// Full lesson content for one topic (opened from the lessons list).
class TopicLessonDetailPage extends StatefulWidget {
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
  State<TopicLessonDetailPage> createState() => _TopicLessonDetailPageState();
}

class _TopicLessonDetailPageState extends State<TopicLessonDetailPage> {
  static const _scrollBottomThreshold = 48.0;

  late final ScrollController _scrollController;
  bool _completionRecorded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollCompletion();
      // Re-check after layout settles (e.g. video card / images change the
      // scroll extent) so short topics that fit on screen still get recorded.
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _checkScrollCompletion();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() => _checkScrollCompletion();

  void _checkScrollCompletion() {
    if (_completionRecorded || _isSaving || !_scrollController.hasClients) {
      return;
    }

    final content = widget.topic.content?.trim() ?? '';
    if (content.isEmpty) return;

    final position = _scrollController.position;
    final reachedBottom = position.maxScrollExtent <= _scrollBottomThreshold ||
        position.pixels >= position.maxScrollExtent - _scrollBottomThreshold;

    if (reachedBottom) {
      _markTopicCompleted();
    }
  }

  Future<void> _markTopicCompleted() async {
    final topicId = widget.topic.sId;
    final lessonId = widget.lessonId ?? widget.topic.lessonId;
    if (topicId == null ||
        topicId.isEmpty ||
        lessonId == null ||
        lessonId.isEmpty) {
      return;
    }

    _isSaving = true;
    final saved = await LessonProgressUtils.markTopicCompleted(
      lessonService: getIt.get<LessonService>(),
      sharedPreferences: getIt.get<AppSharedPreferences>(),
      lessonId: lessonId,
      topicId: topicId,
    );
    _isSaving = false;

    if (saved) {
      _completionRecorded = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn thành bài học ✓'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    // On failure `_completionRecorded` stays false, so a later scroll/re-check
    // will retry saving the progress.
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = widget.topic.content?.trim() ?? '';
    final feedbackParams = LessonFeedbackParams(
      lessonId: widget.lessonId ?? widget.topic.lessonId,
      topicId: widget.topic.sId,
      lessonTitle: widget.lessonTitle,
      topicTitle: widget.topic.title,
      defaultErrorType: content.isEmpty ? 'content' : 'other',
      errorDetail: content.isEmpty ? 'Chưa có nội dung bài học' : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic.title ?? 'Chi tiết bài học',
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
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.topic.hasVideo) ...[
              TopicVideoCard(
                videoLink: widget.topic.videoLink!,
                topicTitle: widget.topic.title ?? 'Video bài học',
                lessonId: widget.lessonId ?? widget.topic.lessonId,
                topicId: widget.topic.sId,
                lessonTitle: widget.lessonTitle,
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
                    if (widget.lessonTitle.isNotEmpty) ...[
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
                          widget.lessonTitle,
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
                      widget.topic.title ?? '',
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
