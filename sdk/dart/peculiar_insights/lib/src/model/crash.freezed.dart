// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crash.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BinaryImage {

 String get name; String get identifier; Int64 get loadAddress;
/// Create a copy of BinaryImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BinaryImageCopyWith<BinaryImage> get copyWith => _$BinaryImageCopyWithImpl<BinaryImage>(this as BinaryImage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BinaryImage&&(identical(other.name, name) || other.name == name)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.loadAddress, loadAddress) || other.loadAddress == loadAddress));
}


@override
int get hashCode => Object.hash(runtimeType,name,identifier,loadAddress);

@override
String toString() {
  return 'BinaryImage(name: $name, identifier: $identifier, loadAddress: $loadAddress)';
}


}

/// @nodoc
abstract mixin class $BinaryImageCopyWith<$Res>  {
  factory $BinaryImageCopyWith(BinaryImage value, $Res Function(BinaryImage) _then) = _$BinaryImageCopyWithImpl;
@useResult
$Res call({
 String name, String identifier, Int64 loadAddress
});




}
/// @nodoc
class _$BinaryImageCopyWithImpl<$Res>
    implements $BinaryImageCopyWith<$Res> {
  _$BinaryImageCopyWithImpl(this._self, this._then);

  final BinaryImage _self;
  final $Res Function(BinaryImage) _then;

/// Create a copy of BinaryImage
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


/// Adds pattern-matching-related methods to [BinaryImage].
extension BinaryImagePatterns on BinaryImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BinaryImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BinaryImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BinaryImage value)  $default,){
final _that = this;
switch (_that) {
case _BinaryImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BinaryImage value)?  $default,){
final _that = this;
switch (_that) {
case _BinaryImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String identifier,  Int64 loadAddress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BinaryImage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String identifier,  Int64 loadAddress)  $default,) {final _that = this;
switch (_that) {
case _BinaryImage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String identifier,  Int64 loadAddress)?  $default,) {final _that = this;
switch (_that) {
case _BinaryImage() when $default != null:
return $default(_that.name,_that.identifier,_that.loadAddress);case _:
  return null;

}
}

}

/// @nodoc


class _BinaryImage extends BinaryImage {
  const _BinaryImage({required this.name, required this.identifier, required this.loadAddress}): super._();
  

@override final  String name;
@override final  String identifier;
@override final  Int64 loadAddress;

/// Create a copy of BinaryImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BinaryImageCopyWith<_BinaryImage> get copyWith => __$BinaryImageCopyWithImpl<_BinaryImage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BinaryImage&&(identical(other.name, name) || other.name == name)&&(identical(other.identifier, identifier) || other.identifier == identifier)&&(identical(other.loadAddress, loadAddress) || other.loadAddress == loadAddress));
}


@override
int get hashCode => Object.hash(runtimeType,name,identifier,loadAddress);

@override
String toString() {
  return 'BinaryImage(name: $name, identifier: $identifier, loadAddress: $loadAddress)';
}


}

/// @nodoc
abstract mixin class _$BinaryImageCopyWith<$Res> implements $BinaryImageCopyWith<$Res> {
  factory _$BinaryImageCopyWith(_BinaryImage value, $Res Function(_BinaryImage) _then) = __$BinaryImageCopyWithImpl;
@override @useResult
$Res call({
 String name, String identifier, Int64 loadAddress
});




}
/// @nodoc
class __$BinaryImageCopyWithImpl<$Res>
    implements _$BinaryImageCopyWith<$Res> {
  __$BinaryImageCopyWithImpl(this._self, this._then);

  final _BinaryImage _self;
  final $Res Function(_BinaryImage) _then;

/// Create a copy of BinaryImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? identifier = null,Object? loadAddress = null,}) {
  return _then(_BinaryImage(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,loadAddress: null == loadAddress ? _self.loadAddress : loadAddress // ignore: cast_nullable_to_non_nullable
as Int64,
  ));
}


}

/// @nodoc
mixin _$Frame {

 String get moduleName; String get function; String get file; int get line; int get column; bool get inApp; Int64? get instructionAddress; BinaryImage? get image;
/// Create a copy of Frame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrameCopyWith<Frame> get copyWith => _$FrameCopyWithImpl<Frame>(this as Frame, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Frame&&(identical(other.moduleName, moduleName) || other.moduleName == moduleName)&&(identical(other.function, function) || other.function == function)&&(identical(other.file, file) || other.file == file)&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column)&&(identical(other.inApp, inApp) || other.inApp == inApp)&&(identical(other.instructionAddress, instructionAddress) || other.instructionAddress == instructionAddress)&&(identical(other.image, image) || other.image == image));
}


@override
int get hashCode => Object.hash(runtimeType,moduleName,function,file,line,column,inApp,instructionAddress,image);

@override
String toString() {
  return 'Frame(moduleName: $moduleName, function: $function, file: $file, line: $line, column: $column, inApp: $inApp, instructionAddress: $instructionAddress, image: $image)';
}


}

/// @nodoc
abstract mixin class $FrameCopyWith<$Res>  {
  factory $FrameCopyWith(Frame value, $Res Function(Frame) _then) = _$FrameCopyWithImpl;
@useResult
$Res call({
 String moduleName, String function, String file, int line, int column, bool inApp, Int64? instructionAddress, BinaryImage? image
});


$BinaryImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$FrameCopyWithImpl<$Res>
    implements $FrameCopyWith<$Res> {
  _$FrameCopyWithImpl(this._self, this._then);

  final Frame _self;
  final $Res Function(Frame) _then;

/// Create a copy of Frame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? moduleName = null,Object? function = null,Object? file = null,Object? line = null,Object? column = null,Object? inApp = null,Object? instructionAddress = freezed,Object? image = freezed,}) {
  return _then(_self.copyWith(
moduleName: null == moduleName ? _self.moduleName : moduleName // ignore: cast_nullable_to_non_nullable
as String,function: null == function ? _self.function : function // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,inApp: null == inApp ? _self.inApp : inApp // ignore: cast_nullable_to_non_nullable
as bool,instructionAddress: freezed == instructionAddress ? _self.instructionAddress : instructionAddress // ignore: cast_nullable_to_non_nullable
as Int64?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as BinaryImage?,
  ));
}
/// Create a copy of Frame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BinaryImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $BinaryImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [Frame].
extension FramePatterns on Frame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Frame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Frame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Frame value)  $default,){
final _that = this;
switch (_that) {
case _Frame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Frame value)?  $default,){
final _that = this;
switch (_that) {
case _Frame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String moduleName,  String function,  String file,  int line,  int column,  bool inApp,  Int64? instructionAddress,  BinaryImage? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Frame() when $default != null:
return $default(_that.moduleName,_that.function,_that.file,_that.line,_that.column,_that.inApp,_that.instructionAddress,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String moduleName,  String function,  String file,  int line,  int column,  bool inApp,  Int64? instructionAddress,  BinaryImage? image)  $default,) {final _that = this;
switch (_that) {
case _Frame():
return $default(_that.moduleName,_that.function,_that.file,_that.line,_that.column,_that.inApp,_that.instructionAddress,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String moduleName,  String function,  String file,  int line,  int column,  bool inApp,  Int64? instructionAddress,  BinaryImage? image)?  $default,) {final _that = this;
switch (_that) {
case _Frame() when $default != null:
return $default(_that.moduleName,_that.function,_that.file,_that.line,_that.column,_that.inApp,_that.instructionAddress,_that.image);case _:
  return null;

}
}

}

/// @nodoc


class _Frame extends Frame {
  const _Frame({required this.moduleName, required this.function, required this.file, required this.line, required this.column, required this.inApp, this.instructionAddress, this.image}): super._();
  

@override final  String moduleName;
@override final  String function;
@override final  String file;
@override final  int line;
@override final  int column;
@override final  bool inApp;
@override final  Int64? instructionAddress;
@override final  BinaryImage? image;

/// Create a copy of Frame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FrameCopyWith<_Frame> get copyWith => __$FrameCopyWithImpl<_Frame>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Frame&&(identical(other.moduleName, moduleName) || other.moduleName == moduleName)&&(identical(other.function, function) || other.function == function)&&(identical(other.file, file) || other.file == file)&&(identical(other.line, line) || other.line == line)&&(identical(other.column, column) || other.column == column)&&(identical(other.inApp, inApp) || other.inApp == inApp)&&(identical(other.instructionAddress, instructionAddress) || other.instructionAddress == instructionAddress)&&(identical(other.image, image) || other.image == image));
}


@override
int get hashCode => Object.hash(runtimeType,moduleName,function,file,line,column,inApp,instructionAddress,image);

@override
String toString() {
  return 'Frame(moduleName: $moduleName, function: $function, file: $file, line: $line, column: $column, inApp: $inApp, instructionAddress: $instructionAddress, image: $image)';
}


}

/// @nodoc
abstract mixin class _$FrameCopyWith<$Res> implements $FrameCopyWith<$Res> {
  factory _$FrameCopyWith(_Frame value, $Res Function(_Frame) _then) = __$FrameCopyWithImpl;
@override @useResult
$Res call({
 String moduleName, String function, String file, int line, int column, bool inApp, Int64? instructionAddress, BinaryImage? image
});


@override $BinaryImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$FrameCopyWithImpl<$Res>
    implements _$FrameCopyWith<$Res> {
  __$FrameCopyWithImpl(this._self, this._then);

  final _Frame _self;
  final $Res Function(_Frame) _then;

/// Create a copy of Frame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? moduleName = null,Object? function = null,Object? file = null,Object? line = null,Object? column = null,Object? inApp = null,Object? instructionAddress = freezed,Object? image = freezed,}) {
  return _then(_Frame(
moduleName: null == moduleName ? _self.moduleName : moduleName // ignore: cast_nullable_to_non_nullable
as String,function: null == function ? _self.function : function // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,inApp: null == inApp ? _self.inApp : inApp // ignore: cast_nullable_to_non_nullable
as bool,instructionAddress: freezed == instructionAddress ? _self.instructionAddress : instructionAddress // ignore: cast_nullable_to_non_nullable
as Int64?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as BinaryImage?,
  ));
}

/// Create a copy of Frame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BinaryImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $BinaryImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}

/// @nodoc
mixin _$LogLine {

 DateTime get time; LogLevel get level; String get message;
/// Create a copy of LogLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogLineCopyWith<LogLine> get copyWith => _$LogLineCopyWithImpl<LogLine>(this as LogLine, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogLine&&(identical(other.time, time) || other.time == time)&&(identical(other.level, level) || other.level == level)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,time,level,message);

@override
String toString() {
  return 'LogLine(time: $time, level: $level, message: $message)';
}


}

/// @nodoc
abstract mixin class $LogLineCopyWith<$Res>  {
  factory $LogLineCopyWith(LogLine value, $Res Function(LogLine) _then) = _$LogLineCopyWithImpl;
@useResult
$Res call({
 DateTime time, LogLevel level, String message
});




}
/// @nodoc
class _$LogLineCopyWithImpl<$Res>
    implements $LogLineCopyWith<$Res> {
  _$LogLineCopyWithImpl(this._self, this._then);

  final LogLine _self;
  final $Res Function(LogLine) _then;

/// Create a copy of LogLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? level = null,Object? message = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LogLine].
extension LogLinePatterns on LogLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogLine value)  $default,){
final _that = this;
switch (_that) {
case _LogLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogLine value)?  $default,){
final _that = this;
switch (_that) {
case _LogLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime time,  LogLevel level,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogLine() when $default != null:
return $default(_that.time,_that.level,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime time,  LogLevel level,  String message)  $default,) {final _that = this;
switch (_that) {
case _LogLine():
return $default(_that.time,_that.level,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime time,  LogLevel level,  String message)?  $default,) {final _that = this;
switch (_that) {
case _LogLine() when $default != null:
return $default(_that.time,_that.level,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _LogLine extends LogLine {
  const _LogLine({required this.time, required this.level, required this.message}): super._();
  

@override final  DateTime time;
@override final  LogLevel level;
@override final  String message;

/// Create a copy of LogLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogLineCopyWith<_LogLine> get copyWith => __$LogLineCopyWithImpl<_LogLine>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogLine&&(identical(other.time, time) || other.time == time)&&(identical(other.level, level) || other.level == level)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,time,level,message);

@override
String toString() {
  return 'LogLine(time: $time, level: $level, message: $message)';
}


}

/// @nodoc
abstract mixin class _$LogLineCopyWith<$Res> implements $LogLineCopyWith<$Res> {
  factory _$LogLineCopyWith(_LogLine value, $Res Function(_LogLine) _then) = __$LogLineCopyWithImpl;
@override @useResult
$Res call({
 DateTime time, LogLevel level, String message
});




}
/// @nodoc
class __$LogLineCopyWithImpl<$Res>
    implements _$LogLineCopyWith<$Res> {
  __$LogLineCopyWithImpl(this._self, this._then);

  final _LogLine _self;
  final $Res Function(_LogLine) _then;

/// Create a copy of LogLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? level = null,Object? message = null,}) {
  return _then(_LogLine(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CapturedCrash {

 String get id; DateTime get time; String get exceptionType; String get message; String get thread; IList<Frame> get frames; AppInfo get app;
/// Create a copy of CapturedCrash
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapturedCrashCopyWith<CapturedCrash> get copyWith => _$CapturedCrashCopyWithImpl<CapturedCrash>(this as CapturedCrash, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapturedCrash&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.exceptionType, exceptionType) || other.exceptionType == exceptionType)&&(identical(other.message, message) || other.message == message)&&(identical(other.thread, thread) || other.thread == thread)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.app, app) || other.app == app));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,exceptionType,message,thread,const DeepCollectionEquality().hash(frames),app);

@override
String toString() {
  return 'CapturedCrash(id: $id, time: $time, exceptionType: $exceptionType, message: $message, thread: $thread, frames: $frames, app: $app)';
}


}

/// @nodoc
abstract mixin class $CapturedCrashCopyWith<$Res>  {
  factory $CapturedCrashCopyWith(CapturedCrash value, $Res Function(CapturedCrash) _then) = _$CapturedCrashCopyWithImpl;
@useResult
$Res call({
 String id, DateTime time, String exceptionType, String message, String thread, IList<Frame> frames, AppInfo app
});


$AppInfoCopyWith<$Res> get app;

}
/// @nodoc
class _$CapturedCrashCopyWithImpl<$Res>
    implements $CapturedCrashCopyWith<$Res> {
  _$CapturedCrashCopyWithImpl(this._self, this._then);

  final CapturedCrash _self;
  final $Res Function(CapturedCrash) _then;

/// Create a copy of CapturedCrash
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? time = null,Object? exceptionType = null,Object? message = null,Object? thread = null,Object? frames = null,Object? app = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,exceptionType: null == exceptionType ? _self.exceptionType : exceptionType // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as IList<Frame>,app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as AppInfo,
  ));
}
/// Create a copy of CapturedCrash
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppInfoCopyWith<$Res> get app {
  
  return $AppInfoCopyWith<$Res>(_self.app, (value) {
    return _then(_self.copyWith(app: value));
  });
}
}


/// Adds pattern-matching-related methods to [CapturedCrash].
extension CapturedCrashPatterns on CapturedCrash {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapturedCrash value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapturedCrash() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapturedCrash value)  $default,){
final _that = this;
switch (_that) {
case _CapturedCrash():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapturedCrash value)?  $default,){
final _that = this;
switch (_that) {
case _CapturedCrash() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime time,  String exceptionType,  String message,  String thread,  IList<Frame> frames,  AppInfo app)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapturedCrash() when $default != null:
return $default(_that.id,_that.time,_that.exceptionType,_that.message,_that.thread,_that.frames,_that.app);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime time,  String exceptionType,  String message,  String thread,  IList<Frame> frames,  AppInfo app)  $default,) {final _that = this;
switch (_that) {
case _CapturedCrash():
return $default(_that.id,_that.time,_that.exceptionType,_that.message,_that.thread,_that.frames,_that.app);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime time,  String exceptionType,  String message,  String thread,  IList<Frame> frames,  AppInfo app)?  $default,) {final _that = this;
switch (_that) {
case _CapturedCrash() when $default != null:
return $default(_that.id,_that.time,_that.exceptionType,_that.message,_that.thread,_that.frames,_that.app);case _:
  return null;

}
}

}

/// @nodoc


class _CapturedCrash implements CapturedCrash {
  const _CapturedCrash({required this.id, required this.time, required this.exceptionType, required this.message, required this.thread, required this.frames, required this.app});
  

@override final  String id;
@override final  DateTime time;
@override final  String exceptionType;
@override final  String message;
@override final  String thread;
@override final  IList<Frame> frames;
@override final  AppInfo app;

/// Create a copy of CapturedCrash
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapturedCrashCopyWith<_CapturedCrash> get copyWith => __$CapturedCrashCopyWithImpl<_CapturedCrash>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapturedCrash&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.exceptionType, exceptionType) || other.exceptionType == exceptionType)&&(identical(other.message, message) || other.message == message)&&(identical(other.thread, thread) || other.thread == thread)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.app, app) || other.app == app));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,exceptionType,message,thread,const DeepCollectionEquality().hash(frames),app);

@override
String toString() {
  return 'CapturedCrash(id: $id, time: $time, exceptionType: $exceptionType, message: $message, thread: $thread, frames: $frames, app: $app)';
}


}

/// @nodoc
abstract mixin class _$CapturedCrashCopyWith<$Res> implements $CapturedCrashCopyWith<$Res> {
  factory _$CapturedCrashCopyWith(_CapturedCrash value, $Res Function(_CapturedCrash) _then) = __$CapturedCrashCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime time, String exceptionType, String message, String thread, IList<Frame> frames, AppInfo app
});


@override $AppInfoCopyWith<$Res> get app;

}
/// @nodoc
class __$CapturedCrashCopyWithImpl<$Res>
    implements _$CapturedCrashCopyWith<$Res> {
  __$CapturedCrashCopyWithImpl(this._self, this._then);

  final _CapturedCrash _self;
  final $Res Function(_CapturedCrash) _then;

/// Create a copy of CapturedCrash
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? time = null,Object? exceptionType = null,Object? message = null,Object? thread = null,Object? frames = null,Object? app = null,}) {
  return _then(_CapturedCrash(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,exceptionType: null == exceptionType ? _self.exceptionType : exceptionType // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as IList<Frame>,app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as AppInfo,
  ));
}

/// Create a copy of CapturedCrash
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppInfoCopyWith<$Res> get app {
  
  return $AppInfoCopyWith<$Res>(_self.app, (value) {
    return _then(_self.copyWith(app: value));
  });
}
}

// dart format on
