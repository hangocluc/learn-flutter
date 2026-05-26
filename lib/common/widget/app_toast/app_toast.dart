import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../main.dart';
import '../../generate/assets.gen.dart';
import '../../utils/snack_bar_utils.dart';
import '../app_icon/app_asset_image.dart';
import '../app_overlay/overlay_widget.dart';
import '../app_snack_bar/app_snack_bar.dart';
import 'package:learn_flutter/common/theme/app_color.dart';

enum ToastType { Success, Error, Other }

class AppToastWidget {
  late GlobalKey globalKey;
  FToast fToast = FToast();

  AppToastWidget() {
    globalKey = GlobalKey();
    //   fToast.init(globalKey.currentState!.context);
  }

  Widget _toastContent(
    BuildContext context, {
    required String message,
    required ToastType toastType,
    Widget? customContent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: const Color.fromRGBO(217, 217, 217, 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToastIconType(context, toastType),
          const SizedBox(
            width: 8.0,
          ),
          Flexible(
            child: customContent ??
                Text(
                  message,
                ),
          ),
        ],
      ),
    );
  }

  registerContext() {
    fToast.init(globalKey.currentState!.context);
  }

  _showToast(BuildContext context, String message, ToastGravity gravity,
      ToastType toastType,
      {int? duration, Widget? customContent}) {
    //remove duplicate Toast showing
    removeToast();
    fToast.showToast(
      child: _toastContent(
        context,
        message: message,
        toastType: toastType,
        customContent: customContent,
      ),
      gravity: gravity,
      toastDuration: Duration(seconds: duration ?? 3),
    );
  }

  Widget _buildToastIconType(BuildContext context, ToastType toastType) {
    switch (toastType) {
      case ToastType.Success:
        {
          return AppAssetImage.icon24(
            path: Assets.icons.icSuccessRound.path,
            color: Colors.lightGreen,
          );
        }
      case ToastType.Error:
        {
          return AppAssetImage.icon24(
            path: Assets.icons.icErrorRound.path,
            color: Colors.redAccent,
          );
        }
      default:
        {
          return const SizedBox();
        }
    }
  }

  @Deprecated('Use [showToastCenterError] instead')
  showToastTopError(BuildContext context,
      {required String message, int? duration}) {
    _showToast(context, message, ToastGravity.TOP, ToastType.Error,
        duration: duration);
  }

  @Deprecated('Use [showToastCenterSuccess] instead')
  showToastTopSuccess(BuildContext context,
      {required String message, int? duration, Widget? customContent}) {
    _showToast(context, message, ToastGravity.TOP, ToastType.Success,
        duration: duration, customContent: customContent);
  }

  showToastCenterSuccess(BuildContext context,
      {required String message, int? duration, Widget? customContent}) {
    _showToast(context, message, ToastGravity.CENTER, ToastType.Success,
        duration: duration, customContent: customContent);
  }

  showToastCenterError(BuildContext context,
      {required String message, int? duration, Widget? customContent}) {
    _showToast(context, message, ToastGravity.CENTER, ToastType.Error,
        duration: duration, customContent: customContent);
  }

  @Deprecated('Use [showToastCenterError] instead')
  showToastBottomError(BuildContext context,
      {required String message, int? duration}) {
    _showToast(context, message, ToastGravity.BOTTOM, ToastType.Error,
        duration: duration);
  }

  // To remove present shwoing toast
  removeToast() {
    fToast.removeCustomToast();
  }

// To clear the queue

  removeAllQueuedToasts() {
    fToast.removeQueuedCustomToasts();
  }
}

void showToastSuccess(BuildContext context, String message) {
  OverlayWidget.show(
    widgetIn: AppSnackBar(
      pathIconLeft: appIcon.icLoudSpeaker.path,
      title: message,
      bgColor: AppColors.other.Color46B969,
      pathIconRight: appIcon.icClose.path,
    ),
  );
  disMissSnackBar();
}

void showToastError(BuildContext context, String message) {
  OverlayWidget.show(
    widgetIn: AppSnackBar(
      pathIconLeft: appIcon.icLoudSpeaker.path,
      title: message,
      bgColor: AppColors.red.red500,
      pathIconRight: appIcon.icClose.path,
    ),
  );
  disMissSnackBar();
}
