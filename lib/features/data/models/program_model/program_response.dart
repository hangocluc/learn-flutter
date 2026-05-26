import 'package:learn_flutter/features/domain/entities/src/program/program_model.dart';

class ProgramResponse {
  String? sId;
  String? name;
  String? image;

  ProgramResponse({this.sId, this.name, this.image});

  ProgramResponse.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    image = json['image'];
  }

  ProgramModel toDomain() => ProgramModel(
        id: sId ?? '',
        name: name ?? '',
        image: image ?? '',
      );
}
