import 'package:url_launcher/url_launcher.dart';

/// Helpers for [videoLink] fields (YouTube watch URLs, youtu.be, embed links).
class VideoLinkUtils {
  VideoLinkUtils._();

  static const _embedOrigin = 'https://www.youtube-nocookie.com';

  static String? youtubeVideoId(String? raw) {
    final input = raw?.trim();
    if (input == null || input.isEmpty) return null;

    final uri = Uri.tryParse(input);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return id.isEmpty ? null : id;
    }

    if (uri.host.contains('youtube.com') ||
        uri.host.contains('youtube-nocookie.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      final segments = uri.pathSegments;
      if (segments.length >= 2 &&
          (segments[0] == 'embed' || segments[0] == 'shorts')) {
        return segments[1];
      }
    }

    return null;
  }

  static bool hasPlayableVideo(String? raw) => youtubeVideoId(raw) != null;

  static String youtubeWatchUrl(String? raw) {
    final id = youtubeVideoId(raw);
    if (id == null) return '';
    return 'https://www.youtube.com/watch?v=$id';
  }

  static String youtubeShortUrl(String? raw) {
    final id = youtubeVideoId(raw);
    if (id == null) return '';
    return 'https://youtu.be/$id';
  }

  /// Opens YouTube via app deep link first, then external browser.
  static Future<bool> launchYoutubeVideo(String? raw) async {
    final id = youtubeVideoId(raw);
    final candidates = <({Uri uri, LaunchMode mode})>[];

    if (id != null) {
      candidates.addAll([
        (
          uri: Uri.parse('vnd.youtube:$id'),
          mode: LaunchMode.externalNonBrowserApplication,
        ),
        (
          uri: Uri.parse('youtube://www.youtube.com/watch?v=$id'),
          mode: LaunchMode.externalNonBrowserApplication,
        ),
        (
          uri: Uri.parse('https://youtu.be/$id'),
          mode: LaunchMode.externalApplication,
        ),
        (
          uri: Uri.parse('https://www.youtube.com/watch?v=$id'),
          mode: LaunchMode.externalApplication,
        ),
      ]);
    }

    final trimmed = raw?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed != null &&
          parsed.hasScheme &&
          !candidates.any((c) => c.uri.toString() == parsed.toString())) {
        candidates.add((uri: parsed, mode: LaunchMode.externalApplication));
      }
    }

    for (final candidate in candidates) {
      try {
        if (await launchUrl(candidate.uri, mode: candidate.mode)) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  static String youtubeThumbnailUrl(String? raw) {
    final id = youtubeVideoId(raw);
    if (id == null) return '';
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  /// Embed URL + params giúp tránh lỗi 153 trên WebView mobile.
  static String youtubeEmbedUrl(String? raw) {
    final id = youtubeVideoId(raw);
    if (id == null) return '';
    return '$_embedOrigin/embed/$id'
        '?playsinline=1'
        '&rel=0'
        '&modestbranding=1'
        '&enablejsapi=1'
        '&fs=1'
        '&origin=$_embedOrigin';
  }

  static String embedHtmlForVideoId(String videoId) {
    final embed = youtubeEmbedUrl('https://www.youtube.com/watch?v=$videoId');
    return _embedHtml(embed);
  }

  static String _embedHtml(String embedUrl) => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    .wrap { position: relative; width: 100%; height: 100%; }
    iframe {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      border: 0;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <iframe
      src="$embedUrl"
      title="YouTube video"
      referrerpolicy="strict-origin-when-cross-origin"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
      allowfullscreen
    ></iframe>
  </div>
</body>
</html>
''';
}
