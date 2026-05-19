import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gọi OpenAI Chat Completions API.
class OpenAiChatService {
  OpenAiChatService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 90),
                sendTimeout: const Duration(seconds: 30),
              ),
            );

  final Dio _dio;

  String? get apiKey => dotenv.env['OPENAI_API_KEY']?.trim();

  String get model =>
      dotenv.env['OPENAI_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['OPENAI_MODEL']!.trim()
          : 'gpt-4o-mini';

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>>? history,
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw OpenAiChatException(
        'OPENAI_API_KEY chưa được cấu hình trong file env (env/.env_staging). '
        'Thêm key tại https://platform.openai.com/api-keys rồi chạy lại app (full restart).',
      );
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Bạn là trợ lý học Flutter và Dart. Trả lời ngắn gọn, dễ hiểu, '
            'ưu tiên tiếng Việt khi người dùng hỏi bằng tiếng Việt. '
            'Có thể đưa ví dụ code ngắn khi phù hợp.',
      },
      ...?history,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.openai.com/v1/chat/completions',
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

      final data = response.data;
      final choices = data?['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map<String, dynamic>) {
          final message = first['message'];
          if (message is Map<String, dynamic>) {
            final content = message['content'];
            if (content is String && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
        }
      }

      throw OpenAiChatException('Phản hồi API không có nội dung text.');
    } on DioException catch (e) {
      throw OpenAiChatException(_messageFromDio(e));
    }
  }

  String _messageFromDio(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    if (body is Map<String, dynamic>) {
      final msg = _extractOpenAiErrorMessage(body);
      if (msg != null && msg.isNotEmpty) {
        if (status == 429 && msg.toLowerCase().contains('quota')) {
          return 'Tài khoản OpenAI đã hết credit hoặc chưa nạp tiền (429).\n\n'
              'Vào https://platform.openai.com/settings/organization/billing '
              '→ thêm phương thức thanh toán / nạp credit, rồi thử lại.\n\n'
              'App và API key của bạn đang hoạt động đúng.';
        }
        return 'OpenAI ($status): $msg';
      }
    }

    switch (status) {
      case 401:
        return 'API key không hợp lệ hoặc đã hết hạn (401). Kiểm tra OPENAI_API_KEY.';
      case 403:
        return 'Tài khoản không có quyền dùng model này (403). Thử đổi OPENAI_MODEL=gpt-4o-mini.';
      case 429:
        final bodyMsg = _extractOpenAiErrorMessage(body);
        if (bodyMsg != null &&
            bodyMsg.toLowerCase().contains('quota')) {
          return 'Tài khoản OpenAI đã hết credit hoặc chưa nạp tiền (429).\n\n'
              'Vào https://platform.openai.com/settings/organization/billing '
              '→ thêm phương thức thanh toán / nạp credit, rồi thử lại.\n\n'
              'App và API key của bạn đang hoạt động đúng.';
        }
        return 'Vượt giới hạn request (429). Thử lại sau vài phút.';
      default:
        break;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Hết thời gian chờ phản hồi. Kiểm tra mạng và thử lại.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Không kết nối được OpenAI. Kiểm tra internet.';
    }

    return e.message ?? 'Lỗi không xác định khi gọi OpenAI.';
  }

  String? _extractOpenAiErrorMessage(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final err = body['error'];
    if (err is Map<String, dynamic>) {
      final msg = err['message'];
      if (msg is String) return msg;
    }
    return null;
  }
}

class OpenAiChatException implements Exception {
  OpenAiChatException(this.message);
  final String message;

  @override
  String toString() => message;
}
