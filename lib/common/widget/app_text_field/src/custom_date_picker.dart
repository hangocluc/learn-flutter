import 'package:learn_flutter/core/extension/src/date_time_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../main.dart';
import '../../../theme/app_color.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../app_calendar/app_calendar.dart';
import '../../app_icon/app_asset_image.dart';
import 'custom_text_field.dart';

class AppCustomDatePicker extends StatefulWidget {
  final String title;
  final DateTime? selectedDate;
  final Function(DateTime? value) onChange;
  final bool? isRequired;
  final TextEditingController? controller;
  final ValueNotifier<String?>? errorText;
  final String? surfixIcon;
  final FocusNode? node;
  final bool? enable;

  const AppCustomDatePicker({
    super.key,
    required this.title,
    required this.onChange,
    this.selectedDate,
    this.isRequired,
    this.controller,
    this.errorText,
    this.surfixIcon,
    this.node,
    this.enable,
  });

  @override
  State<AppCustomDatePicker> createState() => _AppCustomDatePickerState();
}

class _AppCustomDatePickerState extends State<AppCustomDatePicker> {
  late TextEditingController _controller;

  DateTime? selectedDate;
  @override
  void initState() {
    selectedDate = widget.selectedDate;
    _controller = widget.controller ?? TextEditingController();
    _controller.text = selectedDate.convertStringJapanType ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppCustomTextField(
      title: widget.title,
      suffixIcon: widget.surfixIcon ?? appIcon.icCalendar.path,
      readOnly: true,
      node: widget.node,
      controller: _controller,
      isRequired: widget.isRequired,
      errorText: widget.errorText,
      enable: widget.enable,
      onTap: () {
        _onSelect(context);
      },
      onTapSuffixIcon: () {
        _onSelect(context);
      },
    );
  }

  _onSelect(BuildContext context) {
    if (!(widget.enable ?? true)) {
      return;
    }
    showModalBottomSheet(
      backgroundColor: AppColors.white.white,
      context: context,
      builder: (context) {
        return CustomDatepickerBottomSheet(
          onChange: (DateTime? value) {
            selectedDate = value;
            widget.onChange(value);
            if (value != null) {
              _controller.text = value.convertStringDYMD;
            } else {
              _controller.text = '';
            }
            Future.delayed(const Duration(milliseconds: 200)).whenComplete(
              () {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            );
          },
          title: widget.title,
          selectedDate: selectedDate,
        );
      },
    );
  }
}

class CustomDatepickerBottomSheet extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime? value) onChange;
  final String title;

  const CustomDatepickerBottomSheet(
      {super.key,
      required this.onChange,
      this.selectedDate,
      required this.title});

  @override
  State<CustomDatepickerBottomSheet> createState() =>
      _CustomDatePickerBottomSheetState();
}

class _CustomDatePickerBottomSheetState
    extends State<CustomDatepickerBottomSheet> {
  final now = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.white,
        borderRadius: const BorderRadius.only(
            topLeft: AppRadius.radius6, topRight: AppRadius.radius6),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing4, vertical: AppSpacing.spacing6),
            decoration: BoxDecoration(
                color: AppColors.white.white,
                borderRadius: const BorderRadius.only(
                    topLeft: AppRadius.radius6, topRight: AppRadius.radius6),
                border: Border(
                    bottom: BorderSide(
                  width: 1.h,
                  color: AppColors.theBlack.theBlack50,
                ))),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography()
                        .bodyMediumSemiBold
                        .copyWith(color: AppColors.theBlack.theBlack900),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.spacing2),
                        child: AppAssetImage(path: appIcon.icClose.path)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: AppSpacing.spacing4,
          ),
          AppCalendar(
            initialDate: widget.selectedDate ?? now,
            onSelectDate: (DateTime value) {
              widget.onChange(value);
            },
          ),
        ],
      ),
    );
  }
}
