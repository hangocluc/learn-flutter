import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_flutter/common/utils/video_link_utils.dart';
import 'package:learn_flutter/features/presentation/widgets/lesson_feedback_sheet.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// In-app YouTube player for topic [videoLink].
class YoutubeVideoPage extends StatefulWidget {
  const YoutubeVideoPage({
    super.key,
    required this.title,
    required this.videoLink,
    this.lessonId,
    this.topicId,
    this.lessonTitle,
  });

  final String title;
  final String videoLink;
  final String? lessonId;
  final String? topicId;
  final String? lessonTitle;

  @override
  State<YoutubeVideoPage> createState() => _YoutubeVideoPageState();
}

class _YoutubeVideoPageState extends State<YoutubeVideoPage>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _loading = true;
  bool _embedFailed = false;
  bool _openingExternal = false;
  late final String? _videoId;
  late final String? _watchUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoId = VideoLinkUtils.youtubeVideoId(widget.videoLink);
    _watchUrl = VideoLinkUtils.youtubeWatchUrl(widget.videoLink);

    if (_videoId == null) {
      _loading = false;
      _embedFailed = true;
      return;
    }

    _initWebView(_videoId);
  }

  void _initWebView(String videoId) {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _embedFailed = true;
            });
          },
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadHtmlString(
      VideoLinkUtils.embedHtmlForVideoId(videoId),
      baseUrl: 'https://www.youtube-nocookie.com',
    );

    _controller = controller;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final videoId = _videoId;
    if (state == AppLifecycleState.resumed &&
        videoId != null &&
        !_embedFailed &&
        _controller != null) {
      _controller!.loadHtmlString(
        VideoLinkUtils.embedHtmlForVideoId(videoId),
        baseUrl: 'https://www.youtube-nocookie.com',
      );
    }
  }

  Future<void> _openInYoutubeApp() async {
    if (_openingExternal) return;

    setState(() => _openingExternal = true);
    final opened = await VideoLinkUtils.launchYoutubeVideo(widget.videoLink);
    if (!mounted) return;
    setState(() => _openingExternal = false);

    if (opened) return;

    final shortUrl = VideoLinkUtils.youtubeShortUrl(widget.videoLink);
    final fallbackLink = shortUrl.isNotEmpty
        ? shortUrl
        : (_watchUrl ?? widget.videoLink.trim());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Không mở được YouTube'),
        content: SelectableText(
          'Thử mở link sau trong trình duyệt hoặc app YouTube:\n\n$fallbackLink',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: fallbackLink));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép link video')),
              );
            },
            child: const Text('Sao chép link'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_watchUrl != null && _watchUrl.isNotEmpty)
            IconButton(
              tooltip: 'Mở YouTube',
              onPressed: _openingExternal ? null : _openInYoutubeApp,
              icon: _openingExternal
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.open_in_new_rounded),
            ),
        ],
      ),
      body: _videoId == null || _embedFailed
          ? _buildError(
              context,
              _videoId == null
                  ? 'Link video không hợp lệ.'
                  : 'Không phát được trong app (lỗi 153).\n'
                      'Nhấn nút bên dưới để xem trên YouTube.',
              showOpenButton: _watchUrl != null,
              errorDetail: _videoId == null
                  ? 'Link: ${widget.videoLink}'
                  : 'YouTube embed failed — videoId: $_videoId',
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
    );
  }

  Widget _buildError(
    BuildContext context,
    String message, {
    bool showOpenButton = false,
    String? errorDetail,
  }) {
    final feedbackParams = LessonFeedbackParams(
      lessonId: widget.lessonId,
      topicId: widget.topicId,
      lessonTitle: widget.lessonTitle,
      topicTitle: widget.title,
      defaultErrorType: 'video',
      errorDetail: errorDetail ?? message,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
            ),
            if (showOpenButton) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openInYoutubeApp,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Mở trên YouTube'),
              ),
            ],
            LessonFeedbackErrorBanner(
              params: feedbackParams,
              message: 'Gặp lỗi khi xem video? Gửi phản hồi để team kiểm tra.',
            ),
          ],
        ),
      ),
    );
  }
}
