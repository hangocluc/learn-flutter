# Sơ đồ tuần tự UML — Learn Flutter App

Style đen trắng (luận văn / Robustness), dùng chung file [`_style.puml`](_style.puml).

## Cách xem / xuất PNG

Cần [PlantUML](https://plantuml.com/) (extension VS Code/Cursor, hoặc CLI):

```bash
# Từ thư mục docs/uml (cần Java + plantuml.jar hoặc plantuml CLI)
plantuml sequences/*.puml
```

Hoặc mở từng file `.puml` trong IDE có extension **PlantUML**.

## Danh sách sơ đồ

| File | Chức năng |
|------|-----------|
| `sequences/seq_01_app_startup.puml` | Khởi động app, Firebase, DI, FCM |
| `sequences/seq_02_login.puml` | Đăng nhập Google + đồng bộ user BE |
| `sequences/seq_03_home.puml` | Tab Home — dashboard song song |
| `sequences/seq_04_lessons.puml` | Tab Lesson — danh sách, topic, video |
| `sequences/seq_05_quiz.puml` | Quiz — chấm điểm + `update-process` |
| `sequences/seq_06_program.puml` | Tab Program — danh sách chương trình |
| `sequences/seq_07_profile.puml` | Tab Profile — điểm & xếp hạng |
| `sequences/seq_08_chat_ai.puml` | Tab ChatGPT — Groq/Gemini/OpenAI |
| `sequences/seq_09_chat_comments.puml` | Bình luận / like câu hỏi |
| `sequences/seq_10_fcm.puml` | Push notification FCM |
| `sequences/seq_11_feedback.puml` | Phản hồi bài học / hệ thống |
| `sequences/seq_12_compiler.puml` | Dart Playground / compiler |

## Ký hiệu lớp (Robustness)

- **Actor** — Người dùng  
- **Boundary** — UI (`*Page`, `*Sheet`)  
- **Control** — Cubit, UseCase, Service, Repository  
- **Database** — Backend REST, Firebase, API bên thứ ba  
- **Entity** — Local storage (`StorageManager`, `SharedPreferences`)

## Kiến trúc tổng quan (5 tab `MainPage`)

```
Home | Lesson | Program | Profile | ChatGPT
```

Luồng vào app: `LoginPage` → `MainPage` sau khi Google Sign-In + `getOrCreateNewUser`.
