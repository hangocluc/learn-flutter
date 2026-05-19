import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// In-app DartPad: hosts [dartpad.dev] in an iframe and injects [initialCode]
/// via `postMessage` from the parent page (required by current DartPad embed API).
///
/// Optional [gistId] opens `dartpad.dev/?id=…` directly (no injection).
class DartPadPage extends StatefulWidget {
  const DartPadPage({
    super.key,
    required this.initialCode,
    this.title,
    this.gistId,
    this.runOnOpen = false,
  });

  final String initialCode;
  final String? title;
  final String? gistId;
  final bool runOnOpen;

  static Uri embedUri({bool runOnOpen = false}) {
    final query = <String, String>{
      'embed': 'true',
      'channel': 'stable',
    };
    if (runOnOpen) {
      query['run'] = 'true';
    }
    return Uri.https('dartpad.dev', '/', query);
  }

  static Uri gistUri(String gistId, bool runOnOpen) {
    final query = <String, String>{
      'channel': 'stable',
      'id': gistId.trim(),
    };
    if (runOnOpen) {
      query['run'] = 'true';
    }
    return Uri.https('dartpad.dev', '/', query);
  }

  /// Parent page that embeds DartPad in an iframe (DartPad only accepts
  /// `postMessage` from `window.parent`, and expects `sourceCode` as a String).
  static String hostHtml({
    required String embedUrl,
    required String codeBase64,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin: 0; padding: 0; height: 100%; overflow: hidden; background: #fff; }
    #dp { border: 0; width: 100%; height: 100%; }
  </style>
</head>
<body>
  <iframe id="dp" src="$embedUrl" allow="clipboard-write *"></iframe>
  <script>
    (function () {
      const code = (function () {
        const bin = atob('$codeBase64');
        const bytes = new Uint8Array(bin.length);
        for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
        return new TextDecoder('utf-8').decode(bytes);
      })();

      const iframe = document.getElementById('dp');

      function inject() {
        if (!iframe.contentWindow) return;
        iframe.contentWindow.postMessage(
          { type: 'sourceCode', sourceCode: code },
          '*'
        );
      }

      window.addEventListener('message', function (event) {
        if (event.data && event.data.type === 'ready') inject();
      });

      iframe.addEventListener('load', function () {
        inject();
        setTimeout(inject, 450);
        setTimeout(inject, 1200);
      });
    })();
  </script>
</body>
</html>
''';
  }

  @override
  State<DartPadPage> createState() => _DartPadPageState();
}

class _DartPadPageState extends State<DartPadPage> {
  bool _loading = true;
  late final WebViewController _controller;

  bool get _useGist {
    final id = widget.gistId?.trim();
    return id != null && id.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (WebResourceError error) {
            log('DartPad WebView error: ${error.description}');
          },
        ),
      );

    if (_useGist) {
      _controller.loadRequest(DartPadPage.gistUri(widget.gistId!, widget.runOnOpen));
    } else {
      final code = widget.initialCode.trim();
      final embedUrl =
          DartPadPage.embedUri(runOnOpen: widget.runOnOpen).toString();
      final html = DartPadPage.hostHtml(
        embedUrl: embedUrl,
        codeBase64: base64Encode(utf8.encode(code)),
      );
      // data: URI avoids iOS WKWebView auth-challenge crash with loadHtmlString+baseUrl.
      _controller.loadRequest(
        Uri.dataFromString(html, mimeType: 'text/html', encoding: utf8),
      );
    }

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'DartPad'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
