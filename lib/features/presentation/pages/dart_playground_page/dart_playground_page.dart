import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learn_flutter/common/utils/device_info_utils.dart';
import 'package:learn_flutter/features/data/services/dart_pad_service.dart';
import 'package:learn_flutter/features/presentation/widgets/code_editor_widget.dart';
import 'package:learn_flutter/features/presentation/widgets/lesson_feedback_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Dart playground: Code tab + Output tab on one screen.
/// Console Dart runs in a hidden frame; Flutter preview renders in Output tab.
class DartPlaygroundPage extends StatefulWidget {
  const DartPlaygroundPage({
    super.key,
    required this.initialCode,
    this.title,
    this.lessonId,
    this.topicId,
    this.lessonTitle,
  });

  final String initialCode;
  final String? title;
  final String? lessonId;
  final String? topicId;
  final String? lessonTitle;

  static const _dartPadBlue = Color(0xFF168AFD);
  static const _tabBarBg = Color(0xFF2D2E31);
  static final Uri _frameUri = Uri.parse('https://dartpad.dev/frame.html');

  static const _consoleBridgeJs = r'''
(function () {
  if (window.__dartPadBridgeReady) return;
  window.__dartPadBridgeReady = true;

  window.__dartPadDecodeB64 = function (b64) {
    var bin = atob(b64), bytes = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new TextDecoder('utf-8').decode(bytes);
  };

  window.__dartPadNotify = function (msg) {
    var payload = JSON.stringify(msg);
    if (window.DartRunner) {
      DartRunner.postMessage(payload);
    }
  };

  window.__dartPadRunConsole = function (jsB64) {
    try {
      replaceJavaScript(__dartPadDecodeB64(jsB64));
      return true;
    } catch (e) {
      __dartPadNotify({
        sender: 'frame',
        type: 'jserr',
        message: String(e)
      });
      return false;
    }
  };

  __dartPadNotify({ sender: 'frame', type: 'ready' });
})();
''';

  /// Console runner without flutter.js — much lighter than [ _frameUri ].
  static const _consoleRunnerHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="require.js"></script>
</head>
<body>
<script>
function replaceJavaScript(value) {
  var oldNode = document.getElementById('compiled-script');
  if (oldNode && oldNode.parentNode) {
    oldNode.parentNode.removeChild(oldNode);
  }
  var scriptNode = document.createElement('script');
  scriptNode.setAttribute('id', 'compiled-script');
  scriptNode.async = false;
  scriptNode.text = value;
  document.head.appendChild(scriptNode);
}
</script>
</body>
</html>
''';

  static const _flutterBridgeJs = r'''
(function () {
  if (window.__dartPadBridgeReady) return;
  window.__dartPadBridgeReady = true;

  window.__dartPadDecodeB64 = function (b64) {
    var bin = atob(b64), bytes = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new TextDecoder('utf-8').decode(bytes);
  };

  window.__dartPadNotify = function (msg) {
    var payload = JSON.stringify(msg);
    if (window.DartRunner) {
      DartRunner.postMessage(payload);
    }
  };

  window.__dartPadRunFlutter = function (jsB64, kit, reload) {
    try {
      var script = __dartPadDecodeB64(jsB64);
      runFlutterApp(script, kit || '', !!reload);
      return true;
    } catch (e) {
      __dartPadNotify({
        sender: 'frame',
        type: 'jserr',
        message: String(e)
      });
      return false;
    }
  };

  __dartPadNotify({ sender: 'frame', type: 'ready' });
})();
''';

  @override
  State<DartPlaygroundPage> createState() => _DartPlaygroundPageState();
}

class _DartPlaygroundPageState extends State<DartPlaygroundPage>
    with SingleTickerProviderStateMixin {
  final _dartPad = DartPadService();
  late final TabController _tabs;
  WebViewController? _consoleRunner;
  WebViewController? _flutterPreview;
  late String _code;
  bool _running = false;
  bool _consoleReady = false;
  bool _consoleHasRun = false;
  bool _flutterPreviewReady = false;
  bool _flutterHasRun = false;
  int _consoleReadyPolls = 0;
  int _flutterReadyPolls = 0;
  String? _engineVersion;
  String _outputText = '';
  String? _runnerError;
  bool _flutterPreviewRisky = false;
  bool _androidHybridComposition = false;

  bool get _isFlutter => _code.contains('package:flutter');

  bool get _useHybridComposition =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      _androidHybridComposition;

  @override
  void initState() {
    super.initState();
    _code = widget.initialCode.trim();
    _tabs = TabController(length: 2, vsync: this);

    if (_isFlutter) {
      _dartPad.fetchVersion().then((version) {
        if (mounted) setState(() => _engineVersion = version.engineVersion);
      }).catchError((_) {});

      // Pre-warm the Flutter WebView so it's ready before the user taps Run.
      // On Android we must know device caps first (hybrid composition + risky flag).
      _loadFlutterDeviceCaps().then((_) {
        if (mounted && !_flutterPreviewRisky) _initFlutterPreview();
      });
    } else {
      // Pre-warm the console Dart runner in the background.
      _initConsoleRunner();
    }
  }

  Future<void> _loadFlutterDeviceCaps() async {
    if (!Platform.isAndroid) {
      // On iOS the preview is always safe — pre-warm immediately.
      _initFlutterPreview();
      return;
    }
    final risky =
        await DeviceInfoUtils.instance.isFlutterWebPreviewRisky();
    final emulator = await DeviceInfoUtils.instance.isAndroidEmulator();
    if (!mounted) return;
    setState(() {
      _flutterPreviewRisky = risky;
      _androidHybridComposition = !emulator;
    });
  }

  WebViewController _createRunner({
    required void Function(JavaScriptMessage message) onMessage,
    required void Function(String description) onWebError,
    required VoidCallback onPageFinished,
    required bool flutterFrame,
  }) {
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
      ..addJavaScriptChannel(
        'DartRunner',
        onMessageReceived: onMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => onPageFinished(),
          onWebResourceError: (WebResourceError error) {
            onWebError(error.description);
          },
        ),
      );

    if (flutterFrame) {
      controller.loadRequest(DartPlaygroundPage._frameUri);
    } else {
      controller.loadHtmlString(
        DartPlaygroundPage._consoleRunnerHtml,
        baseUrl: 'https://dartpad.dev/',
      );
    }

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    return controller;
  }

  void _initConsoleRunner() {
    if (_consoleRunner != null) return;

    _consoleRunner = _createRunner(
      onMessage: _onConsoleMessage,
      onWebError: (description) {
        dev.log('Console runner WebView: $description');
        if (mounted) {
          setState(() {
            _runnerError = 'Không tải runner: $description';
          });
        }
      },
      onPageFinished: _pollConsoleReady,
      flutterFrame: false,
    );
  }

  void _initFlutterPreview() {
    if (_flutterPreview != null) return;

    _flutterPreview = _createRunner(
      onMessage: _onFlutterPreviewMessage,
      onWebError: (description) {
        dev.log('Flutter preview WebView: $description');
        _handleFlutterPreviewCrash(description);
      },
      onPageFinished: _pollFlutterPreviewReady,
      flutterFrame: true,
    );
  }

  void _handleFlutterPreviewCrash(String description) {
    _releaseRunner(_flutterPreview);
    _flutterPreview = null;
    if (!mounted) return;
    setState(() {
      _flutterPreviewReady = false;
      _flutterHasRun = false;
      _flutterReadyPolls = 0;
      _runnerError = 'Preview bị dừng (thiếu RAM hoặc WebView crash).';
      _outputText = '$_runnerError\n$description\n\n'
          'Thử mở DartPad trên trình duyệt (nút góc phải).';
    });
  }

  Widget _runnerWebView(WebViewController controller) {
    if (_useHybridComposition &&
        controller.platform is AndroidWebViewController) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: controller.platform,
          displayWithHybridComposition: true,
        ),
      );
    }
    return WebViewWidget(controller: controller);
  }

  Future<void> _pollConsoleReady() async {
    await _pollRunnerReady(
      runner: _consoleRunner,
      bridgeJs: DartPlaygroundPage._consoleBridgeJs,
      isReady: () => _consoleReady,
      onReady: () {
        if (mounted) {
          setState(() {
            _consoleReady = true;
            _runnerError = null;
          });
        }
      },
      pollCount: () => _consoleReadyPolls,
      incrementPoll: () => _consoleReadyPolls++,
    );
  }

  Future<void> _pollFlutterPreviewReady() async {
    await _pollRunnerReady(
      runner: _flutterPreview,
      bridgeJs: DartPlaygroundPage._flutterBridgeJs,
      isReady: () => _flutterPreviewReady,
      onReady: () {
        if (mounted) {
          setState(() {
            _flutterPreviewReady = true;
            _runnerError = null;
          });
        }
      },
      pollCount: () => _flutterReadyPolls,
      incrementPoll: () => _flutterReadyPolls++,
      // Flutter frame.html không có replaceJavaScript — chỉ check require
      flutterFrame: true,
    );
  }

  Future<void> _pollRunnerReady({
    required WebViewController? runner,
    required String bridgeJs,
    required bool Function() isReady,
    required VoidCallback onReady,
    required int Function() pollCount,
    required void Function() incrementPoll,
    bool flutterFrame = false,
  }) async {
    if (!mounted || isReady() || runner == null) return;
    incrementPoll();

    try {
      final hasRequire = await runner.runJavaScriptReturningResult(
        'typeof require === "function"',
      );
      final requireOk = hasRequire == true || hasRequire == 'true';

      bool ok;
      if (flutterFrame) {
        // frame.html không định nghĩa replaceJavaScript — chỉ cần require
        ok = requireOk;
      } else {
        final hasReplace = await runner.runJavaScriptReturningResult(
          'typeof replaceJavaScript === "function"',
        );
        ok = requireOk && (hasReplace == true || hasReplace == 'true');
      }

      if (ok) {
        await runner.runJavaScript(bridgeJs);
        onReady();
        return;
      }
    } catch (e) {
      dev.log('Runner poll error: $e');
    }

    if (pollCount() >= 60) {
      if (mounted) {
        setState(() {
          _runnerError =
              'Không kết nối được dartpad.dev. Kiểm tra mạng hoặc mở trên trình duyệt.';
        });
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await _pollRunnerReady(
        runner: runner,
        bridgeJs: bridgeJs,
        isReady: isReady,
        onReady: onReady,
        pollCount: pollCount,
        incrementPoll: incrementPoll,
        flutterFrame: flutterFrame,
      );
    }
  }

  Future<void> _waitForConsoleReady() async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (!_consoleReady && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    if (!_consoleReady) {
      throw StateError(
        'Không tải được Dart runner. Kiểm tra mạng hoặc mở trên trình duyệt.',
      );
    }
  }

  Future<void> _waitForFlutterPreviewReady() async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (!_flutterPreviewReady && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    if (!_flutterPreviewReady) {
      throw StateError('Không tải được Flutter preview. Thử lại sau.');
    }
  }

  Future<void> _reloadConsoleRunner() async {
    if (_consoleRunner == null) return;

    setState(() {
      _consoleReady = false;
      _consoleHasRun = false;
      _consoleReadyPolls = 0;
    });

    await _consoleRunner!.loadHtmlString(
      DartPlaygroundPage._consoleRunnerHtml,
      baseUrl: 'https://dartpad.dev/',
    );
    await _waitForConsoleReady();
  }

  Future<void> _reloadFlutterPreview() async {
    if (_flutterPreview == null) return;

    setState(() {
      _flutterPreviewReady = false;
      _flutterHasRun = false;
      _flutterReadyPolls = 0;
    });

    await _flutterPreview!.loadRequest(DartPlaygroundPage._frameUri);
    await _waitForFlutterPreviewReady();
  }

  Future<void> _injectFlutterRun({
    required String jsB64,
    required String canvasKit,
    required bool allowRetry,
  }) async {
    if (_flutterHasRun) {
      await _reloadFlutterPreview();
    }

    final result = await _flutterPreview!.runJavaScriptReturningResult(
      '__dartPadRunFlutter($jsB64, ${jsonEncode(canvasKit)}, false)',
    );
    final failed = result == false || result == 'false';

    if (!failed) {
      _flutterHasRun = true;
      return;
    }

    if (!allowRetry || !mounted) return;

    await _reloadFlutterPreview();
    await _injectFlutterRun(
      jsB64: jsB64,
      canvasKit: canvasKit,
      allowRetry: false,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _releaseRunner(_consoleRunner);
    _releaseRunner(_flutterPreview);
    super.dispose();
  }

  Future<void> _releaseRunner(WebViewController? runner) async {
    if (runner == null) return;
    try {
      await runner.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
  }

  void _onConsoleMessage(JavaScriptMessage message) {
    _handleRunnerMessage(
      message,
      onReady: () {
        if (mounted) {
          setState(() {
            _consoleReady = true;
            _runnerError = null;
          });
        }
      },
    );
  }

  void _onFlutterPreviewMessage(JavaScriptMessage message) {
    _handleRunnerMessage(
      message,
      onReady: () {
        if (mounted) {
          setState(() {
            _flutterPreviewReady = true;
            _runnerError = null;
          });
        }
      },
    );
  }

  void _handleRunnerMessage(
    JavaScriptMessage message, {
    required VoidCallback onReady,
  }) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'ready') {
        onReady();
        return;
      }

      final text = data['message']?.toString() ?? '';
      if (text.isEmpty) return;

      if (mounted) {
        setState(() {
          if (type == 'stdout') {
            _outputText += text.endsWith('\n') ? text : '$text\n';
          } else {
            _outputText += '$text\n';
          }
        });
      }

      if (mounted && (type == 'stdout' || type == 'jserr' || type == 'stderr')) {
        _tabs.animateTo(1);
      }
    } catch (e) {
      dev.log('DartRunner message parse error: $e');
    }
  }

  Future<void> _run() async {
    if (_running) return;
    // Lock immediately so rapid taps or re-entries during async gaps are ignored.
    setState(() => _running = true);

    try {
      if (_isFlutter) {
        await _runFlutter();
        return;
      }

      setState(() {
        _outputText = '';
        _runnerError = null;
      });
      _tabs.animateTo(1);

      if (!_consoleReady) {
        _initConsoleRunner();
        await _waitForConsoleReady();
      } else if (_consoleHasRun) {
        await _reloadConsoleRunner();
      }

      final compile = await _dartPad.compile(_code);
      if (!mounted) return;
      if (!compile.isSuccess) {
        setState(() {
          _outputText = compile.error ?? 'Compilation failed.';
        });
        _tabs.animateTo(1);
        return;
      }

      final decorated = decorateDartPadJavaScript(
        compile.javaScript!,
        isFlutter: false,
        useHostBridge: true,
      );

      final jsB64 = jsonEncode(base64Encode(utf8.encode(decorated)));
      final result = await _consoleRunner!.runJavaScriptReturningResult(
        '__dartPadRunConsole($jsB64)',
      );
      if (!mounted) return;
      final failed = result == false || result == 'false';
      if (failed) {
        setState(() {
          _outputText =
              'Không chạy được trên runner. Thử lại hoặc mở dartpad.dev.';
        });
        _tabs.animateTo(1);
      } else {
        _consoleHasRun = true;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _outputText = e.toString());
        _tabs.animateTo(1);
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// Called only from [_run], which already holds the [_running] lock.
  Future<void> _runFlutter() async {
    if (_flutterPreviewRisky) {
      final choice = await _showFlutterPreviewRiskDialog();
      if (!mounted) return;
      if (choice == _FlutterRunChoice.cancel) return;
      if (choice == _FlutterRunChoice.browser) {
        await _compileAndOpenInBrowser();
        return;
      }
    }

    setState(() {
      _outputText = '';
      _runnerError = null;
    });
    _tabs.animateTo(1);

    _initFlutterPreview();
    if (mounted) setState(() {});

    final compileFuture = _dartPad.compile(_code);
    if (!_flutterPreviewReady) {
      await _waitForFlutterPreviewReady();
    }

    final versionFuture = _engineVersion == null
        ? _dartPad.fetchVersion().then((version) {
            _engineVersion = version.engineVersion;
          }).catchError((_) {})
        : Future<void>.value();

    final compile = await compileFuture;
    await versionFuture;
    if (!mounted) return;
    if (!compile.isSuccess) {
      setState(() {
        _outputText = compile.error ?? 'Compilation failed.';
      });
      return;
    }

    final decorated = decorateDartPadJavaScript(
      compile.javaScript!,
      isFlutter: true,
      useHostBridge: true,
    );

    final jsB64 = jsonEncode(base64Encode(utf8.encode(decorated)));
    final canvasKit = _engineVersion != null && _engineVersion!.isNotEmpty
        ? 'https://www.gstatic.com/flutter-canvaskit/$_engineVersion/'
        : '';

    await _injectFlutterRun(
      jsB64: jsB64,
      canvasKit: canvasKit,
      allowRetry: true,
    );
  }

  Future<String?> _formatCode(String source) async {
    final result = await _dartPad.format(source);
    if (!result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Không format được code'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
    return result.formattedSource;
  }

  Future<void> _openInBrowser() async {
    await launchUrl(
      Uri.https('dartpad.dev', '/', {'channel': 'stable'}),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _compileAndOpenInBrowser() async {
    setState(() {
      _running = true;
      _outputText = '';
      _runnerError = null;
    });
    _tabs.animateTo(1);

    try {
      final compile = await _dartPad.compile(_code);
      if (!mounted) return;
      if (!compile.isSuccess) {
        setState(() {
          _outputText = compile.error ?? 'Compilation failed.';
        });
        return;
      }

      setState(() {
        _outputText =
            'Biên dịch thành công.\n'
            'Đang mở DartPad trên trình duyệt — dán code vào editor nếu cần.';
      });
      await _openInBrowser();
    } catch (e) {
      if (mounted) setState(() => _outputText = e.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<_FlutterRunChoice> _showFlutterPreviewRiskDialog() {
    return showDialog<_FlutterRunChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Flutter preview cần nhiều RAM'),
        content: const Text(
          'Chạy Flutter trong app tải engine Web (CanvasKit) qua WebView. '
          'Trên máy ảo Android hoặc máy RAM thấp, app có thể bị thoát đột ngột.\n\n'
          'Khuyên dùng DartPad trên trình duyệt để chạy code Flutter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _FlutterRunChoice.cancel),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _FlutterRunChoice.inApp),
            child: const Text('Thử trong app'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _FlutterRunChoice.browser),
            child: const Text('Mở trình duyệt'),
          ),
        ],
      ),
    ).then((value) => value ?? _FlutterRunChoice.cancel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DartPlaygroundPage._tabBarBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Dart'),
        actions: [
          IconButton(
            tooltip: 'Mở trên trình duyệt',
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_new, size: 22),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    CodeEditorWidget(
                      initialCode: _code,
                      onCodeChanged: (v) => _code = v,
                      onFormat: _formatCode,
                    ),
                    _buildOutputPane(),
                  ],
                ),
              ),
            ],
          ),
          if (_consoleRunner != null && !_isFlutter)
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.01,
                  child: _runnerWebView(_consoleRunner!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: DartPlaygroundPage._tabBarBg,
      child: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) {
          return SizedBox(
            height: 44,
            child: Row(
              children: [
                _tabLabel('Code', 0),
                _tabLabel('Output', 1),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _runButton(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tabLabel(String label, int index) {
    final selected = _tabs.index == index;
    return InkWell(
      onTap: () => _tabs.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? DartPlaygroundPage._dartPadBlue
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade500,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _runButton() {
    final canRun = !_running;
    return Material(
      color: DartPlaygroundPage._dartPadBlue,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: canRun ? _run : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_running)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              const Text(
                'Run',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutputPane() {
    if (_isFlutter) {
      return _buildFlutterOutputPane();
    }
    return _buildConsoleOutputPane();
  }

  Widget _buildFlutterOutputPane() {
    if (_flutterPreview == null) {
      return ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Nhấn Run để tải Flutter preview.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (_flutterPreviewRisky) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Máy ảo Android thường không đủ RAM cho Flutter preview. '
                    'Khi Run, hãy chọn "Mở trình duyệt" hoặc tăng RAM emulator (≥4 GB).',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ] else if (_useHybridComposition) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Flutter preview cần nhiều RAM. Nếu app bị thoát, thử máy thật hoặc nút mở trình duyệt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final hasError = _outputText.contains('Error') ||
        _outputText.contains('error:') ||
        _outputText.contains('Exception') ||
        _runnerError != null;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_running) const LinearProgressIndicator(minHeight: 2),
          if (_outputText.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              color: CodeEditorWidget.toolbarBg,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  _outputText,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    height: 1.4,
                    color: hasError ? const Color(0xFFEF5350) : Colors.white70,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                _runnerWebView(_flutterPreview!),
                if (!_flutterPreviewReady || (_running && _outputText.isEmpty))
                  ColoredBox(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            _running
                                ? 'Đang biên dịch và chạy…'
                                : 'Đang tải Flutter runner…',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleOutputPane() {
    final isError = _outputText.contains('Error') ||
        _outputText.contains('error:') ||
        _outputText.contains('Exception') ||
        _runnerError != null;

    final emptyHint = _isFlutter
        ? (_flutterPreview == null
            ? 'Nhấn Run để tải và chạy Flutter preview.'
            : (_flutterPreviewReady
                ? 'Nhấn Run để xem preview Flutter.'
                : 'Đang tải Flutter runner…'))
        : (_consoleReady
            ? 'Nhấn Run để xem kết quả print().'
            : 'Nhấn Run để tải Dart runner.');

    final display = _runnerError ??
        (_outputText.isEmpty
            ? (_running ? 'Đang biên dịch và chạy…' : emptyHint)
            : _outputText);

    return ColoredBox(
      color: CodeEditorWidget.editorBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 40,
            color: CodeEditorWidget.toolbarBg,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Console',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    display,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      height: 1.5,
                      color: display == _outputText && _outputText.isEmpty
                          ? Colors.grey.shade600
                          : (isError
                              ? const Color(0xFFEF5350)
                              : Colors.white70),
                    ),
                  ),
                  if (isError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () => LessonFeedbackSheet.showLesson(
                          context,
                          params: LessonFeedbackParams(
                            lessonId: widget.lessonId,
                            topicId: widget.topicId,
                            lessonTitle: widget.lessonTitle,
                            topicTitle: widget.title,
                            defaultErrorType: 'code',
                            errorDetail: display.length > 500
                                ? display.substring(0, 500)
                                : display,
                          ),
                        ),
                        icon: const Icon(
                          Icons.feedback_outlined,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          'Báo lỗi code / bài tập',
                          style: TextStyle(color: Colors.white70),
                        ),
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

enum _FlutterRunChoice { browser, inApp, cancel }
