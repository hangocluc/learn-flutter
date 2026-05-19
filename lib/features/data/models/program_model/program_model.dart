import 'package:json_annotation/json_annotation.dart';

part 'program_model.g.dart';

@JsonSerializable()
class ProgramModel {
  @JsonKey(name: '_id')
  final String? id;
  final String? name;
  final String? image;
  @JsonKey(name: 'programDetail')
  final List<ProgramDetailModel>? programDetails;

  const ProgramModel({
    this.id,
    this.name,
    this.image,
    this.programDetails,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramModelToJson(this);
}

@JsonSerializable()
class ProgramDetailModel {
  @JsonKey(name: '_id')
  final String? id;
  @JsonKey(name: 'programId')
  final String? programId;
  final String? title;
  final String? content;
  /// Network `https://...` / `http://...`, or bundled asset path `assets/videos/....mp4`.
  @JsonKey(name: 'videoUrl')
  final String? videoUrl;

  const ProgramDetailModel({
    this.id,
    this.programId,
    this.title,
    this.content,
    this.videoUrl,
  });

  factory ProgramDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramDetailModelToJson(this);
}
