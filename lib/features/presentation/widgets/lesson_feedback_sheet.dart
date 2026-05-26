import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences_key.dart';
import 'package:learn_flutter/common/utils/snack_bar_utils.dart';
import 'package:learn_flutter/features/data/models/feedback/system_feedback_request_model.dart';
import 'package:learn_flutter/features/data/models/lesson_model/lesson_feedback_request_model.dart';
import 'package:learn_flutter/core/base/src/api_response.dart';
import 'package:learn_flutter/features/data/providers/feedback_service/feedback_service.dart';
import 'package:learn_flutter/main.dart';

enum FeedbackScope { lesson, system }

/// Context for a lesson feedback report (topic, video, code, etc.).
class LessonFeedbackParams {
  const LessonFeedbackParams({
    this.lessonId,
    this.topicId,
    this.lessonTitle,
    this.topicTitle,
    this.errorDetail,
    this.defaultErrorType = 'other',
  });

  final String? lessonId;
  final String? topicId;
  final String? lessonTitle;
  final String? topicTitle;
  final String? errorDetail;
  final String defaultErrorType;
}

class LessonFeedbackSheet {
  static const _lessonErrorTypes = <String, String>{
    'video': 'Video không phát được',
    'content': 'Nội dung bài học sai/thiếu',
    'code': 'Code / bài tập lỗi',
    'quiz': 'Câu hỏi / quiz lỗi',
    'other': 'Lỗi khác',
  };

  static const _systemCategories = <String, String>{
    'bug': 'App bug',
    'ui': 'UI / UX',
    'performance': 'Slow / freezing',
    'suggestion': 'Feature suggestion',
    'other': 'Other',
  };

  /// Báo lỗi nội dung bài học → `POST /api/insert-lesson-feedback`
  static Future<void> showLesson(
    BuildContext context, {
    required LessonFeedbackParams params,
  }) {
    return _show(
      context,
      scope: FeedbackScope.lesson,
      lessonParams: params,
    );
  }

  /// Phản hồi hệ thống / app → `POST /api/insert-system-feedback`
  static Future<void> showSystem(BuildContext context) {
    return _show(
      context,
      scope: FeedbackScope.system,
      lessonParams: const LessonFeedbackParams(),
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required FeedbackScope scope,
    required LessonFeedbackParams lessonParams,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FeedbackForm(
        scope: scope,
        lessonParams: lessonParams,
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm({
    required this.scope,
    required this.lessonParams,
  });

  final FeedbackScope scope;
  final LessonFeedbackParams lessonParams;

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  late String _selectedType;
  final _messageController = TextEditingController();
  bool _submitting = false;

  bool get _isLesson => widget.scope == FeedbackScope.lesson;

  @override
  void initState() {
    super.initState();
    if (_isLesson) {
      _selectedType = widget.lessonParams.defaultErrorType;
      if (!LessonFeedbackSheet._lessonErrorTypes.containsKey(_selectedType)) {
        _selectedType = 'other';
      }
    } else {
      _selectedType = 'bug';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 5) {
      showSnackBarFail(
        context,
        title: 'Please enter at least 5 characters',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final prefs = getIt<AppSharedPreferences>();
      final userId =
          prefs.get(AppSharedPreferencesKey.userId) as String?;
      final feedbackService = getIt<FeedbackService>();

      final ApiResponse<dynamic> response;
      if (_isLesson) {
        response = await feedbackService.insertLessonFeedback(
          LessonFeedbackRequestModel(
            userId: userId,
            lessonId: widget.lessonParams.lessonId,
            topicId: widget.lessonParams.topicId,
            lessonTitle: widget.lessonParams.lessonTitle,
            topicTitle: widget.lessonParams.topicTitle,
            errorType: _selectedType,
            message: message,
            errorDetail: widget.lessonParams.errorDetail,
          ),
        );
      } else {
        response = await feedbackService.insertSystemFeedback(
          SystemFeedbackRequestModel(
            userId: userId,
            category: _selectedType,
            message: message,
            platform: _platformLabel(),
          ),
        );
      }

      if (!mounted) return;

      if (response.isSuccessResponse) {
        Navigator.of(context).pop();
        showSnackBarSuccess(
          context,
          title: response.message ?? 'Feedback sent. Thank you!',
        );
      } else {
        showSnackBarFail(
          context,
          title: response.message ?? 'Failed to send feedback',
        );
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBarFail(context, title: 'Failed to send feedback: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final typeOptions =
        _isLesson ? LessonFeedbackSheet._lessonErrorTypes : LessonFeedbackSheet._systemCategories;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isLesson ? 'Báo lỗi bài học' : 'System Feedback',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLesson
                ? 'Mô tả lỗi nội dung bài học để team cập nhật.'
                : 'Report app bugs, suggest features, or share your experience.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (_isLesson &&
              widget.lessonParams.errorDetail != null &&
              widget.lessonParams.errorDetail!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.lessonParams.errorDetail!.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onErrorContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: _isLesson ? 'Loại lỗi' : 'Category',
              border: const OutlineInputBorder(),
            ),
            items: typeOptions.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: _submitting
                ? null
                : (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: _isLesson ? 'Mô tả chi tiết' : 'Details',
              hintText: _isLesson
                  ? 'Ví dụ: video báo lỗi 153, nội dung trống...'
                  : 'e.g. slow login, button not working...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Sending...' : 'Send feedback'),
          ),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: Text(_isLesson ? 'Đóng' : 'Close'),
          ),
        ],
      ),
    );
  }
}

/// Banner shown on lesson error screens with a feedback action.
class LessonFeedbackErrorBanner extends StatelessWidget {
  const LessonFeedbackErrorBanner({
    super.key,
    required this.params,
    required this.message,
  });

  final LessonFeedbackParams params;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.report_problem_outlined, color: scheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => LessonFeedbackSheet.showLesson(
              context,
              params: params,
            ),
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Gửi phản hồi / báo lỗi bài học'),
          ),
        ],
      ),
    );
  }
}
