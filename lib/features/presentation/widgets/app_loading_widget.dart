import 'package:flutter/material.dart';
import 'package:learn_flutter/common/theme/app_color.dart';

class AppLoadingWidget extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppLoadingWidget({
    super.key,
    this.size = 36,
    this.strokeWidth = 3,
    this.color,
  });

  /// Full-screen centered loading (dùng cho page-level loading state)
  const factory AppLoadingWidget.fullScreen() = _FullScreenLoading;

  /// Nhỏ dùng inline (chat, button...)
  const factory AppLoadingWidget.small({Color? color}) = _SmallLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? AppColors.primary.primary500,
      ),
    );
  }
}

class _FullScreenLoading extends AppLoadingWidget {
  const _FullScreenLoading() : super(size: 40, strokeWidth: 3);

  @override
  Widget build(BuildContext context) {
    return const Center(child: AppLoadingWidget());
  }
}

class _SmallLoading extends AppLoadingWidget {
  const _SmallLoading({Color? color}) : super(size: 20, strokeWidth: 2, color: color);
}
