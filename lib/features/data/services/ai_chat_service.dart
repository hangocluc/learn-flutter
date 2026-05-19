import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_java/features/data/services/gemini_chat_service.dart';
import 'package:learn_java/features/data/services/groq_chat_service.dart';
import 'package:learn_java/features/data/services/openai_chat_service.dart';

enum AiChatProvider { groq, gemini, openai }

/// `CHAT_PROVIDER=groq` (free, khuyên dùng) | gemini | openai
class AiChatService {
  AiChatService({
    OpenAiChatService? openAi,
    GeminiChatService? gemini,
    GroqChatService? groq,
  })  : _openAi = openAi ?? OpenAiChatService(),
        _gemini = gemini ?? GeminiChatService(),
        _groq = groq ?? GroqChatService();

  final OpenAiChatService _openAi;
  final GeminiChatService _gemini;
  final GroqChatService _groq;

  String? get _forcedProvider =>
      dotenv.env['CHAT_PROVIDER']?.trim().toLowerCase();

  AiChatProvider get activeProvider {
    final forced = _forcedProvider;
    if (forced == 'groq') return AiChatProvider.groq;
    if (forced == 'gemini') return AiChatProvider.gemini;
    if (forced == 'openai') return AiChatProvider.openai;
    if (_groq.isConfigured) return AiChatProvider.groq;
    if (_gemini.isConfigured) return AiChatProvider.gemini;
    if (_openAi.isConfigured) return AiChatProvider.openai;
    return AiChatProvider.groq;
  }

  String get providerLabel {
    switch (activeProvider) {
      case AiChatProvider.groq:
        return 'Groq (free)';
      case AiChatProvider.gemini:
        return 'Gemini';
      case AiChatProvider.openai:
        return 'OpenAI';
    }
  }

  bool get isConfigured {
    switch (activeProvider) {
      case AiChatProvider.groq:
        return _groq.isConfigured;
      case AiChatProvider.gemini:
        return _gemini.isConfigured;
      case AiChatProvider.openai:
        return _openAi.isConfigured;
    }
  }

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>>? history,
  }) async {
    final provider = activeProvider;

    switch (provider) {
      case AiChatProvider.groq:
        if (!_groq.isConfigured) {
          throw OpenAiChatException(
            'CHAT_PROVIDER=groq nhưng GROQ_API_KEY trống.\n'
            'Lấy key free: https://console.groq.com/keys',
          );
        }
        return _groq.sendMessage(
          userMessage: userMessage,
          history: history,
        );

      case AiChatProvider.gemini:
        if (!_gemini.isConfigured) {
          throw OpenAiChatException(
            'CHAT_PROVIDER=gemini nhưng GEMINI_API_KEY trống.\n'
            'Lấy key: https://aistudio.google.com/apikey',
          );
        }
        try {
          return await _gemini.sendMessage(
            userMessage: userMessage,
            history: history,
          );
        } on OpenAiChatException {
          if (_groq.isConfigured) {
            return _groq.sendMessage(
              userMessage: userMessage,
              history: history,
            );
          }
          rethrow;
        }

      case AiChatProvider.openai:
        if (!_openAi.isConfigured) {
          throw OpenAiChatException('OPENAI_API_KEY trống (cần billing).');
        }
        try {
          return await _openAi.sendMessage(
            userMessage: userMessage,
            history: history,
          );
        } on OpenAiChatException catch (e) {
          final quota = e.message.contains('429') ||
              e.message.toLowerCase().contains('quota');
          if (quota && _groq.isConfigured) {
            return _groq.sendMessage(
              userMessage: userMessage,
              history: history,
            );
          }
          if (quota && _gemini.isConfigured) {
            return _gemini.sendMessage(
              userMessage: userMessage,
              history: history,
            );
          }
          rethrow;
        }
    }
  }
}
