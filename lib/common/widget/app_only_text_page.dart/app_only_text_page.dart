import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_flutter/core/extension/src/string_extension.dart';
import '../../theme/app_color.dart';
import '../../theme/app_effect.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../app_appbar/app_appbar.dart';
import '../app_button/app_button.dart';
import '../app_text/app_text.dart';
import 'app_only_text_param.dart';

class AppOnlyTextPage extends StatefulWidget {
  final AppOnlyTextParam param;

  const AppOnlyTextPage({super.key, required this.param});

  @override
  State<AppOnlyTextPage> createState() => _AppOnlyTextPageState();
}

class _AppOnlyTextPageState extends State<AppOnlyTextPage> {
  final ScrollController _scrollController = ScrollController();
  bool canSubmit = false;

  @override
  initState() {
    super.initState();
    _scrollController.addListener(
      () {
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent ||
            _scrollController.position.maxScrollExtent <= 0) {
          if (!canSubmit) {
            setState(() {
              canSubmit = true;
            });
          }
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        if (_scrollController.hasClients) {
          final canScroll = _scrollController.position.maxScrollExtent <= 0;
          if (canScroll) {
            setState(() {
              canSubmit = true;
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.other.ColorF8F9FA,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return CustomAppBar(
      isCenterTitle: true,
      title: widget.param.appBarTitle,
      backgroundColor: AppColors.white.white,
      appBarColor: AppColors.other.ColorF8F9FA,
    );
  }

  _buildBody(BuildContext context) {
    return Stack(
      children: [
        ListView(
          controller: _scrollController,
          children: [
            const SizedBox(
              height: AppSpacing.spacing4,
            ),
            // _buildNotice(context),
            (widget.param.child != null)
                ? _buildBodyWidget(context)
                : _buildBodyText(context)
          ],
        ),
        _buildSubmitButton(context),
      ],
    );
  }

  _buildBodyText(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            100.h + MediaQuery.of(context).padding.bottom + AppSpacing.spacing4,
        left: AppSpacing.spacing4,
        right: AppSpacing.spacing4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: widget.param.title.isNotNullOrEmpty,
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.spacing6,
                bottom: AppSpacing.spacing4,
              ),
              child: AppText(
                title: widget.param.title ?? '',
                style: AppTypography().heading4.copyWith(
                      color: AppColors.theBlack.theBlack900,
                    ),
              ),
            ),
          ),
          AppText(
            title: widget.param.content ?? '',
            maxLines: 9999,
            style: widget.param.contentStyle ??
                AppTypography().bodySmallRegular.copyWith(
                      color: AppColors.theBlack.theBlack950,
                    ),
          ),
        ],
      ),
    );
  }

  _buildBodyWidget(BuildContext context) {
    return widget.param.child!;
  }

  _buildSubmitButton(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Visibility(
        visible: widget.param.onSubmit != null,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.only(
            left: AppSpacing.spacing4,
            right: AppSpacing.spacing4,
            top: AppSpacing.spacing6,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.spacing5,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.white,
            boxShadow: [AppEffect.shadow.boxS],
            borderRadius: const BorderRadius.only(
              topLeft: AppRadius.radius4,
              topRight: AppRadius.radius4,
            ),
          ),
          child: AppButton(
            onTap: () {
              canSubmit ? widget.param.onSubmit?.call() : null;
            },
            padding: const EdgeInsets.all(AppSpacing.spacing3),
            // height: 56.h,
            radius: AppRadius.radius3.x,
            titleStyle: AppTypography().bodyMediumSemiBold.copyWith(
                  color: AppColors.white.white,
                ),
            buttonColor: canSubmit
                ? AppColors.primary.primary400
                : AppColors.theBlack.theBlack200,
            borderColor: canSubmit
                ? AppColors.primary.primary400
                : AppColors.theBlack.theBlack200,
            title: widget.param.submitTitle ?? '',
          ),
        ),
      ),
    );
  }
}
