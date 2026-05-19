import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_java/features/data/services/openai_chat_service.dart';

/// Groq — free tier: https://console.groq.com/keys
class GroqChatService {
  GroqChatService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 90),
              ),
            );

  final Dio _dio;

  static const defaultModel = 'llama-3.1-8b-instant';

  String? get apiKey => dotenv.env['GROQ_API_KEY']?.trim();

  String get model {
    final fromEnv = dotenv.env['GROQ_MODEL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return defaultModel;
  }

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>>? history,
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw OpenAiChatException(
        'GROQ_API_KEY chưa cấu hình. Lấy key free tại '
        'https://console.groq.com/keys',
      );
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Bạn là trợ lý học Flutter và Dart. Trả lời ngắn gọn, tiếng Việt khi user hỏi tiếng Việt.',
      },
      ...?history,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
        },
      );

      final choices = response.data?['choices'];
      if (choices is List && choices.isNotEmpty) {
        final message = (choices.first as Map<String, dynamic>)['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
      throw OpenAiChatException('Groq không trả về nội dung text.');
    } on DioException catch (e) {
      throw OpenAiChatException(_messageFromDio(e));
    }
  }

  String _messageFromDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is Map<String, dynamic>) {
        final msg = err['message'];
        if (msg is String && msg.isNotEmpty) {
          return 'Groq ($status): $msg';
        }
      }
    }
    if (status == 429) {
      return 'Groq hết quota free (429). Thử lại sau hoặc tạo key mới tại console.groq.com';
    }
    return e.message ?? 'Lỗi khi gọi Groq.';
  }
}
