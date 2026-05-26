import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../common/theme/app_color.dart';
import '../../../../../common/theme/app_spacing.dart';
import '../../../../../common/theme/app_typography.dart';
import '../../../../../common/widget/app_icon/app_asset_image.dart';
import '../../../../../common/widget/app_icon/app_network_image.dart';
import 'package:learn_flutter/core/extension/src/string_extension.dart';

import '../../theme/app_radius.dart';

class AppSwitchComponentSync extends StatefulWidget {
  final String iconPath;
  final String title;
  final String? description;
  final bool initValue;
  final bool hasBorder;
  final Function(bool value) onChange;
  final Decoration? decoration;
  final Widget? customSwitch;
  final EdgeInsetsGeometry? padding;
  final String? iconUrl;
  final TextStyle? titleStyle;
  final Future<bool> Function(bool? value)? onRequestChange;

  const AppSwitchComponentSync(
      {super.key,
      required this.iconPath,
      required this.title,
      this.description,
      this.initValue = false,
      this.hasBorder = true,
      required this.onChange,
      this.customSwitch,
      this.decoration,
      this.padding,
      this.iconUrl,
      this.titleStyle,
      this.onRequestChange});

  @override
  State<AppSwitchComponentSync> createState() => _AppSwitchComponentSyncState();
}

class _AppSwitchComponentSyncState extends State<AppSwitchComponentSync> {
  bool _isToggled = false;

  @override
  void initState() {
    _isToggled = widget.initValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
      decoration: widget.hasBorder
          ? widget.decoration ??
              BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      width: 1, color: AppColors.theBlack.theBlack50),
                ),
              )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Visibility(
            visible: widget.iconPath.isNotEmpty,
            child: SizedBox.square(
                dimension: 24.w, child: AppAssetImage(path: widget.iconPath)),
          ),
          Visibility(
            visible: widget.iconUrl.isNotNullOrEmpty,
            child: SizedBox.square(
                dimension: 24.w,
                child: AppNetworkImage(imageUrl: widget.iconUrl ?? '')),
          ),
          SizedBox(
            width: 7.5.w,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: widget.titleStyle ??
                      AppTypography().bodySmallSemiBold.copyWith(
                            color: AppColors.theBlack.theBlack900,
                          ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Visibility(
                  visible: (widget.description ?? '').isNotEmpty,
                  child: Text(
                    widget.description ?? '',
                    style: AppTypography().bodyXSmallRegular.copyWith(
                          color: AppColors.theBlack.theBlack500,
                        ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          widget.customSwitch ??
              GestureDetector(
                onTap: () async {
                  if (widget.onRequestChange != null) {
                    widget.onRequestChange!(!_isToggled).then((value) {
                      setState(() {
                        _isToggled = value;
                      });
                      widget.onChange(_isToggled);
                    });
                  } else {
                    setState(() {
                      _isToggled = !_isToggled;
                    });
                    widget.onChange(_isToggled);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 32.w,
                  width: 60.w,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(AppRadius.radius3),
                    color: _isToggled
                        ? AppColors.secondary.secondary100
                        : AppColors.theBlack.theBlack100,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: _isToggled
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      height: 28.h,
                      width: 28.w,
                      decoration: BoxDecoration(
                        color: _isToggled
                            ? AppColors.primary.primary400
                            : AppColors.white.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              )
        ],
      ),
    );
  }
}
