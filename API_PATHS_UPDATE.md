# API Paths Update - Profile Feature

## ✅ Đã cập nhật API paths vào đúng vị trí

### File: `/lib/features/data/providers/network_service/src/api_path.dart`

```dart
class ProfileApiPath {
  static const getProfileScore = '/api/get-score-profile';
  static const getProfileRank = '/api/get-top-user';
}
```

### File: `/lib/features/data/providers/profile_service/profile_service.dart`

```dart
// Đã cập nhật để sử dụng ProfileApiPath thay vì hardcode
final response = await dio.get(
  ProfileApiPath.getProfileScore,
  queryParameters: {'userId': userId},
);

final response = await dio.get('${ProfileApiPath.getProfileRank}?topUser=100');
```

## 🎯 Lợi ích

- ✅ **Centralized API paths**: Tất cả API endpoints được quản lý tập trung
- ✅ **Easy maintenance**: Dễ dàng thay đổi API paths khi cần
- ✅ **Consistent naming**: Theo đúng convention của project Learn Flutter
- ✅ **Type safety**: Sử dụng const để tránh lỗi typo

## 📝 API Endpoints

1. **GET** `/api/get-score-profile?userId={userId}`
   - Lấy lịch sử điểm số của user
   - Query parameter: `userId`

2. **GET** `/api/get-top-user?topUser=100`
   - Lấy bảng xếp hạng top 100 user
   - Query parameter: `topUser=100`

Base URL được cấu hình trong network environment của project.
