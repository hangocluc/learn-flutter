// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgramModel _$ProgramModelFromJson(Map<String, dynamic> json) => ProgramModel(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      programDetails: (json['programDetail'] as List<dynamic>?)
          ?.map((e) => ProgramDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProgramModelToJson(ProgramModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'image': instance.image,
      'programDetail': instance.programDetails,
    };

ProgramDetailModel _$ProgramDetailModelFromJson(Map<String, dynamic> json) =>
    ProgramDetailModel(
      id: json['_id'] as String?,
      programId: json['programId'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      videoUrl: json['videoUrl'] as String?,
    );

Map<String, dynamic> _$ProgramDetailModelToJson(ProgramDetailModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'programId': instance.programId,
      'title': instance.title,
      'content': instance.content,
      'videoUrl': instance.videoUrl,
    };
