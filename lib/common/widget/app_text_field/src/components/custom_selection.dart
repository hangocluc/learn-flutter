import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_flutter/core/extension/src/string_extension.dart';
import '../../../../theme/app_color.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../app_text/app_text.dart';
import '../../app_text_field.dart';
import 'button_confirm_select.dart';
import 'dropdown_model.dart';
import 'header_dropdown.dart';

class CustomSelection extends StatefulWidget {
  final List<DropdownModel> data;
  final Function(DropdownModel? value) onSelect;
  final DropdownModel? selectedValue;
  final String titleBottomSheet;
  final String? description;
  final Function(DropdownModel? value) onChangeValue;

  const CustomSelection({
    super.key,
    required this.data,
    required this.onSelect,
    this.selectedValue,
    required this.titleBottomSheet,
    this.description,
    required this.onChangeValue,
  });

  @override
  State<CustomSelection> createState() => _CustomSelectionState();
}

class _CustomSelectionState extends State<CustomSelection> {
  DropdownModel? selectedValue;

  @override
  void initState() {
    selectedValue = widget.selectedValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white.white,
          borderRadius: const BorderRadius.only(
            topLeft: AppRadius.radius6,
            topRight: AppRadius.radius6,
          )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderDropdown(
            title: widget.titleBottomSheet,
          ),
          Visibility(
              visible: widget.description.isNotNullOrEmpty,
              child: Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.spacing4, left: AppSpacing.spacing4),
                  child: AppText(title: widget.description ?? ''))),
          Flexible(
            child: ListView.builder(
              itemCount: widget.data.length,
              shrinkWrap: true,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
              itemBuilder: (context, index) {
                final currentItem = widget.data.elementAt(index);
                return IntrinsicHeight(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedValue = currentItem;
                      });
                    },
                    child: Container(
                      width: 100.w,
                      margin: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing2,
                          horizontal: AppSpacing.spacing4),
                      decoration: BoxDecoration(
                        boxShadow: selectedValue == currentItem
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.primary200,
                                  blurRadius: 1,
                                  spreadRadius: 3.0,
                                  offset: const Offset(0, 0),
                                ),
                              ]
                            : [],
                        color: AppColors.other.ColorF8F9FA,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.spacing3),
                        border: Border.all(
                          color: selectedValue == currentItem
                              ? AppColors.primary.primary500
                              : AppColors.other.ColorF8F9FA,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing2,
                          horizontal: AppSpacing.spacing4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: AppSpacing.spacing2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentItem.getItemDisplay(),
                                    style: _getStyleSelection(
                                        selectedValue?.getItemId() !=
                                            currentItem.getItemId()),
                                  ),
                                  Visibility(
                                    visible: currentItem
                                        .getItemDescription()
                                        .isNotNullOrEmpty,
                                    child: Text(
                                      currentItem.getItemDescription() ?? '',
                                      maxLines: 2,
                                      style: AppTypography()
                                          .bodyXSmallMedium
                                          .copyWith(
                                            color:
                                                AppColors.theBlack.theBlack500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Radio<DropdownModel>(
                            groupValue: selectedValue,
                            value: currentItem,
                            activeColor: AppColors.primary.primary500,
                            fillColor: WidgetStatePropertyAll(
                                AppColors.primary.primary500),
                            onChanged: (value) {
                              setState(() {
                                selectedValue = value;
                                widget.onChangeValue(value);
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ButtonConfirmSelect(
              onTap: () {
                widget.onSelect(selectedValue);
              },
              title: 'Ok')
        ],
      ),
    );
  }

  _getStyleSelection(bool isSelect) {
    return isSelect
        ? AppTypography()
            .bodyMediumMedium
            .copyWith(color: AppColors.theBlack.theBlack700)
        : AppTypography()
            .bodyMediumSemiBold
            .copyWith(color: AppColors.theBlack.theBlack900);
  }
}
