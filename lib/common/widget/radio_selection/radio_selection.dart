import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_flutter/core/extension/src/string_extension.dart';
import '../../theme/app_color.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'radio_model.dart';

class CustomRadioSelection extends StatefulWidget {
  final List<RadioModel> data;
  final Function(RadioModel? value) onSelect;
  final RadioModel? selectedValue;

  const CustomRadioSelection({
    super.key,
    required this.data,
    required this.onSelect,
    this.selectedValue,
  });

  @override
  State<CustomRadioSelection> createState() => _CustomRadioSelectionState();
}

class _CustomRadioSelectionState extends State<CustomRadioSelection> {
  RadioModel? selectedValue;

  @override
  void initState() {
    selectedValue = widget.selectedValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.data.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final items = widget.data[index];
        final isSelected = selectedValue == items;
        return IntrinsicHeight(
          child: GestureDetector(
            onTap: () {
              setState(() {
                final value = widget.data.elementAt(index);
                selectedValue = value;
                widget.onSelect(value);
              });
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(
                top: AppSpacing.spacing2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20.w,
                    height: 20.h,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.primary700
                            : AppColors.theBlack.theBlack300,
                        width: 2,
                      ),
                      color: isSelected
                          ? AppColors.primary.primary50
                          : Colors.transparent,
                    ),
                    child: Container(
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: AppColors.primary.primary700,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.spacing3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data.elementAt(index).getItemDisplay(),
                            style: AppTypography().bodyMediumMedium.copyWith(
                                color: AppColors.theBlack.theBlack900),
                          ),
                          ...widget.data
                                  .elementAt(index)
                                  .getItemDescription()
                                  .isNotNullOrEmpty
                              ? [
                                  Text(
                                    "※${widget.data.elementAt(index).getItemDescription() ?? ''}",
                                    style: AppTypography()
                                        .bodyXSmallMedium
                                        .copyWith(
                                          color: AppColors.theBlack.theBlack500,
                                        ),
                                  ),
                                ]
                              : []
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
