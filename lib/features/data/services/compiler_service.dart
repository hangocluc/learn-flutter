import 'package:flutter/services.dart';

class CompilerService {
  CompilerService();

  final _channel = MethodChannel('java_executor');

  /// Compile and run Java code
  Future<CompileResult> compileAndRun(String javaCode) async {
    try {
      String output = await _channel.invokeMethod("compileJava", javaCode);
      output = output.toString().replaceFirst("ignoring input files", "");
      output = output
          .toString()
          .replaceFirst(
              "processing /data/user/0/com.example.learn_java/files/class_output/JavaStudio.class...",
              "")
          .trim();
      return CompileResult(
        success: true,
        output: output,
        error: null,
        executionTime: 150,
      );
    } catch (e) {
      return CompileResult(
        success: false,
        output: e.toString(),
        error: e.toString(),
        executionTime: 0,
      );
    }
  }

  /// Format Java code
  Future<String?> formatCode(String javaCode) async {
    try {
      // For now, return the original code
      // In a real implementation, you would use a Java formatter
      await Future.delayed(const Duration(milliseconds: 500));
      return javaCode;
    } catch (e) {
      return null;
    }
  }

  /// Validate Java syntax
  Future<ValidationResult> validateSyntax(String javaCode) async {
    try {
      // Basic syntax validation
      bool hasMainMethod = javaCode.contains('public static void main');
      bool hasClass = javaCode.contains('class ');
      bool hasBrackets = _countBrackets(javaCode);

      List<String> errors = [];
      if (!hasClass) errors.add('Missing class declaration');
      if (!hasMainMethod) errors.add('Missing main method');
      if (!hasBrackets) errors.add('Unmatched brackets');

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: [e.toString()],
      );
    }
  }

  bool _countBrackets(String code) {
    int openBrackets = 0;
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '{') openBrackets++;
      if (code[i] == '}') openBrackets--;
      if (openBrackets < 0) return false;
    }
    return openBrackets == 0;
  }
}

class CompileResult {
  final bool success;
  final String? output;
  final String? error;
  final int executionTime; // in milliseconds

  CompileResult({
    required this.success,
    this.output,
    this.error,
    required this.executionTime,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}
