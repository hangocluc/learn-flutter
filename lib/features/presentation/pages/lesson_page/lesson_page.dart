import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences_key.dart';
import 'package:learn_flutter/features/data/models/lesson_model/progress_request_model.dart';
import 'package:learn_flutter/features/data/models/quiz_model/topic_model.dart';
import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';
import 'package:learn_flutter/features/domain/entities/src/lesson/lesson_entity.dart';
import 'package:learn_flutter/features/presentation/pages/topic_lesson_detail_page/topic_lesson_detail_page.dart';
import 'package:learn_flutter/features/presentation/pages/youtube_video_page/youtube_video_page.dart';
import 'package:learn_flutter/features/presentation/widgets/lesson_feedback_sheet.dart';
import 'package:learn_flutter/main.dart';
import '../../cubits/lesson_cubit/lesson_cubit.dart';
import '../../cubits/lesson_cubit/lesson_state.dart';
import '../quiz_page/quiz_page.dart';

class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  late final LessonService _lessonService;
  late final AppSharedPreferences _sharedPreferences;

  @override
  void initState() {
    super.initState();
    _lessonService = getIt.get<LessonService>();
    _sharedPreferences = getIt.get<AppSharedPreferences>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonCubit>().loadLessons();
    });
  }

  Widget _buildList(List<LessonEntity> lessons) {
    if (lessons.isEmpty) {
      return const Center(child: Text('No lessons'));
    }
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<LessonCubit>().loadLessons();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: lessons.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) =>
            _buildChapterTile(lessons[index], index),
      ),
    );
  }

  Widget _buildChapterTile(LessonEntity lesson, int chapterIndex) {
    final hasVideoLesson = lesson.topics.any((t) => t.hasVideo);
    final scheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withOpacity(0.12),
          foregroundColor: scheme.primary,
          child: Text(
            '${chapterIndex + 1}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Topics: ${lesson.totalTopic} • Quiz: ${lesson.quiz != null ? 1 : 0}'
          '${hasVideoLesson ? ' • Có video' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasVideoLesson)
              Icon(
                Icons.play_circle_outline,
                color: scheme.primary,
                size: 22,
              ),
            if (lesson.quiz != null)
              IconButton(
                icon: const Icon(Icons.quiz_outlined),
                tooltip: 'Làm Quiz',
                onPressed: () => _startQuiz(context, lesson.quiz!, true),
              ),
          ],
        ),
        children: lesson.topics.isEmpty
            ? const [
                ListTile(
                  dense: true,
                  title: Text('Chưa có bài học trong chương này'),
                ),
              ]
            : [
                for (var i = 0; i < lesson.topics.length; i++)
                  _buildTopicTile(
                    lesson: lesson,
                    topic: lesson.topics[i],
                    topicIndex: i,
                  ),
                if (lesson.quiz != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _startQuiz(context, lesson.quiz!, false),
                        icon: const Icon(Icons.quiz_outlined, size: 20),
                        label: const Text('Làm Quiz chương này'),
                      ),
                    ),
                  ),
              ],
      ),
    );
  }

  Widget _buildTopicTile({
    required LessonEntity lesson,
    required Topics topic,
    required int topicIndex,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openTopicLesson(lesson, topic, topicIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title ?? 'Bài ${topicIndex + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chạm để đọc nội dung bài học',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (topic.hasVideo)
                  IconButton(
                    icon: Icon(
                      Icons.play_circle_outline,
                      color: scheme.primary,
                    ),
                    tooltip: 'Xem video',
                    onPressed: () => _openVideo(lesson, topic),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopicLesson(
    LessonEntity lesson,
    Topics topic,
    int topicIndex,
  ) {
    _markLessonStarted(lesson.id);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TopicLessonDetailPage(
          topic: topic,
          topicIndex: topicIndex,
          lessonTitle: lesson.title,
          lessonId: lesson.id,
        ),
      ),
    );
  }

  void _openVideo(LessonEntity lesson, Topics topic) {
    final link = topic.videoLink?.trim();
    if (link == null || link.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => YoutubeVideoPage(
          title: topic.title ?? 'Video bài học',
          videoLink: link,
          lessonId: lesson.id,
          topicId: topic.sId,
          lessonTitle: lesson.title,
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, QuizEntity quiz, bool isFromQuiz) {
    _markLessonStarted(quiz.lessonId);
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => QuizPage(
          quiz: quiz,
          isFromQuiz: isFromQuiz,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        context.read<LessonCubit>().loadLessons();
      }
    });
  }

  Future<void> _markLessonStarted(String lessonId) async {
    try {
      final String? userId =
          _sharedPreferences.get(AppSharedPreferencesKey.userId) as String?;
      if (userId == null || userId.isEmpty) return;
      final request = ProgressRequestModel(
        userId: userId,
        lessonId: lessonId,
        status: 0,
        quizStatus: 0,
      );
      await _lessonService.updateProcess(request);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
      ),
      body: BlocBuilder<LessonCubit, LessonState>(
        builder: (context, state) {
          if (state is LessonStateLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LessonStateFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<LessonCubit>().loadLessons(),
                      child: const Text('Thử lại'),
                    ),
                    LessonFeedbackErrorBanner(
                      params: LessonFeedbackParams(
                        defaultErrorType: 'other',
                        errorDetail: state.message,
                      ),
                      message: 'Không tải được danh sách bài học?',
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is LessonStateSuccess) {
            return _buildList(state.lessons);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
