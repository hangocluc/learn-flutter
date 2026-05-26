import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:learn_flutter/firebase_options.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widget/app_icon/app_asset_image.dart';
import '../widget/app_text/app_text.dart';
import '../widget/app_toast/app_toast.dart';

Future<void> initFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    log('Firebase already initialized: ${Firebase.app().name}');
    return;
  }
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  log('Firebase initialized: ${app.name}');
}

Future<void> enableFirebaseAnalytics() async {
  //await analytics.setAnalyticsCollectionEnabled(true);
}

Color stringToColor(String? color) {
  Color myColor =
      Color(int.parse((color ?? '#dc3545').replaceFirst('#', '0xFF')));
  return myColor;
}

String generateUniqueId({int? lenghtOfCode}) {
  var uuid = const Uuid();
  return uuid.v4().substring(0, lenghtOfCode ?? 12);
}

void showSessionExpiredDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: AppText(title: 'language.lblSessionExpired'),
        content: AppText(title: 'language.lblMustLoginForUse'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('RouteName.login', (route) => false);
            },
            child: AppText(title: 'language.lblReLogin'),
          ),
        ],
      );
    },
  );
}

final emailFormatRegex = RegExp(
  r'^(?!.*\.\.)(?!\.)([a-zA-Z0-9._+-?/]{1,63})(?<!\.)@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);
final lengthEmailFormatRegex = RegExp(
  r'^(?=.{1,63}@)[^@]+@[^@]+\.[^@]+$',
);

String removeHtmlTags(String html) {
  final RegExp regExp = RegExp(r'<[^>]*>');
  return html.replaceAll(regExp, ''); // Loại bỏ tất cả các thẻ HTML
}

// permissionPhotoHandle(
//     Function(XFile? pickedFile) onPickPhoto, BuildContext context) async {
//   if (context.mounted) {
//     final hasPermission = await AppPermissionHandler.requestStoragePermission(
//       context,
//     );
//     if (hasPermission) {
//       final ImagePicker picker = ImagePicker();
//       final XFile? pickedFile =
//           await picker.pickImage(source: ImageSource.gallery);
//       onPickPhoto(pickedFile);
//     }
//   }
//}

String getDataFromKey({required String key, Map<dynamic, dynamic>? data}) {
  if (data != null && data.keys.contains(key)) {
    return data[key];
  }
  return '';
}

Future<void> deleteCacheAppWebViewDir() async {
  final cacheDir = await getTemporaryDirectory();
  final List<FileSystemEntity> entities = await cacheDir.parent.list().toList();
  for (var element in entities) {
    if (element.path.toLowerCase().contains('webview')) {
      await Directory(element.path).delete(recursive: true);
    }
  }
}

Future<void> deleteCacheWebViewDir() async {
  final cacheDir = await getTemporaryDirectory();
  final List<FileSystemEntity> entities = await cacheDir.list().toList();
  for (var element in entities) {
    if (element.path.toLowerCase().contains('webview')) {
      await Directory(element.path).delete(recursive: true);
    }
  }
}

class CustomPostalCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('-', ''); // Remove existing dashes
    if (text.length <= 3) {
      // If the input is less than or equal to 3 digits
      return newValue.copyWith(text: text, selection: newValue.selection);
    } else if (text.length <= 7) {
      // If the input is between 4 and 7 digits
      final formatted = '${text.substring(0, 3)}-${text.substring(3)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      // Restrict input to 7 digits
      final formatted = '${text.substring(0, 3)}-${text.substring(3, 7)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
}

openLink(BuildContext context, String? url) {
  try {
    if (url?.isEmpty ?? true) {
      throw Exception();
    }
    // launchUrl(
    //   Uri.parse(url!),
    //   mode: LaunchMode.platformDefault,
    // );
  } catch (error) {
    showToastError(context, 'language.lblCannotOpenWeb');
  }
}

Widget waterDropHeader() {
  return WaterDropHeader(
    complete: Row(
      children: [
        const Spacer(),
        AppText(title: 'language.lblRefreshComplete'),
        AppAssetImage(
          path: appIcon.icCheck.path,
          color: AppColors.primary.primary400,
        ),
        const Spacer(),
      ],
    ),
  );
}

// Future<bool> checkActivityRecognitionPermission() async {
//   bool granted = await Permission.activityRecognition.isGranted;

//   if (!granted) {
//     granted = await Permission.activityRecognition.request() ==
//         PermissionStatus.granted;
//   }

//   return granted;
// }

// Future<void> requestActivityRecognitionPermission(BuildContext context) async {
//   if (context.mounted) {
//     await Permission.activityRecognition.request();
//   }
// }

Widget backToHome(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '',
        (route) => false,
      );
    },
    child: Container(
      height: 44.w,
      width: 44.w,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing3, vertical: AppSpacing.spacing3),
      decoration: BoxDecoration(
          color: AppColors.white.white,
          borderRadius: BorderRadius.circular(AppRadius.radius3.x)),
      child: AppAssetImage(
        path: appIcon.icClose.path,
        color: AppColors.theBlack.theBlack800,
      ),
    ),
  );
}
