import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:learn_java/common/utils/video_link_utils.dart';
import 'package:learn_java/features/presentation/pages/youtube_video_page/youtube_video_page.dart';

/// Video lesson CTA for a topic with [videoLink].
class TopicVideoCard extends StatelessWidget {
  const TopicVideoCard({
    super.key,
    required this.videoLink,
    required this.topicTitle,
  });

  final String videoLink;
  final String topicTitle;

  @override
  Widget build(BuildContext context) {
    if (!VideoLinkUtils.hasPlayableVideo(videoLink)) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final thumb = VideoLinkUtils.youtubeThumbnailUrl(videoLink);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => YoutubeVideoPage(
                title: topicTitle,
                videoLink: videoLink,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.ondemand_video_rounded,
                            size: 48,
                            color: scheme.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.45),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 22,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video bài học',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Xem video để học theo nội dung topic này',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
