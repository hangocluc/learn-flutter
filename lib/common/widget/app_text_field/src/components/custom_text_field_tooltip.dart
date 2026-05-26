import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:learn_flutter/core/extension/src/string_extension.dart';
import '../../../../../main.dart';
import '../../../../generate/assets.gen.dart';
import '../../../../theme/app_color.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../app_icon/app_asset_image.dart';
import '../../../app_tooltip/custom_path_builder.dart';

const CUSTOM_TEXTFIELD_MAX_LENGHT = 255;
const CUSTOM_TEXTFIELD_MAX_LINE = 1;

class AppCustomTextFieldToolTip extends StatefulWidget {
  final String title;
  final String? suffixIcon;
  final FocusNode? node;
  final TextEditingController? controller;
  final String? initData;
  final String? hintText;
  final Function(String? value)? onChange;
  final String? Function(String?)? validator;
  final VoidCallback? onTapSuffixIcon;
  final VoidCallback? onTap;
  final VoidCallback? onInputComplete;
  final bool? readOnly;
  final bool? enable;
  final int? maxLength;
  final int? maxLine;
  final ValueNotifier<String?>? errorText;
  final bool obscureText;
  final bool? isRequired;
  final TextInputType? textInputType;
  final JustTheController? tooltipController;
  final Widget? tooltipWidget;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final List<TextInputFormatter>? inputFormatters;
  final bool isModal;
  final bool isDropDown;
  final String? prefixIcon;

  const AppCustomTextFieldToolTip({
    super.key,
    required this.title,
    this.suffixIcon,
    this.hintText,
    this.node,
    this.controller,
    this.initData,
    this.onChange,
    this.onInputComplete,
    this.readOnly,
    this.onTap,
    this.maxLength,
    this.maxLine,
    this.validator,
    this.enable,
    this.errorText,
    this.onTapSuffixIcon,
    this.isRequired,
    this.textInputType,
    this.obscureText = false,
    this.tooltipController,
    this.tooltipWidget,
    this.margin,
    this.width,
    this.inputFormatters,
    this.isModal = true,
    this.isDropDown = false,
    this.prefixIcon,
  });

  @override
  State<AppCustomTextFieldToolTip> createState() =>
      _AppCustomTextFieldToolTipState();
}

class _AppCustomTextFieldToolTipState extends State<AppCustomTextFieldToolTip> {
  late TextEditingController _controller;
  late FocusNode _node;

  @override
  void initState() {
    initDataAndController();
    super.initState();
  }

  ValueNotifier<bool> focusValue = ValueNotifier(false);
  ValueNotifier<String?> error = ValueNotifier(null);

  void initDataAndController() {
    if (widget.controller == null) {
      _controller = TextEditingController();
    } else {
      _controller = widget.controller!;
    }
    if (widget.node == null) {
      _node = FocusNode();
    } else {
      _node = widget.node!;
    }
    _node.addListener(
      () {
        if (_node.hasFocus) {
          focusValue.value = true;
        } else {
          focusValue.value = false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing2),
            child: RichText(
              text: TextSpan(
                  text: widget.title,
                  style: AppTypography().bodySmallRegular.copyWith(
                        color: AppColors.theBlack.theBlack900,
                      ),
                  children: [
                    ...widget.isRequired == true
                        ? [
                            TextSpan(
                              text: '*',
                              style: AppTypography().bodySmallRegular.copyWith(
                                    color: AppColors.red.red500,
                                  ),
                            )
                          ]
                        : [],
                  ]),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: focusValue,
            builder: (context, value, child) {
              return JustTheTooltip(
                backgroundColor: AppColors.secondary.secondary400,
                controller: widget.tooltipController,
                preferredDirection: AxisDirection.up,
                margin: widget.margin ??
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                isModal: false,
                tailBuilder: (anchor, tip, end) {
                  return CustomPathBuilder.buildCustomTail(
                      anchor, tip, end, context);
                },
                content: widget.tooltipWidget ?? Container(),
                child: ValueListenableBuilder<String?>(
                    valueListenable: widget.errorText ?? ValueNotifier(''),
                    builder: (context, errorMessage, child) {
                      return Container(
                        width: widget.width ?? MediaQuery.sizeOf(context).width,
                        decoration: BoxDecoration(
                          color: widget.readOnly ?? false
                              ? AppColors.theBlack.theBlack50
                              : AppColors.white.white,
                          boxShadow: value
                              ? [
                                  BoxShadow(
                                      offset: const Offset(0, 0),
                                      blurRadius: 0,
                                      spreadRadius: 3,
                                      color: errorMessage != null &&
                                              errorMessage.isNotEmpty
                                          ? AppColors.other.ColorFDD9DF
                                          : AppColors.primary.primary200)
                                ]
                              : (widget.errorText?.value ?? '').isNotEmpty
                                  ? [
                                      BoxShadow(
                                          offset: const Offset(0, 0),
                                          blurRadius: 0,
                                          spreadRadius: 3,
                                          color: AppColors.other.ColorFDD9DF)
                                    ]
                                  : [],
                          border:
                              Border.all(color: AppColors.theBlack.theBlack200),
                          borderRadius:
                              const BorderRadius.all(AppRadius.radius4),
                        ),
                        child: TextFormField(
                          obscureText: widget.obscureText,
                          readOnly: widget.readOnly ?? false,
                          keyboardType: widget.textInputType,
                          onChanged: (value) {
                            if (widget.onChange != null) {
                              widget.onChange!(value);
                            }
                          },
                          onTap: () {
                            if (widget.onTap != null) {
                              widget.onTap!();
                            }
                          },
                          inputFormatters: widget.inputFormatters,
                          onEditingComplete: widget.onInputComplete,
                          controller: _controller,
                          focusNode: _node,
                          enabled: widget.enable ?? true,
                          maxLength:
                              widget.maxLength ?? CUSTOM_TEXTFIELD_MAX_LENGHT,
                          maxLines: widget.maxLine ?? CUSTOM_TEXTFIELD_MAX_LINE,
                          buildCounter: (context,
                              {required currentLength,
                              required isFocused,
                              required maxLength}) {
                            return null;
                          },
                          validator: (value) {
                            if (widget.validator != null) {
                              error.value = widget.validator!(value);
                            }
                            return null;
                          },
                          style: AppTypography().bodyMediumRegular.copyWith(
                                color: AppColors.theBlack.theBlack900,
                              ),
                          initialValue: widget.initData,
                          decoration: InputDecoration(
                            prefixIcon: (widget.prefixIcon ?? '').isNotEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(
                                        AppSpacing.spacing3),
                                    child: AppAssetImage(
                                      path: widget.prefixIcon ??
                                          appIcon.icLocked.path,
                                      width: 24.w,
                                      height: 24.h,
                                      color: AppColors.theBlack.theBlack800,
                                    ),
                                  )
                                : null,
                            border: widget.readOnly ?? false
                                ? InputBorder.none
                                : null,
                            hintText: widget.hintText,
                            hintStyle: AppTypography()
                                .bodyMediumRegular
                                .copyWith(
                                    color: AppColors.theBlack.theBlack300),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 12.h),
                            fillColor: AppColors.white.white,
                            suffixIcon: GestureDetector(
                              onTap: () {
                                if (widget.onTapSuffixIcon != null) {
                                  widget.onTapSuffixIcon!();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: AppSpacing.spacing3),
                                child: SizedBox(
                                  height: 24.h,
                                  width: widget.isDropDown ? null : 24.w,
                                  child: widget.suffixIcon.isNotNullOrEmpty
                                      ? AppAssetImage(
                                          path: widget.suffixIcon!,
                                          color: AppColors.theBlack.theBlack800,
                                        )
                                      : Container(),
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(AppRadius.radius4),
                              borderSide: BorderSide(
                                color: errorMessage != null &&
                                        errorMessage.isNotEmpty
                                    ? AppColors.red.red500
                                    : AppColors.theBlack.theBlack50,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(AppRadius.radius4),
                              borderSide: BorderSide(
                                color: errorMessage != null &&
                                        errorMessage.isNotEmpty
                                    ? AppColors.red.red500
                                    : AppColors.secondary.secondary500,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(AppRadius.radius4),
                              borderSide: BorderSide(
                                color: AppColors.red.red500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              );
            },
          ),
          ValueListenableBuilder<String?>(
            valueListenable: widget.errorText ?? ValueNotifier(''),
            builder: (context, value, child) {
              return Visibility(
                visible: value != null && value.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      AppAssetImage.icon16(
                          path: Assets.icons.icWarnningBg.path),
                      const SizedBox(
                        width: AppSpacing.spacing2,
                      ),
                      Expanded(
                        child: Text("$value",
                            style: AppTypography().bodySmallRegular.copyWith(
                                  color: AppColors.red.red500,
                                )),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
