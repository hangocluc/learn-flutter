import 'package:flutter/material.dart';
import 'package:learn_java/features/data/services/ai_chat_service.dart';
import 'package:learn_java/features/data/services/openai_chat_service.dart';

class ChatGptPage extends StatefulWidget {
  const ChatGptPage({super.key});

  @override
  State<ChatGptPage> createState() => _ChatGptPageState();
}

class _ChatGptPageState extends State<ChatGptPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = AiChatService();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.assistant,
      text:
          'Xin chào! Mình là trợ lý học Flutter.\n\n'
          'Hỏi về widget, state, layout, API, Firebase… mình sẽ trả lời ngắn gọn.',
    ),
  ];

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _historyExcludingWelcome() {
    final history = <Map<String, String>>[];
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (i == 0 && m.role == _ChatRole.assistant) continue;
      history.add({
        'role': m.role == _ChatRole.user ? 'user' : 'assistant',
        'content': m.text,
      });
    }
    return history;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: _ChatRole.user, text: text));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final history = _historyExcludingWelcome();
      history.removeLast();

      final reply = await _ai.sendMessage(
        userMessage: text,
        history: history.isEmpty ? null : history,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: _ChatRole.assistant, text: reply));
      });
    } on OpenAiChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(role: _ChatRole.assistant, text: e.message),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text: 'Có lỗi: $e',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final configured = _ai.isConfigured;
    final providerLabel = _ai.providerLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatGPT'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                configured ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 18,
                color: configured ? Colors.green : Colors.orange,
              ),
              label: Text(
                configured ? providerLabel : 'Chưa có key',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!configured)
            MaterialBanner(
              content: const Text(
                'Free: GROQ_API_KEY tại console.groq.com/keys\n'
                'Đặt CHAT_PROVIDER=groq trong env, full restart app.',
              ),
              leading: Icon(Icons.key_off_rounded, color: scheme.error),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Hỏi về Flutter…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});
  final _ChatRole role;
  final String text;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == _ChatRole.user;
    final bg = isUser ? scheme.primary : scheme.surface;
    final fg = isUser ? Colors.white : scheme.onSurface;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 18),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: isUser
                  ? null
                  : Border.all(color: scheme.primary.withOpacity(0.10)),
            ),
            child: SelectableText(
              message.text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
