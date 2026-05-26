import 'package:learn_flutter/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_color.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'app_asset_image.dart';

class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool canOpenFullScreen;
  final VoidCallback? onTapImage;
  final Color? backgroundColor;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.canOpenFullScreen = false,
    this.onTapImage,
    this.backgroundColor,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  late String _currentImageUrl;
  bool _isReloading = false;

  @override
  void initState() {
    _currentImageUrl = widget.imageUrl;
    super.initState();
  }

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.imageUrl != oldWidget.imageUrl) {
      setState(() {
        _currentImageUrl = widget.imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.canOpenFullScreen
            ? showDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.75),
                builder: (context) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          child: Center(
                            child: CachedNetworkImage(
                              width: MediaQuery.of(context).size.width,
                              imageUrl: _currentImageUrl,
                              fit: widget.fit ?? BoxFit.contain,
                              placeholder: (context, url) =>
                                  widget.placeholder ?? _defaultPlaceHolder(),
                              errorWidget: (context, url, error) =>
                                  widget.errorWidget ?? _defaultErrorWidget(),
                            ),
                          ),
                        ),
                        Positioned(
                          right: AppSpacing.spacing4,
                          top: AppSpacing.spacing4,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 44.w,
                              width: 44.w,
                              decoration: BoxDecoration(
                                color: AppColors.white.white,
                                borderRadius:
                                    const BorderRadius.all(AppRadius.radius3),
                              ),
                              padding:
                                  const EdgeInsets.all(AppSpacing.spacing3),
                              child: AppAssetImage(
                                path: appIcon.icClose.path,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : widget.onTapImage?.call();
      },
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Stack(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.other.ColorF8F9FA,
              ),
            ),
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _currentImageUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit ?? BoxFit.cover,
                placeholder: (context, url) =>
                    widget.placeholder ?? _defaultPlaceHolder(),
                errorWidget: (context, url, error) =>
                    widget.errorWidget ?? _defaultErrorWidget(),
              ),
            ),
            if (_isReloading)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        widget.backgroundColor ?? AppColors.other.ColorF8F9FA,
                  ),
                  child: widget.placeholder ?? _defaultPlaceHolder(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _defaultPlaceHolder() {
    return const Center(
        child: SizedBox.square(
            dimension: AppSpacing.spacing6,
            child: CupertinoActivityIndicator()));
  }

  _defaultErrorWidget() {
    return GestureDetector(
      onTap: () {
        _reloadImage();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.other.ColorF8F9FA,
        ),
        child: Icon(
          Icons.refresh_rounded,
          color: AppColors.red.red500,
          size: AppSpacing.spacing6,
        ),
      ),
    );
  }

  void _reloadImage() async {
    setState(() {
      _isReloading = true;
    });
    await CachedNetworkImage.evictFromCache(_currentImageUrl);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _currentImageUrl = widget.imageUrl;
      _isReloading = false;
    });
  }
}
