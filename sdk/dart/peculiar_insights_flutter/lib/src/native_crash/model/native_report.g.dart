// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'native_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NativeImage _$NativeImageFromJson(Map<String, dynamic> json) => _NativeImage(
  name: json['name'] as String,
  identifier: json['identifier'] as String,
  loadAddress: const HexAddress().fromJson(json['loadAddress'] as String),
);

Map<String, dynamic> _$NativeImageToJson(_NativeImage instance) =>
    <String, dynamic>{
      'name': instance.name,
      'identifier': instance.identifier,
      'loadAddress': const HexAddress().toJson(instance.loadAddress),
    };

_NativeFrame _$NativeFrameFromJson(Map<String, dynamic> json) => _NativeFrame(
  module: json['module'] as String,
  function: json['function'] as String,
  file: json['file'] as String,
  line: (json['line'] as num).toInt(),
  inApp: json['inApp'] as bool,
  address: _$JsonConverterFromJson<String, Int64>(
    json['address'],
    const HexAddress().fromJson,
  ),
  image: json['image'] == null
      ? null
      : NativeImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NativeFrameToJson(_NativeFrame instance) =>
    <String, dynamic>{
      'module': instance.module,
      'function': instance.function,
      'file': instance.file,
      'line': instance.line,
      'inApp': instance.inApp,
      'address': _$JsonConverterToJson<String, Int64>(
        instance.address,
        const HexAddress().toJson,
      ),
      'image': instance.image,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

_NativeReport _$NativeReportFromJson(Map<String, dynamic> json) =>
    _NativeReport(
      id: json['id'] as String,
      timeMillis: (json['timeMillis'] as num).toInt(),
      exceptionType: json['exceptionType'] as String,
      message: json['message'] as String,
      thread: json['thread'] as String,
      appVersion: json['appVersion'] as String,
      appBuild: json['appBuild'] as String,
      frames: IList<NativeFrame>.fromJson(
        json['frames'],
        (value) => NativeFrame.fromJson(value as Map<String, dynamic>),
      ),
    );

Map<String, dynamic> _$NativeReportToJson(_NativeReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timeMillis': instance.timeMillis,
      'exceptionType': instance.exceptionType,
      'message': instance.message,
      'thread': instance.thread,
      'appVersion': instance.appVersion,
      'appBuild': instance.appBuild,
      'frames': instance.frames.toJson((value) => value),
    };
