import 'package:dio/dio.dart';

/// Client for [stable.api.dartpad.dev] (compile / version).
class DartPadService {
  DartPadService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://stable.api.dartpad.dev/api/v3/',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<DartPadVersion> fetchVersion() async {
    final response = await _dio.get<Map<String, dynamic>>('version');
    final data = response.data;
    if (data == null) {
      throw Exception('DartPad version: empty response');
    }
    return DartPadVersion(
      engineVersion: data['engineVersion'] as String? ?? '',
    );
  }

  Future<DartPadCompileResult> compile(String source) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'compileNewDDC',
      data: {'source': source},
    );
    final data = response.data;
    if (data == null) {
      throw Exception('DartPad compile: empty response');
    }
    final error = data['error'] as String?;
    if (error != null && error.isNotEmpty) {
      return DartPadCompileResult.failure(error);
    }
    final result = data['result'] as String?;
    if (result == null || result.isEmpty) {
      return DartPadCompileResult.failure('Compilation returned no output.');
    }
    return DartPadCompileResult.success(result);
  }
}

class DartPadVersion {
  const DartPadVersion({required this.engineVersion});

  final String engineVersion;

  String get canvasKitBaseUrl =>
      'https://www.gstatic.com/flutter-canvaskit/$engineVersion/';
}

class DartPadCompileResult {
  const DartPadCompileResult._({this.javaScript, this.error});

  factory DartPadCompileResult.success(String javaScript) =>
      DartPadCompileResult._(javaScript: javaScript);

  factory DartPadCompileResult.failure(String error) =>
      DartPadCompileResult._(error: error);

  final String? javaScript;
  final String? error;

  bool get isSuccess => javaScript != null;
}

/// Wraps compiled JS for execution (matches dart-lang/dart-pad frame.dart).
///
/// [useHostBridge] — when true, stdout/errors go through `DartRunner` (in-app
/// WebView) instead of `parent.postMessage` (dartpad.dev iframe).
String decorateDartPadJavaScript(
  String javaScript, {
  required bool isFlutter,
  bool useHostBridge = false,
}) {
  const artifactsUrl = 'https://stable.api.dartpad.dev/artifacts/';
  final postMessage = useHostBridge
      ? '''
function _dartPadPost(msg) {
  if (typeof DartRunner !== 'undefined') {
    DartRunner.postMessage(JSON.stringify(msg));
  }
}
'''
      : '''
function _dartPadPost(msg) {
  parent.postMessage(msg, '*');
}
''';

  final buffer = StringBuffer()
    ..writeln(postMessage)
    ..writeln('''
function dartPrint(message) {
  _dartPadPost({
    'sender': 'frame',
    'type': 'stdout',
    'message': message.toString(),
  });
}
''')
    ..writeln('''
window.onerror = function(message, url, line, column, error) {
  var errorMessage = error == null ? '' : ', error: ' + error;
  _dartPadPost({
    'sender': 'frame',
    'type': 'jserr',
    'message': message + errorMessage
  });
};
''')
    ..writeln('''
require.config({
  "baseUrl": "$artifactsUrl",
  "waitSeconds": 60,
  "onNodeCreated": function(node, config, id, url) {
    node.setAttribute('crossorigin', 'anonymous');
  }
});
''')
    ..writeln('{')
    ..writeln('let __ddcInitCode = function() {$javaScript}')
    ..writeln('''
function contextLoaded() {
  __ddcInitCode();
  dartDevEmbedder.runMain('package:dartpad_sample/bootstrap.dart', {});
}
''');

  if (isFlutter) {
    buffer.writeln('''
function moduleLoaderLoaded() {
  require(["dart_sdk_new", "flutter_web_new"], contextLoaded);
}
''');
  } else {
    buffer.writeln('''
function moduleLoaderLoaded() {
  require(["dart_sdk_new"], contextLoaded);
}
''');
  }

  buffer
    ..writeln('require(["ddc_module_loader"], moduleLoaderLoaded);')
    ..writeln('}');

  return buffer.toString();
}
