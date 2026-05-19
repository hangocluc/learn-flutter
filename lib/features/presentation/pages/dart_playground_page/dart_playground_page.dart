import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learn_java/features/data/services/dart_pad_service.dart';
import 'package:learn_java/features/presentation/pages/dartpad_page/dartpad_page.dart';
import 'package:learn_java/features/presentation/widgets/code_editor_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Dart playground: editor in Flutter + run via dartpad.dev [frame.html].
class DartPlaygroundPage extends StatefulWidget {
  const DartPlaygroundPage({
    super.key,
    required this.initialCode,
    this.title,
  });

  final String initialCode;
  final String? title;

  static const _dartPadBlue = Color(0xFF168AFD);
  static const _tabBarBg = Color(0xFF2D2E31);
  static final Uri _frameUri = Uri.parse('https://dartpad.dev/frame.html');

  /// Injected once after frame.html loads (replaceJavaScript lives in frame.js).
  static const _runnerBridgeJs = r'''
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
    } else if (window.webkit &&
        window.webkit.messageHandlers &&
        window.webkit.messageHandlers.DartRunner) {
      window.webkit.messageHandlers.DartRunner.postMessage(payload);
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

  window.__dartPadRunFlutter = function (jsB64, kit) {
    try {
      var script = __dartPadDecodeB64(jsB64);
      runFlutterApp(script, kit || '', false);
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
  late final WebViewController _runner;
  late String _code;
  bool _running = false;
  bool _frameReady = false;
  int _readyPolls = 0;
  String? _engineVersion;
  String _outputText = '';
  String? _runnerError;

  bool get _isFlutter => _code.contains('package:flutter');

  @override
  void initState() {
    super.initState();
    _code = widget.initialCode.trim();
    _tabs = TabController(length: 2, vsync: this);
    _initRunner();

    _dartPad.fetchVersion().then((v) {
      if (mounted) _engineVersion = v.engineVersion;
    }).catchError((_) {});
  }

  void _initRunner() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _runner = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'DartRunner',
        onMessageReceived: _onRunnerMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _pollRunnerReady(),
          onWebResourceError: (WebResourceError error) {
            dev.log('Dart runner WebView: ${error.description}');
            if (mounted) {
              setState(() {
                _runnerError =
                    'Không tải runner: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(DartPlaygroundPage._frameUri);

    final platform = _runner.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  Future<void> _pollRunnerReady() async {
    if (!mounted || _frameReady) return;
    _readyPolls++;

    try {
      final hasReplace = await _runner.runJavaScriptReturningResult(
        'typeof replaceJavaScript === "function"',
      );
      final hasRequire = await _runner.runJavaScriptReturningResult(
        'typeof require === "function"',
      );

      final ok = (hasReplace == true || hasReplace == 'true') &&
          (hasRequire == true || hasRequire == 'true');

      if (ok) {
        await _runner.runJavaScript(DartPlaygroundPage._runnerBridgeJs);
        if (mounted) {
          setState(() {
            _frameReady = true;
            _runnerError = null;
          });
        }
        return;
      }
    } catch (e) {
      dev.log('Runner poll error: $e');
    }

    if (_readyPolls >= 40) {
      if (mounted) {
        setState(() {
          _runnerError =
              'Không kết nối được dartpad.dev. Kiểm tra mạng hoặc mở trên trình duyệt.';
        });
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) await _pollRunnerReady();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onRunnerMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'ready') {
        if (mounted) {
          setState(() {
            _frameReady = true;
            _runnerError = null;
          });
        }
        return;
      }

      final text = data['message']?.toString() ?? '';
      if (text.isEmpty) return;

      setState(() {
        if (type == 'stdout') {
          _outputText += text.endsWith('\n') ? text : '$text\n';
        } else {
          _outputText += '$text\n';
        }
      });

      if (type == 'stdout' || type == 'jserr' || type == 'stderr') {
        _tabs.animateTo(1);
      }
    } catch (e) {
      dev.log('DartRunner message parse error: $e');
    }
  }

  Future<void> _run() async {
    if (_running || !_frameReady) return;
    setState(() {
      _running = true;
      _outputText = '';
    });

    try {
      final compile = await _dartPad.compile(_code);
      if (!compile.isSuccess) {
        setState(() {
          _outputText = compile.error ?? 'Compilation failed.';
        });
        _tabs.animateTo(1);
        return;
      }

      final decorated = decorateDartPadJavaScript(
        compile.javaScript!,
        isFlutter: _isFlutter,
        useHostBridge: true,
      );

      final jsB64 = jsonEncode(base64Encode(utf8.encode(decorated)));
      final canvasKit = _engineVersion != null && _engineVersion!.isNotEmpty
          ? 'https://www.gstatic.com/flutter-canvaskit/$_engineVersion/'
          : '';

      final call = _isFlutter
          ? '__dartPadRunFlutter($jsB64, ${jsonEncode(canvasKit)})'
          : '__dartPadRunConsole($jsB64)';

      final result = await _runner.runJavaScriptReturningResult(call);
      final failed = result == false || result == 'false';
      if (failed && mounted) {
        setState(() {
          _outputText = 'Không chạy được trên runner. Thử lại hoặc mở dartpad.dev.';
        });
        _tabs.animateTo(1);
      }
    } catch (e) {
      setState(() => _outputText = e.toString());
      _tabs.animateTo(1);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _openInBrowser() async {
    await launchUrl(
      Uri.https('dartpad.dev', '/', {'channel': 'stable'}),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openFullDartPad() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => DartPadPage(
          title: widget.title,
          initialCode: _code,
          runOnOpen: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DartPlaygroundPage._tabBarBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: DartPlaygroundPage._dartPadBlue,
        foregroundColor: Colors.white,
        title: Text(
          widget.title ?? 'Dart',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            tooltip: 'DartPad đầy đủ (chạy chắc chắn)',
            onPressed: _openFullDartPad,
            icon: const Icon(Icons.code, size: 22),
          ),
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
                    ),
                    _buildOutputPane(),
                  ],
                ),
              ),
            ],
          ),
          // Hidden runner (in tree for JS; not Offstage — iOS needs that).
          Positioned(
            left: 0,
            top: 0,
            width: 1,
            height: 1,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.01,
                child: WebViewWidget(controller: _runner),
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
    final canRun = _frameReady && !_running;
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
              else if (!_frameReady)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                )
              else
                const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                _frameReady ? 'Run' : '…',
                style: const TextStyle(
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
    final isError = _outputText.contains('Error') ||
        _outputText.contains('error:') ||
        _outputText.contains('Exception') ||
        _runnerError != null;

    final display = _runnerError ??
        (_outputText.isEmpty
            ? (_running
                ? 'Đang biên dịch và chạy…'
                : _frameReady
                    ? 'Nhấn Run để xem kết quả print().'
                    : 'Đang tải DartPad runner…')
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
                  if (isError && _outputText.contains('__ddcInitCode'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton.icon(
                        onPressed: _openFullDartPad,
                        icon: const Icon(Icons.code, color: Colors.white70),
                        label: const Text(
                          'Chạy trên DartPad đầy đủ',
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
