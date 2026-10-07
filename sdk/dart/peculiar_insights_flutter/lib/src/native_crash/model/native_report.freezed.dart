// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'native_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NativeImage {

 String get name; String get identifier;@HexAddress() Int64 get loadAddress;
/// Create a copy of NativeImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeImageCopyWith<NativeImage> get copyWith => _$NativeImageCopyWithImpl<NativeImage>(this as NativeImage, _$identity);

  /// Serializes this NativeImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeImage&&(identical(other.name, name) || other.name == name)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.loadAddress, loadAddress) || other.loadAddress == loadAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,identifier,loadAddress);

@override
String toString() {
  return 'NativeImage(name: $name, identifier: $identifier, loadAddress: $loadAddress)';
}


}

/// @nodoc
abstract mixin class $NativeImageCopyWith<$Res>  {
  factory $NativeImageCopyWith(NativeImage value, $Res Function(NativeImage) _then) = _$NativeImageCopyWithImpl;
@useResult
$Res call({
 String name, String identifier,@HexAddress() Int64 loadAddress
});




}
/// @nodoc
class _$NativeImageCopyWithImpl<$Res>
    implements $NativeImageCopyWith<$Res> {
  _$NativeImageCopyWithImpl(this._self, this._then);

  final NativeImage _self;
  final $Res Function(NativeImage) _then;

/// Create a copy of NativeImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? identifier = null,Object? loadAddress = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,loadAddress: null == loadAddress ? _self.loadAddress : loadAddress // ignore: cast_nullable_to_non_nullable
as Int64,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeImage].
extension NativeImagePatterns on NativeImage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeImage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeImage value)  $default,){
final _that = this;
switch (_that) {
case _NativeImage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeImage value)?  $default,){
final _that = this;
switch (_that) {
case _NativeImage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String identifier, @HexAddress()  Int64 loadAddress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeImage() when $default != null:
return $default(_that.name,_that.identifier,_that.loadAddress);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String identifier, @HexAddress()  Int64 loadAddress)  $default,) {final _that = this;
switch (_that) {
case _NativeImage():
return $default(_that.name,_that.identifier,_that.loadAddress);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String identifier, @HexAddress()  Int64 loadAddress)?  $default,) {final _that = this;
switch (_that) {
case _NativeImage() when $default != null:
return $default(_that.name,_that.identifier,_that.loadAddress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeImage extends NativeImage {
  const _NativeImage({required this.name, required this.identifier, @HexAddress() required this.loadAddress}): super._();
  factory _NativeImage.fromJson(Map<String, dynamic> json) => _$NativeImageFromJson(json);

@override final  String name;
@override final  String identifier;
@override@HexAddress() final  Int64 loadAddress;

/// Create a copy of NativeImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeImageCopyWith<_NativeImage> get copyWith => __$NativeImageCopyWithImpl<_NativeImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeImage&&(identical(other.name, name) || other.name == name)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.loadAddress, loadAddress) || other.loadAddress == loadAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,identifier,loadAddress);

@override
String toString() {
  return 'NativeImage(name: $name, identifier: $identifier, loadAddress: $loadAddress)';
}


}

/// @nodoc
abstract mixin class _$NativeImageCopyWith<$Res> implements $NativeImageCopyWith<$Res> {
  factory _$NativeImageCopyWith(_NativeImage value, $Res Function(_NativeImage) _then) = __$NativeImageCopyWithImpl;
@override @useResult
$Res call({
 String name, String identifier,@HexAddress() Int64 loadAddress
});




}
/// @nodoc
class __$NativeImageCopyWithImpl<$Res>
    implements _$NativeImageCopyWith<$Res> {
  __$NativeImageCopyWithImpl(this._self, this._then);

  final _NativeImage _self;
  final $Res Function(_NativeImage) _then;

/// Create a copy of NativeImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? identifier = null,Object? loadAddress = null,}) {
  return _then(_NativeImage(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,loadAddress: null == loadAddress ? _self.loadAddress : loadAddress // ignore: cast_nullable_to_non_nullable
as Int64,
  ));
}


}


/// @nodoc
mixin _$NativeFrame {

 String get module; String get function; String get file; int get line; bool get inApp;@HexAddress() Int64? get address; NativeImage? get image;
/// Create a copy of NativeFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeFrameCopyWith<NativeFrame> get copyWith => _$NativeFrameCopyWithImpl<NativeFrame>(this as NativeFrame, _$identity);

  /// Serializes this NativeFrame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeFrame&&(identical(other.module, module) || other.module == module)&&(identical(other.function, function) || other.function == function)&&(identical(other.file, file) || other.file == file)&&(identical(other.line, line) || other.line == line)&&(identical(other.inApp, inApp) || other.inApp == inApp)&&(identical(other.address, address) || other.address == address)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,module,function,file,line,inApp,address,image);

@override
String toString() {
  return 'NativeFrame(module: $module, function: $function, file: $file, line: $line, inApp: $inApp, address: $address, image: $image)';
}


}

/// @nodoc
abstract mixin class $NativeFrameCopyWith<$Res>  {
  factory $NativeFrameCopyWith(NativeFrame value, $Res Function(NativeFrame) _then) = _$NativeFrameCopyWithImpl;
@useResult
$Res call({
 String module, String function, String file, int line, bool inApp,@HexAddress() Int64? address, NativeImage? image
});


$NativeImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$NativeFrameCopyWithImpl<$Res>
    implements $NativeFrameCopyWith<$Res> {
  _$NativeFrameCopyWithImpl(this._self, this._then);

  final NativeFrame _self;
  final $Res Function(NativeFrame) _then;

/// Create a copy of NativeFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? module = null,Object? function = null,Object? file = null,Object? line = null,Object? inApp = null,Object? address = freezed,Object? image = freezed,}) {
  return _then(_self.copyWith(
module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,function: null == function ? _self.function : function // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,inApp: null == inApp ? _self.inApp : inApp // ignore: cast_nullable_to_non_nullable
as bool,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Int64?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as NativeImage?,
  ));
}
/// Create a copy of NativeFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $NativeImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeFrame].
extension NativeFramePatterns on NativeFrame {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeFrame() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeFrame value)  $default,){
final _that = this;
switch (_that) {
case _NativeFrame():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeFrame value)?  $default,){
final _that = this;
switch (_that) {
case _NativeFrame() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String module,  String function,  String file,  int line,  bool inApp, @HexAddress()  Int64? address,  NativeImage? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeFrame() when $default != null:
return $default(_that.module,_that.function,_that.file,_that.line,_that.inApp,_that.address,_that.image);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String module,  String function,  String file,  int line,  bool inApp, @HexAddress()  Int64? address,  NativeImage? image)  $default,) {final _that = this;
switch (_that) {
case _NativeFrame():
return $default(_that.module,_that.function,_that.file,_that.line,_that.inApp,_that.address,_that.image);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String module,  String function,  String file,  int line,  bool inApp, @HexAddress()  Int64? address,  NativeImage? image)?  $default,) {final _that = this;
switch (_that) {
case _NativeFrame() when $default != null:
return $default(_that.module,_that.function,_that.file,_that.line,_that.inApp,_that.address,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeFrame extends NativeFrame {
  const _NativeFrame({required this.module, required this.function, required this.file, required this.line, required this.inApp, @HexAddress() this.address, this.image}): super._();
  factory _NativeFrame.fromJson(Map<String, dynamic> json) => _$NativeFrameFromJson(json);

@override final  String module;
@override final  String function;
@override final  String file;
@override final  int line;
@override final  bool inApp;
@override@HexAddress() final  Int64? address;
@override final  NativeImage? image;

/// Create a copy of NativeFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeFrameCopyWith<_NativeFrame> get copyWith => __$NativeFrameCopyWithImpl<_NativeFrame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeFrameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeFrame&&(identical(other.module, module) || other.module == module)&&(identical(other.function, function) || other.function == function)&&(identical(other.file, file) || other.file == file)&&(identical(other.line, line) || other.line == line)&&(identical(other.inApp, inApp) || other.inApp == inApp)&&(identical(other.address, address) || other.address == address)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,module,function,file,line,inApp,address,image);

@override
String toString() {
  return 'NativeFrame(module: $module, function: $function, file: $file, line: $line, inApp: $inApp, address: $address, image: $image)';
}


}

/// @nodoc
abstract mixin class _$NativeFrameCopyWith<$Res> implements $NativeFrameCopyWith<$Res> {
  factory _$NativeFrameCopyWith(_NativeFrame value, $Res Function(_NativeFrame) _then) = __$NativeFrameCopyWithImpl;
@override @useResult
$Res call({
 String module, String function, String file, int line, bool inApp,@HexAddress() Int64? address, NativeImage? image
});


@override $NativeImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$NativeFrameCopyWithImpl<$Res>
    implements _$NativeFrameCopyWith<$Res> {
  __$NativeFrameCopyWithImpl(this._self, this._then);

  final _NativeFrame _self;
  final $Res Function(_NativeFrame) _then;

/// Create a copy of NativeFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? module = null,Object? function = null,Object? file = null,Object? line = null,Object? inApp = null,Object? address = freezed,Object? image = freezed,}) {
  return _then(_NativeFrame(
module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,function: null == function ? _self.function : function // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,inApp: null == inApp ? _self.inApp : inApp // ignore: cast_nullable_to_non_nullable
as bool,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Int64?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as NativeImage?,
  ));
}

/// Create a copy of NativeFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $NativeImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// @nodoc
mixin _$NativeReport {

 String get id; int get timeMillis; String get exceptionType; String get message; String get thread; String get appVersion; String get appBuild; IList<NativeFrame> get frames;
/// Create a copy of NativeReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeReportCopyWith<NativeReport> get copyWith => _$NativeReportCopyWithImpl<NativeReport>(this as NativeReport, _$identity);

  /// Serializes this NativeReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeReport&&(identical(other.id, id) || other.id == id)&&(identical(other.timeMillis, timeMillis) || other.timeMillis == timeMillis)&&(identical(other.exceptionType, exceptionType) || other.exceptionType == exceptionType)&&(identical(other.message, message) || other.message == message)&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appBuild, appBuild) || other.appBuild == appBuild)&&const DeepCollectionEquality().equals(other.frames, frames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timeMillis,exceptionType,message,thread,appVersion,appBuild,const DeepCollectionEquality().hash(frames));

@override
String toString() {
  return 'NativeReport(id: $id, timeMillis: $timeMillis, exceptionType: $exceptionType, message: $message, thread: $thread, appVersion: $appVersion, appBuild: $appBuild, frames: $frames)';
}


}

/// @nodoc
abstract mixin class $NativeReportCopyWith<$Res>  {
  factory $NativeReportCopyWith(NativeReport value, $Res Function(NativeReport) _then) = _$NativeReportCopyWithImpl;
@useResult
$Res call({
 String id, int timeMillis, String exceptionType, String message, String thread, String appVersion, String appBuild, IList<NativeFrame> frames
});




}
/// @nodoc
class _$NativeReportCopyWithImpl<$Res>
    implements $NativeReportCopyWith<$Res> {
  _$NativeReportCopyWithImpl(this._self, this._then);

  final NativeReport _self;
  final $Res Function(NativeReport) _then;

/// Create a copy of NativeReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? timeMillis = null,Object? exceptionType = null,Object? message = null,Object? thread = null,Object? appVersion = null,Object? appBuild = null,Object? frames = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timeMillis: null == timeMillis ? _self.timeMillis : timeMillis // ignore: cast_nullable_to_non_nullable
as int,exceptionType: null == exceptionType ? _self.exceptionType : exceptionType // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appBuild: null == appBuild ? _self.appBuild : appBuild // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as IList<NativeFrame>,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeReport].
extension NativeReportPatterns on NativeReport {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeReport() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeReport value)  $default,){
final _that = this;
switch (_that) {
case _NativeReport():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeReport value)?  $default,){
final _that = this;
switch (_that) {
case _NativeReport() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int timeMillis,  String exceptionType,  String message,  String thread,  String appVersion,  String appBuild,  IList<NativeFrame> frames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeReport() when $default != null:
return $default(_that.id,_that.timeMillis,_that.exceptionType,_that.message,_that.thread,_that.appVersion,_that.appBuild,_that.frames);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int timeMillis,  String exceptionType,  String message,  String thread,  String appVersion,  String appBuild,  IList<NativeFrame> frames)  $default,) {final _that = this;
switch (_that) {
case _NativeReport():
return $default(_that.id,_that.timeMillis,_that.exceptionType,_that.message,_that.thread,_that.appVersion,_that.appBuild,_that.frames);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int timeMillis,  String exceptionType,  String message,  String thread,  String appVersion,  String appBuild,  IList<NativeFrame> frames)?  $default,) {final _that = this;
switch (_that) {
case _NativeReport() when $default != null:
return $default(_that.id,_that.timeMillis,_that.exceptionType,_that.message,_that.thread,_that.appVersion,_that.appBuild,_that.frames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeReport extends NativeReport {
  const _NativeReport({required this.id, required this.timeMillis, required this.exceptionType, required this.message, required this.thread, required this.appVersion, required this.appBuild, required this.frames}): super._();
  factory _NativeReport.fromJson(Map<String, dynamic> json) => _$NativeReportFromJson(json);

@override final  String id;
@override final  int timeMillis;
@override final  String exceptionType;
@override final  String message;
@override final  String thread;
@override final  String appVersion;
@override final  String appBuild;
@override final  IList<NativeFrame> frames;

/// Create a copy of NativeReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeReportCopyWith<_NativeReport> get copyWith => __$NativeReportCopyWithImpl<_NativeReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeReport&&(identical(other.id, id) || other.id == id)&&(identical(other.timeMillis, timeMillis) || other.timeMillis == timeMillis)&&(identical(other.exceptionType, exceptionType) || other.exceptionType == exceptionType)&&(identical(other.message, message) || other.message == message)&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appBuild, appBuild) || other.appBuild == appBuild)&&const DeepCollectionEquality().equals(other.frames, frames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timeMillis,exceptionType,message,thread,appVersion,appBuild,const DeepCollectionEquality().hash(frames));

@override
String toString() {
  return 'NativeReport(id: $id, timeMillis: $timeMillis, exceptionType: $exceptionType, message: $message, thread: $thread, appVersion: $appVersion, appBuild: $appBuild, frames: $frames)';
}


}

/// @nodoc
abstract mixin class _$NativeReportCopyWith<$Res> implements $NativeReportCopyWith<$Res> {
  factory _$NativeReportCopyWith(_NativeReport value, $Res Function(_NativeReport) _then) = __$NativeReportCopyWithImpl;
@override @useResult
$Res call({
 String id, int timeMillis, String exceptionType, String message, String thread, String appVersion, String appBuild, IList<NativeFrame> frames
});




}
/// @nodoc
class __$NativeReportCopyWithImpl<$Res>
    implements _$NativeReportCopyWith<$Res> {
  __$NativeReportCopyWithImpl(this._self, this._then);

  final _NativeReport _self;
  final $Res Function(_NativeReport) _then;

/// Create a copy of NativeReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? timeMillis = null,Object? exceptionType = null,Object? message = null,Object? thread = null,Object? appVersion = null,Object? appBuild = null,Object? frames = null,}) {
  return _then(_NativeReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timeMillis: null == timeMillis ? _self.timeMillis : timeMillis // ignore: cast_nullable_to_non_nullable
as int,exceptionType: null == exceptionType ? _self.exceptionType : exceptionType // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appBuild: null == appBuild ? _self.appBuild : appBuild // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as IList<NativeFrame>,
  ));
}


}

// dart format on
