import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_flutter/features/data/services/openai_chat_service.dart';

/// Google Gemini — https://aistudio.google.com/apikey
class GeminiChatService {
  GeminiChatService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 90),
              ),
            );

  final Dio _dio;

  /// Chỉ dùng model free ổn định — **không** dùng gemini-2.0-flash (hay limit: 0).
  static const defaultModel = 'gemini-1.5-flash';

  static const freeModels = <String>[
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-2.0-flash-lite',
  ];

  String? get apiKey => dotenv.env['GEMINI_API_KEY']?.trim();

  String get configuredModel {
    final fromEnv = dotenv.env['GEMINI_MODEL']?.trim() ?? '';
    if (fromEnv.isEmpty) return defaultModel;
    if (fromEnv.contains('2.0-flash') && !fromEnv.contains('lite')) {
      return defaultModel;
    }
    return fromEnv;
  }

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  List<String> get _modelsToTry {
    final ordered = <String>[configuredModel, ...freeModels];
    return ordered.toSet().toList();
  }

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>>? history,
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw OpenAiChatException(
        'GEMINI_API_KEY chưa cấu hình. Lấy key tại https://aistudio.google.com/apikey',
      );
    }

    final contents = _buildContents(userMessage, history);
    final failed = <String>[];

    for (final modelName in _modelsToTry) {
      try {
        return await _generate(modelName, key, contents);
      } on _GeminiRetryException catch (e) {
        failed.add('• $modelName: ${e.reason}');
      }
    }

    throw OpenAiChatException(
      'Tất cả model Gemini free đều không dùng được:\n${failed.join('\n')}\n\n'
      'Khuyên dùng Groq free: đặt CHAT_PROVIDER=groq và GROQ_API_KEY tại console.groq.com',
    );
  }

  List<Map<String, dynamic>> _buildContents(
    String userMessage,
    List<Map<String, String>>? history,
  ) {
    final contents = <Map<String, dynamic>>[];
    for (final m in history ?? const []) {
      final role = m['role'];
      final text = m['content'] ?? '';
      if (text.trim().isEmpty) continue;
      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': text}
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });
    return contents;
  }

  Future<String> _generate(
    String modelName,
    String key,
    List<Map<String, dynamic>> contents,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent',
        queryParameters: {'key': key},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'systemInstruction': {
            'parts': [
              {
                'text':
                    'Bạn là trợ lý học Flutter và Dart. Trả lời ngắn gọn, dễ hiểu, '
                    'ưu tiên tiếng Việt.',
              }
            ],
          },
          'contents': contents,
          'generationConfig': {'temperature': 0.7},
        },
      );

      final text = _extractText(response.data);
      if (text != null) return text;

      throw _GeminiRetryException('không có nội dung trả về');
    } on DioException catch (e) {
      throw _GeminiRetryException(_dioReason(e));
    }
  }

  String? _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = (candidates.first as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;
    final text = (parts.first as Map<String, dynamic>)['text'];
    if (text is String && text.trim().isNotEmpty) return text.trim();
    return null;
  }

  String _dioReason(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is Map<String, dynamic>) {
        final msg = err['message'];
        if (msg is String && msg.isNotEmpty) {
          return 'HTTP $status — ${msg.length > 120 ? '${msg.substring(0, 120)}…' : msg}';
        }
      }
    }
    return 'HTTP $status';
  }
}

class _GeminiRetryException implements Exception {
  _GeminiRetryException(this.reason);
  final String reason;
}
