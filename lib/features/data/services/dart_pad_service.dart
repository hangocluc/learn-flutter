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
    final prepared = prepareDartPadSource(source);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'compileNewDDC',
        data: {'source': prepared},
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
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is String && body.trim().isNotEmpty) {
        return DartPadCompileResult.failure(body.trim());
      }
      if (body is Map) {
        final error = body['error']?.toString();
        if (error != null && error.isNotEmpty) {
          return DartPadCompileResult.failure(error);
        }
      }
      return DartPadCompileResult.failure(
        'Không biên dịch được code. Kiểm tra cú pháp hoặc thử lại sau.',
      );
    }
  }

  Future<DartPadFormatResult> format(String source) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'format',
        data: {'source': source},
      );
      final data = response.data;
      if (data == null) {
        return DartPadFormatResult.failure('Format: empty response');
      }
      final formatted = data['source'] as String?;
      if (formatted == null || formatted.isEmpty) {
        return DartPadFormatResult.failure('Format returned no output.');
      }
      return DartPadFormatResult.success(formatted);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is String && body.trim().isNotEmpty) {
        return DartPadFormatResult.failure(body.trim());
      }
      if (body is Map) {
        final error = body['error']?.toString();
        if (error != null && error.isNotEmpty) {
          return DartPadFormatResult.failure(error);
        }
      }
      return DartPadFormatResult.failure('Không format được code.');
    }
  }
}

/// Ensures Flutter snippets from lessons can compile on DartPad.
String prepareDartPadSource(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  if (RegExp(r'\bvoid\s+main\s*\(').hasMatch(trimmed)) {
    return trimmed;
  }

  if (!trimmed.contains('package:flutter')) {
    return trimmed;
  }

  final allWidgets = _findAllWidgetClasses(trimmed);
  if (allWidgets.isEmpty) {
    return trimmed;
  }

  // Find the root widget: one that is NOT instantiated inside other widget classes.
  final rootWidget = _findRootWidget(trimmed, allWidgets);

  // If the code already has a MaterialApp (e.g. MyApp wraps MaterialApp),
  // just call runApp directly on the root widget.
  if (trimmed.contains('MaterialApp')) {
    return '''
$trimmed

void main() {
  runApp($rootWidget());
}
''';
  }

  return '''
$trimmed

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: $rootWidget(),
        ),
      ),
    ),
  );
}
''';
}

List<String> _findAllWidgetClasses(String source) {
  final pattern = RegExp(
    r'class\s+(\w+)\s+extends\s+(?:StatelessWidget|StatefulWidget)',
    multiLine: true,
  );
  return [
    for (final match in pattern.allMatches(source))
      if (match.group(1) != null) match.group(1)!,
  ];
}

/// Returns the widget class that is NOT instantiated inside any other widget
/// class body — that widget is the entry-point / root.
String _findRootWidget(String source, List<String> widgetNames) {
  if (widgetNames.length == 1) return widgetNames.first;

  for (final candidate in widgetNames) {
    final usedByOther = widgetNames.any(
      (other) => other != candidate && _isUsedInside(source, other, candidate),
    );
    if (!usedByOther) return candidate;
  }

  return widgetNames.first;
}

/// Returns true when [targetName] is instantiated (`targetName(`) inside the
/// body of class [containerClass].
bool _isUsedInside(String source, String containerClass, String targetName) {
  final classStart =
      RegExp('class\\s+$containerClass\\b').firstMatch(source)?.start;
  if (classStart == null) return false;

  final nextClassMatch =
      RegExp(r'\nclass\s+\w+\s+extends').firstMatch(source.substring(classStart + 1));
  final end = nextClassMatch == null
      ? source.length
      : classStart + 1 + nextClassMatch.start;

  return source.substring(classStart, end).contains('$targetName(');
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

class DartPadFormatResult {
  const DartPadFormatResult._({this.formattedSource, this.error});

  factory DartPadFormatResult.success(String formattedSource) =>
      DartPadFormatResult._(formattedSource: formattedSource);

  factory DartPadFormatResult.failure(String error) =>
      DartPadFormatResult._(error: error);

  final String? formattedSource;
  final String? error;

  bool get isSuccess => formattedSource != null;
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
