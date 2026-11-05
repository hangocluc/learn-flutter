import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/languages/dart.dart' as highlight_lang;

/// DartPad-style dark editor (TextField + [CodeController] for highlight).
class CodeEditorWidget extends StatefulWidget {
  const CodeEditorWidget({
    super.key,
    required this.initialCode,
    required this.onCodeChanged,
    this.readOnly = false,
    this.onFormat,
  });

  final String initialCode;
  final ValueChanged<String> onCodeChanged;
  final bool readOnly;
  final Future<String?> Function(String source)? onFormat;

  static const Color editorBg = Color(0xFF1E1E1E);
  static const Color toolbarBg = Color(0xFF2D2D30);
  static const Color cursorBlue = Color(0xFF168AFD);

  static const EdgeInsets editorPadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

  /// VS2015 + punctuation / default text visible on dark bg.
  static final Map<String, TextStyle> dartEditorTheme = {
    ...vs2015Theme,
    'root': vs2015Theme['root']!.copyWith(color: const Color(0xFFDCDCDC)),
    'punctuation': const TextStyle(color: Color(0xFFD4D4D4)),
  };

  @override
  State<CodeEditorWidget> createState() => CodeEditorWidgetState();
}

class CodeEditorWidgetState extends State<CodeEditorWidget> {
  late final CodeController _controller;
  late final FocusNode _focusNode;
  bool _formatting = false;

  TextStyle get _monoStyle => GoogleFonts.robotoMono(
        fontSize: 14,
        height: 1.5,
        color: const Color(0xFFDCDCDC),
      );

  /// Brackets stand out; `${...}` segments get an extra pass via patterns.
  static final Map<String, TextStyle> _bracketStyles = {
    r'[\(\)\{\}\[\]]': const TextStyle(color: Color(0xFFD7BA7D)),
    r'\$\{[^}]*\}': const TextStyle(color: Color(0xFF9CDCFE)),
  };

  String get code => _controller.text;

  void updateCode(String code) {
    _controller.text = code;
    widget.onCodeChanged(code);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = CodeController(
      text: widget.initialCode.trim(),
      language: highlight_lang.dart,
      patternMap: _bracketStyles,
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.onCodeChanged(_controller.text);
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã copy code'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _formatCode() async {
    if (widget.onFormat == null || _formatting) return;

    setState(() => _formatting = true);
    try {
      final formatted = await widget.onFormat!(_controller.text);
      if (formatted != null && mounted) {
        updateCode(formatted);
      }
    } finally {
      if (mounted) setState(() => _formatting = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showActions = !widget.readOnly;

    return ColoredBox(
      color: CodeEditorWidget.editorBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            color: CodeEditorWidget.toolbarBg,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(Icons.description_outlined,
                    size: 15, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  'main.dart',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (showActions) ...[
                  if (widget.onFormat != null)
                    TextButton(
                      onPressed: _formatting ? null : _formatCode,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _formatting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Format',
                              style: GoogleFonts.robotoMono(fontSize: 12),
                            ),
                    ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: _copyCode,
                    icon: Icon(
                      Icons.copy,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: widget.readOnly
                ? SingleChildScrollView(
                    padding: CodeEditorWidget.editorPadding,
                    child: HighlightView(
                      widget.initialCode,
                      language: 'dart',
                      theme: CodeEditorWidget.dartEditorTheme,
                      textStyle: _monoStyle,
                    ),
                  )
                : CodeTheme(
                    data: CodeThemeData(styles: CodeEditorWidget.dartEditorTheme),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        brightness: Brightness.dark,
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: CodeEditorWidget.cursorBlue,
                          selectionColor:
                              CodeEditorWidget.cursorBlue.withOpacity(0.35),
                        ),
                        inputDecorationTheme: const InputDecorationTheme(
                          filled: true,
                          fillColor: CodeEditorWidget.editorBg,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: CodeEditorWidget.editorPadding,
                          isDense: true,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        style: _monoStyle,
                        cursorColor: CodeEditorWidget.cursorBlue,
                        keyboardType: TextInputType.multiline,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartQuotesType: SmartQuotesType.disabled,
                        decoration: const InputDecoration(
                          hintText: '// Viết code Dart tại đây',
                          hintStyle: TextStyle(color: Color(0xFF6A6A6A)),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
