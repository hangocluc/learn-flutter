import 'package:learn_flutter/features/domain/entities/src/program/program_detail.dart';

class ProgramDetailResponse {
  String? sId;
  String? programId;
  String? title;
  String? content;

  ProgramDetailResponse({this.sId, this.programId, this.title, this.content});

  ProgramDetailResponse.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    programId = json['programId'];
    title = json['title'];
    content = json['content'];
  }

  ProgramDetail toDomain() => ProgramDetail(
        id: sId ?? '',
        programId: programId ?? '',
        title: title ?? '',
        content: content ?? '',
      );
}
