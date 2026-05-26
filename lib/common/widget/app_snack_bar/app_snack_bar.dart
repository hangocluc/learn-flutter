import 'package:learn_flutter/common/widget/app_text/app_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../common/theme/app_color.dart';
import '../../../../../../common/theme/app_typography.dart';
import '../../../../../../common/widget/app_icon/app_asset_image.dart';
import '../../../../../../main.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../app_overlay/overlay_widget.dart';

class AppSnackBar extends StatelessWidget {
  final String? title;
  final String? pathIconLeft;
  final String? pathIconRight;
  final Color? bgColor;
  final double? topPadding;
  final TextStyle? style;
  final Color? colorIcLeft;

  const AppSnackBar({
    super.key,
    this.title,
    this.pathIconLeft,
    this.pathIconRight,
    this.bgColor,
    this.topPadding,
    this.style,
    this.colorIcLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding ?? MediaQuery.of(context).padding.top + 80.h,
        left: AppSpacing.spacing4,
        right: AppSpacing.spacing4,
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width - AppSpacing.spacing8,
        padding: EdgeInsets.only(
            bottom: 1.h, left: 1.w, right: 1.w, top: AppSpacing.spacing2),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.yellow.yellow500,
          borderRadius: const BorderRadius.all(AppRadius.radius2),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing3),
          decoration: BoxDecoration(
            color: AppColors.white.white,
            borderRadius: const BorderRadius.all(AppRadius.radius2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppAssetImage(
                      path: pathIconLeft ?? appIcon.icWarnningBg.path,
                      color: (pathIconRight ?? '').isEmpty
                          ? colorIcLeft ?? AppColors.yellow.yellow500
                          : bgColor,
                      width: 24.w,
                      height: 24.h,
                    ),
                    const SizedBox(
                      width: AppSpacing.spacing3,
                    ),
                    Expanded(
                      child: AppText(
                        title: title ?? '',
                        maxLines: 2,
                        style: style ??
                            AppTypography().bodyXSmallMedium.copyWith(
                                color: AppColors.theBlack.theBlack700),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  OverlayWidget.dismiss(animation: false);
                },
                child: AppAssetImage(
                  path: appIcon.icClose.path,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
