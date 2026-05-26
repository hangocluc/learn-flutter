import 'package:learn_flutter/common/theme/app_color.dart';
import 'package:learn_flutter/common/theme/app_effect.dart';
import 'package:learn_flutter/common/theme/app_radius.dart';
import 'package:learn_flutter/common/theme/app_typography.dart';
import 'package:learn_flutter/common/widget/app_icon/app_asset_image.dart';
import 'package:learn_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_spacing.dart';
import '../app_button/app_button.dart';

class AppDialog extends StatelessWidget {
  final String? title;
  final String? icon;
  final bool isShowIcon;
  final String? subTitle;
  final Widget? subTitleWidget;
  final Function? onDone;
  final String? titleButton;
  final Widget? dialogWidget;
  final bool isShowIcClose;
  final Widget? widgetMoreInfo;
  final bool barrierDismissible;
  final MainAxisAlignment? mainAxisAlignment;
  final Color? barrierColor;
  final Function? onClose;

  const AppDialog(
      {super.key,
      this.title,
      this.icon,
      this.subTitle,
      this.titleButton,
      this.onDone,
      this.dialogWidget,
      this.widgetMoreInfo,
      this.barrierDismissible = true,
      this.mainAxisAlignment,
      this.barrierColor,
      this.isShowIcClose = false,
      required this.isShowIcon,
      this.subTitleWidget,
      this.onClose});

  static Future showAppDialog(
    BuildContext context, {
    String? title,
    String? subTitle,
    Widget? subTitleWidget,
    String? icon,
    bool isShowIcon = true,
    final String? titleButton,
    Function? onDone,
    final Widget? dialogWidget,
    bool? isShowIcClose,
    Widget? widgetMoreInfo,
    bool barrierDismissible = true,
    final Color? barrierColor,
    MainAxisAlignment? mainAxisAlignment,
    final Function? onClose,
  }) async {
    await showDialog(
      context: context,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return AppDialog(
          title: title,
          icon: icon,
          isShowIcon: isShowIcon,
          subTitle: subTitle,
          subTitleWidget: subTitleWidget,
          titleButton: titleButton,
          isShowIcClose: isShowIcClose ?? false,
          dialogWidget: dialogWidget,
          widgetMoreInfo: widgetMoreInfo,
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.spaceAround,
          onDone: () {
            if (onDone != null) {
              onDone();
            }
          },
          onClose: () {
            if (onClose != null) {
              onClose();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.spaceAround,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              margin:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(AppRadius.radius3),
              ),
              child: dialogWidget ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.spacing4,
                          right: AppSpacing.spacing4,
                          top: AppSpacing.spacing6,
                          bottom: AppSpacing.spacing3,
                        ),
                        child: Text(
                          title ?? '',
                          textAlign: TextAlign.center,
                          style: AppTypography().heading5.copyWith(
                                color: AppColors.theBlack.theBlack900,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.spacing4,
                          right: AppSpacing.spacing4,
                          bottom: AppSpacing.spacing3,
                        ),
                        child: subTitleWidget ??
                            Text(
                              subTitle ?? '',
                              textAlign: TextAlign.center,
                              style: AppTypography().bodySmallMedium.copyWith(
                                    color: AppColors.theBlack.theBlack700,
                                  ),
                            ),
                      ),
                      Visibility(
                        visible: isShowIcon,
                        child: AppAssetImage(
                          path: icon ?? '',
                          width: 200.w,
                        ),
                      ),
                      widgetMoreInfo ?? const SizedBox(),
                      AppButton(
                        radius: AppRadius.radius3.x,
                        buttonColor: AppColors.primary.primary400,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing3,
                          horizontal: AppSpacing.spacing5,
                        ),
                        margin: const EdgeInsets.all(AppSpacing.spacing4),
                        onTap: () {
                          Navigator.pop(context);
                          if (onDone != null) {
                            onDone!();
                          }
                        },
                        title: titleButton ?? '',
                        titleStyle: AppTypography().bodyMediumSemiBold.copyWith(
                              color: AppColors.white.white,
                            ),
                      ),
                    ],
                  ),
            ),
            Visibility(
              visible: isShowIcClose,
              child: Positioned(
                right: 6,
                top: -10,
                child: GestureDetector(
                  onTap: () {
                    if (onClose != null) {
                      onClose!();
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [AppEffect.shadow.boxXS],
                    ),
                    child: AppAssetImage(
                      path: appIcon.icCloseCircle.path,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}
