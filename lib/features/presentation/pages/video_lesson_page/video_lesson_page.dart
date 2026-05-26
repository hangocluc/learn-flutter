import 'package:flutter/material.dart';
import 'package:learn_flutter/features/presentation/widgets/lesson_feedback_sheet.dart';
import 'package:video_player/video_player.dart';

/// Plays a lesson video from a remote URL or a bundled asset under [assets/videos/].
class VideoLessonPage extends StatefulWidget {
  const VideoLessonPage({
    super.key,
    required this.title,
    required this.source,
  });

  final String title;
  final String source;

  @override
  State<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends State<VideoLessonPage> {
  late final VideoPlayerController _controller;
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.source.trim());
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = null;
      });
      _controller.play();
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _error = e.toString();
      });
    });
  }

  static VideoPlayerController _buildController(String spec) {
    if (spec.startsWith('http://') || spec.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(spec));
    }
    return VideoPlayerController.asset(spec);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _error != null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    LessonFeedbackErrorBanner(
                      params: LessonFeedbackParams(
                        topicTitle: widget.title,
                        defaultErrorType: 'video',
                        errorDetail: _error,
                      ),
                      message: 'Video không phát được? Gửi phản hồi cho team.',
                    ),
                  ],
                ),
              ),
            )
          : !_ready
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio:
                                  _controller.value.aspectRatio == 0
                                      ? 16 / 9
                                      : _controller.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(_controller),
                                  Material(
                                    color: Colors.black26,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      iconSize: 56,
                                      color: Colors.white,
                                      icon: Icon(
                                        _controller.value.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                      onPressed: () {
                                        if (_controller.value.isPlaying) {
                                          _controller.pause();
                                        } else {
                                          _controller.play();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
