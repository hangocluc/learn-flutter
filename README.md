# learn_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Chuogeomatic Flutter Application

## Getting Started

1. Setup Build_runner, Flutter_gen_runner

- for generate Model, Assets
  a. Install - Flutter pub get - brew install FlutterGen/tap/fluttergen
  b. Active - dart pub global activate flutter_gen
  c. Usage - dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n - flutter gen-l10n

2. autogen UI page file

- File gen: generate_file.sh
- Cấp quyền cho file gen: chmod +x generate_file.sh
- lệnh gen file: ./generate_file.sh + tên UI module ( tên format dạng lowercase_with_underscores)
- Ví dụ: ./generate_file.sh demo_auto_gen
- các thư mục được tạo ra/ ghi thêm:
  │
  └───../routes/routes_name.dart - Thêm const tên trang vừa tạo (static const demoAutoGen = '/demoAutoGen')
  │  
   └───../domain/usecases/src
  │  
   └─── demo_auto_gen_usecase.dart - thêm export usecase vào file usecase.dart
  │  
   └─── usecase.dart thêm export usecase vào file
  │  
   └───../presentation
  │  
   └───cubits
  │  
   └─── demo_auto_gen_cubit
  │  
   └─── demo_auto_gen_cubit.dart
  │  
   └─── demo_auto_gen_state.dart
  │  
   └───pages
  │  
   └─── demo_auto_gen_page
  │  
   └─── demo_auto_gen_page.dart

-------------------------- PRE-BUILD -----------------------------------------

- Download file 'firebase_option.dart' and copy to 'project/lib/'
- ANDROID:
  - Download file 'properties google_map_configure.properties' to 'project/android/'
  - Download file 'key.properties' to 'project/android/'
  - Downalod copy google-json to each folder dev, prod, uat
  - Downlaod keystore if debug or key if release to 'project/android/app'
- IOS:
  - Checkout to branch by enviroment: develop, uat, prod, official(master project)
  - Download file 'KeyConstaints.swift' to 'ios/Runner'

-------------------------- BUILD ANDROID -------------------------------------
Build android app

- Build appbundle release Production
  - flutter build appbundle --flavor prod -Pflavor=prod --dart-define=flavor=prod
- Build apk release UAT
  - flutter build apk --flavor uar -Pflavor=uat --dart-define=flavor=uat
- Build apk release Dev
  - flutter build apk --flavor dev -Pflavor=dev --dart-define=flavor=dev
  - flutter build apk --flavor dev -Pflavor=dev --dart-define=flavor=dev

--------------------------- BUILD IOS -------------------------------------------

Because of GoogleMaps error when configure flavor for ios project, Im Split project to multi branch - develop : For development enviroment - uat : Uat env - prod : Old version review applestore connect. ( production env) - official : Official production ---- in appStore

How to using:

- In Visual Studio Code:
  - Open Run and Debug and select runner script from file 'launch.json'
