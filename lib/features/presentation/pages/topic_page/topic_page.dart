import 'package:flutter/material.dart';
import 'package:learn_flutter/features/presentation/pages/topic_lesson_detail_page/topic_lesson_detail_page.dart';
import 'package:learn_flutter/features/presentation/widgets/topic_video_card.dart';
import '../../../domain/entities/src/lesson/lesson_entity.dart';

class TopicPage extends StatefulWidget {
  const TopicPage({super.key, required this.lesson, required this.onTap});
  final LessonEntity lesson;
  final VoidCallback onTap;

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final topics = widget.lesson.topics;
    if (topics.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.lesson.title)),
        body: const Center(child: Text('Chưa có nội dung topic')),
      );
    }

    final current = topics[currentIndex];
    final isLast = currentIndex == topics.length - 1;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lesson.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.35),
      body: Column(
        children: [
          StepperWithArrows(
            topicCount: topics.length,
            currentIndex: currentIndex,
            onStepTap: (idx) => setState(() => currentIndex = idx),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (current.hasVideo) ...[
                    TopicVideoCard(
                      videoLink: current.videoLink!,
                      topicTitle: current.title ?? 'Video bài học',
                    ),
                    const SizedBox(height: 16),
                  ],
                  Material(
                    color: Theme.of(context).cardTheme.color ?? scheme.surface,
                    elevation: 0,
                    shadowColor: Colors.black.withOpacity(0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: scheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => TopicLessonDetailPage(
                              topic: current,
                              topicIndex: currentIndex,
                              lessonTitle: widget.lesson.title,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                      'Topic ${currentIndex + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    current.title ?? 'Bài học',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Chạm để đọc nội dung bài học',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
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
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: isLast
                        ? FilledButton.icon(
                            onPressed: widget.onTap,
                            icon: const Icon(Icons.quiz_outlined),
                            label: const Text('Làm Quiz'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          )
                        : FilledButton(
                            onPressed: () =>
                                setState(() => currentIndex += 1),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Tiếp tục'),
                          ),
                  ),
                  if (!isLast)
                    TextButton(
                      onPressed: widget.onTap,
                      child: const Text(
                        'Làm Quiz',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StepperWithArrows extends StatefulWidget {
  final int topicCount;
  final int currentIndex;
  final Function(int) onStepTap;

  const StepperWithArrows({
    super.key,
    required this.topicCount,
    required this.currentIndex,
    required this.onStepTap,
  });

  @override
  State<StepperWithArrows> createState() => _StepperWithArrowsState();
}

class _StepperWithArrowsState extends State<StepperWithArrows> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: widget.currentIndex > 0
                  ? () => widget.onStepTap(widget.currentIndex - 1)
                  : null,
            ),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.topicCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final isActive = idx == widget.currentIndex;
                    return GestureDetector(
                      onTap: () => widget.onStepTap(idx),
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? scheme.primary
                                  : scheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Topic ${idx + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isActive
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              onPressed: widget.currentIndex < widget.topicCount - 1
                  ? () => widget.onStepTap(widget.currentIndex + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
