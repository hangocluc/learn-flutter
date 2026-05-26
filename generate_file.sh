#!/bin/bash

# Kiểm tra nếu có tên module được truyền vào
if [ -z "$1" ]; then
  echo "Vui lòng cung cấp tên module (feature)."
  exit 1
fi

# Tên module/feature được truyền vào
feature_name=$1
# Chuyển đổi chuỗi từ lowercase_with_underscores sang UpperCamelCase
class_name=$(echo "$feature_name" | awk -F'_' '{for(i=1;i<=NF;i++) { $i=toupper(substr($i,1,1)) substr($i,2) }} 1' OFS='')

# Tạo cấu trúc thư mục Clean Architecture cho Flutter
echo "Tạo cấu trúc thư mục cho module $feature_name ..."

# Tạo thư mục cho page
mkdir -p lib/features/presentation/pages/${feature_name}_page

# Tạo file cơ bản trong thư mục 'presentation'
echo "import 'package:flutter/material.dart';

class ${class_name}Page extends StatelessWidget {
  const ${class_name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${feature_name}'),
      ),
      body: const Center(child: Text('Welcome to ${feature_name} Page')),
    );
  }
}
" > lib/features/presentation/pages/${feature_name}_page/${feature_name}_page.dart

# Tạo thư mục cho cubit
mkdir -p lib/features/presentation/cubits/${feature_name}_cubit

# Tạo file cơ bản trong thư mục 'cubit'
echo "import 'package:bloc/bloc.dart';

import '${feature_name}_state.dart';

class ${class_name}Cubit extends Cubit<${class_name}State> {
  ${class_name}Cubit() : super(${class_name}StateInitial());
}" > lib/features/presentation/cubits/${feature_name}_cubit/${feature_name}_cubit.dart


echo "sealed class ${class_name}State {}

class ${class_name}StateInitial extends ${class_name}State {}

class ${class_name}StateLoading extends ${class_name}State {}

class ${class_name}StateFailure extends ${class_name}State {
  final String message;

  ${class_name}StateFailure({required this.message});
}

class ${class_name}StateSuccess extends ${class_name}State {
  final dynamic data;

  ${class_name}StateSuccess({this.data});
}" > lib/features/presentation/cubits/${feature_name}_cubit/${feature_name}_state.dart

# Tạo file cơ bản trong usecases
echo "import 'package:learn_flutter/core/base/base.dart';
import 'package:dartz/dartz.dart';

class ${class_name}Usecase extends BaseUseCase<NoParams, dynamic> {
  @override
  Future<Either<Exception, NoParams>> call(params) {
    // do something
    throw UnimplementedError();
  }
}" > lib/features/domain/usecases/src/${feature_name}_usecase.dart

# Thêm export vào index file của usecase
echo "export 'src/${feature_name}_usecase.dart';" >> lib/features/domain/usecases/usecase.dart

# Thêm page name vào file route name
page_name=$(echo "$feature_name" | awk -F'_' '{for(i=1;i<=NF;i++) { if(i==1) { printf $i } else { printf toupper(substr($i,1,1)) substr($i,2) } } print ""}')
file_path="lib/features/app/routes/src/routes_name.dart"
content="  static const String $page_name = '/${page_name}';"
  # Kiểm tra nếu file tồn tại
if [ ! -f "$file_path" ]; then
  echo "File '$file_path' không tồn tại. Vui lòng kiểm tra lại."
  exit 1
fi
  # Tính số dòng trong file
line_count=$(wc -l < "$file_path")
  # Kiểm tra nếu file có ít hơn 2 dòng
if [ "$line_count" -lt 2 ]; then
  echo "File '$file_path' phải có ít nhất 2 dòng để chèn nội dung."
  exit 1
fi
  # Chèn nội dung vào trước dòng thứ (độ dài file - 1)
insert_line=$((line_count - 1))
  # Sử dụng sed để chèn nội dung vào dòng đã tính
sed -i "${insert_line}i $content" "$file_path"

echo "Tất cả các file và thư mục cho module $feature_name đã được tạo thành công."

# Mở thư mục module trong VSCode (nếu có cài đặt VSCode)
code lib/features/presentation/pages/${feature_name}_page/${feature_name}_page.dart
