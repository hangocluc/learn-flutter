import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_flutter/core/extension/extention.dart';
import 'package:learn_flutter/main.dart';

import '../../theme/app_color.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../app_button/app_button.dart';
import '../app_icon/app_asset_image.dart';

class AppDialogConfirm extends StatelessWidget {
  final String? title;
  final String? subTitle;
  final String? description;
  final Function onConfirm;
  final Function? onCancel;
  final String? titleConfirm;
  final String? titleCancel;
  final Color? buttonConfirmColor;
  final Color? buttonCancelColor;
  final Color? titleButtonConfirmColor;
  final Color? titleButtonCancelColor;
  final bool isShowIcClose;
  final bool isBorder;

  const AppDialogConfirm({
    super.key,
    this.title,
    this.subTitle,
    required this.onConfirm,
    this.onCancel,
    this.titleConfirm,
    this.titleCancel,
    this.buttonConfirmColor,
    this.buttonCancelColor,
    this.titleButtonConfirmColor,
    this.titleButtonCancelColor,
    this.isShowIcClose = false,
    this.description,
    this.isBorder = true,
  });

  static showAppDialogConfirm(
    BuildContext context, {
    String? title,
    String? subTitle,
    required Function onConfirm,
    Function? onCancel,
    String? titleConfirm,
    String? titleCancel,
    Color? buttonConfirmColor,
    Color? buttonCancelColor,
    Color? titleButtonConfirmColor,
    Color? titleButtonCancelColor,
    bool isShowIcClose = false,
    bool isBorder = true,
    String? description,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AppDialogConfirm(
          title: title,
          subTitle: subTitle,
          titleConfirm: titleConfirm,
          onCancel: onCancel,
          titleCancel: titleCancel,
          isShowIcClose: isShowIcClose,
          onConfirm: () => onConfirm(),
          buttonConfirmColor: buttonConfirmColor,
          buttonCancelColor: buttonCancelColor,
          titleButtonConfirmColor: titleButtonConfirmColor,
          titleButtonCancelColor: titleButtonCancelColor,
          isBorder: isBorder,
          description: description,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              child: Column(
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
                    child: Text(
                      subTitle ?? '',
                      textAlign: TextAlign.center,
                      style: AppTypography().bodySmallMedium.copyWith(
                            color: AppColors.theBlack.theBlack700,
                          ),
                    ),
                  ),
                  Visibility(
                    visible: description.isNotNullOrEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.spacing4,
                        right: AppSpacing.spacing4,
                        bottom: AppSpacing.spacing3,
                      ),
                      child: Text(
                        description ?? '',
                        textAlign: TextAlign.center,
                        style: AppTypography().bodyXSmallMedium.copyWith(
                              color: AppColors.theBlack.theBlack700,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      AppButton(
                        width: 116.w,
                        height: 56.h,
                        radius: AppRadius.radius3.x,
                        buttonColor: AppColors.secondary.secondary50,
                        borderColor:
                            isBorder ? AppColors.primary.primary400 : null,
                        margin: const EdgeInsets.only(
                            left: AppSpacing.spacing4,
                            bottom: AppSpacing.spacing4,
                            top: AppSpacing.spacing4,
                            right: AppSpacing.spacing2),
                        onTap: () {
                          Navigator.pop(context);
                          if (onCancel != null) {
                            onCancel!();
                          }
                        },
                        title: titleCancel ?? '',
                        titleStyle: AppTypography().bodySmallSemiBold.copyWith(
                              color: titleButtonCancelColor ??
                                  AppColors.theBlack.theBlack600,
                            ),
                      ),
                      Expanded(
                        child: AppButton(
                          height: 56.h,
                          radius: AppRadius.radius3.x,
                          buttonColor: AppColors.secondary.secondary400,
                          margin: const EdgeInsets.only(
                              right: AppSpacing.spacing4,
                              top: AppSpacing.spacing4,
                              bottom: AppSpacing.spacing4,
                              left: AppSpacing.spacing2),
                          onTap: () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                          title: titleConfirm ?? '',
                          titleStyle:
                              AppTypography().bodySmallSemiBold.copyWith(
                                    color: titleButtonConfirmColor ??
                                        AppColors.white.white,
                                  ),
                        ),
                      )
                    ],
                  )
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
                    Navigator.pop(context);
                  },
                  child: AppAssetImage(
                    path: appIcon.icCloseCircle.path,
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
