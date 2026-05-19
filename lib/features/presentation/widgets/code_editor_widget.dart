import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
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
  });

  final String initialCode;
  final ValueChanged<String> onCodeChanged;
  final bool readOnly;

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
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late final CodeController _controller;
  late final FocusNode _focusNode;

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

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CodeEditorWidget.editorBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            color: CodeEditorWidget.toolbarBg,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
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
