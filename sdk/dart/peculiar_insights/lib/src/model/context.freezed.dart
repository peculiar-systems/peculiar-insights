// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlatformInfo {

 AppPlatform get platform; String get osName; String get osVersion; String get deviceModel; String get locale; String get timezone; int get screenWidth; int get screenHeight;
/// Create a copy of PlatformInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlatformInfoCopyWith<PlatformInfo> get copyWith => _$PlatformInfoCopyWithImpl<PlatformInfo>(this as PlatformInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformInfo&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.osName, osName) || other.osName == osName)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.deviceModel, deviceModel) || other.deviceModel == deviceModel)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.screenWidth, screenWidth) || other.screenWidth == screenWidth)&&(identical(other.screenHeight, screenHeight) || other.screenHeight == screenHeight));
}


@override
int get hashCode => Object.hash(runtimeType,platform,osName,osVersion,deviceModel,locale,timezone,screenWidth,screenHeight);

@override
String toString() {
  return 'PlatformInfo(platform: $platform, osName: $osName, osVersion: $osVersion, deviceModel: $deviceModel, locale: $locale, timezone: $timezone, screenWidth: $screenWidth, screenHeight: $screenHeight)';
}


}

/// @nodoc
abstract mixin class $PlatformInfoCopyWith<$Res>  {
  factory $PlatformInfoCopyWith(PlatformInfo value, $Res Function(PlatformInfo) _then) = _$PlatformInfoCopyWithImpl;
@useResult
$Res call({
 AppPlatform platform, String osName, String osVersion, String deviceModel, String locale, String timezone, int screenWidth, int screenHeight
});




}
/// @nodoc
class _$PlatformInfoCopyWithImpl<$Res>
    implements $PlatformInfoCopyWith<$Res> {
  _$PlatformInfoCopyWithImpl(this._self, this._then);

  final PlatformInfo _self;
  final $Res Function(PlatformInfo) _then;

/// Create a copy of PlatformInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? osName = null,Object? osVersion = null,Object? deviceModel = null,Object? locale = null,Object? timezone = null,Object? screenWidth = null,Object? screenHeight = null,}) {
  return _then(_self.copyWith(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as AppPlatform,osName: null == osName ? _self.osName : osName // ignore: cast_nullable_to_non_nullable
as String,osVersion: null == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String,deviceModel: null == deviceModel ? _self.deviceModel : deviceModel // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,screenWidth: null == screenWidth ? _self.screenWidth : screenWidth // ignore: cast_nullable_to_non_nullable
as int,screenHeight: null == screenHeight ? _self.screenHeight : screenHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlatformInfo].
extension PlatformInfoPatterns on PlatformInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlatformInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlatformInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlatformInfo value)  $default,){
final _that = this;
switch (_that) {
case _PlatformInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlatformInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PlatformInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppPlatform platform,  String osName,  String osVersion,  String deviceModel,  String locale,  String timezone,  int screenWidth,  int screenHeight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlatformInfo() when $default != null:
return $default(_that.platform,_that.osName,_that.osVersion,_that.deviceModel,_that.locale,_that.timezone,_that.screenWidth,_that.screenHeight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppPlatform platform,  String osName,  String osVersion,  String deviceModel,  String locale,  String timezone,  int screenWidth,  int screenHeight)  $default,) {final _that = this;
switch (_that) {
case _PlatformInfo():
return $default(_that.platform,_that.osName,_that.osVersion,_that.deviceModel,_that.locale,_that.timezone,_that.screenWidth,_that.screenHeight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppPlatform platform,  String osName,  String osVersion,  String deviceModel,  String locale,  String timezone,  int screenWidth,  int screenHeight)?  $default,) {final _that = this;
switch (_that) {
case _PlatformInfo() when $default != null:
return $default(_that.platform,_that.osName,_that.osVersion,_that.deviceModel,_that.locale,_that.timezone,_that.screenWidth,_that.screenHeight);case _:
  return null;

}
}

}

/// @nodoc


class _PlatformInfo extends PlatformInfo {
  const _PlatformInfo({required this.platform, required this.osName, required this.osVersion, required this.deviceModel, required this.locale, required this.timezone, required this.screenWidth, required this.screenHeight}): super._();
  

@override final  AppPlatform platform;
@override final  String osName;
@override final  String osVersion;
@override final  String deviceModel;
@override final  String locale;
@override final  String timezone;
@override final  int screenWidth;
@override final  int screenHeight;

/// Create a copy of PlatformInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlatformInfoCopyWith<_PlatformInfo> get copyWith => __$PlatformInfoCopyWithImpl<_PlatformInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlatformInfo&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.osName, osName) || other.osName == osName)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.deviceModel, deviceModel) || other.deviceModel == deviceModel)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.screenWidth, screenWidth) || other.screenWidth == screenWidth)&&(identical(other.screenHeight, screenHeight) || other.screenHeight == screenHeight));
}


@override
int get hashCode => Object.hash(runtimeType,platform,osName,osVersion,deviceModel,locale,timezone,screenWidth,screenHeight);

@override
String toString() {
  return 'PlatformInfo(platform: $platform, osName: $osName, osVersion: $osVersion, deviceModel: $deviceModel, locale: $locale, timezone: $timezone, screenWidth: $screenWidth, screenHeight: $screenHeight)';
}


}

/// @nodoc
abstract mixin class _$PlatformInfoCopyWith<$Res> implements $PlatformInfoCopyWith<$Res> {
  factory _$PlatformInfoCopyWith(_PlatformInfo value, $Res Function(_PlatformInfo) _then) = __$PlatformInfoCopyWithImpl;
@override @useResult
$Res call({
 AppPlatform platform, String osName, String osVersion, String deviceModel, String locale, String timezone, int screenWidth, int screenHeight
});




}
/// @nodoc
class __$PlatformInfoCopyWithImpl<$Res>
    implements _$PlatformInfoCopyWith<$Res> {
  __$PlatformInfoCopyWithImpl(this._self, this._then);

  final _PlatformInfo _self;
  final $Res Function(_PlatformInfo) _then;

/// Create a copy of PlatformInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? osName = null,Object? osVersion = null,Object? deviceModel = null,Object? locale = null,Object? timezone = null,Object? screenWidth = null,Object? screenHeight = null,}) {
  return _then(_PlatformInfo(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as AppPlatform,osName: null == osName ? _self.osName : osName // ignore: cast_nullable_to_non_nullable
as String,osVersion: null == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String,deviceModel: null == deviceModel ? _self.deviceModel : deviceModel // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,screenWidth: null == screenWidth ? _self.screenWidth : screenWidth // ignore: cast_nullable_to_non_nullable
as int,screenHeight: null == screenHeight ? _self.screenHeight : screenHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AppContext {

 String get sdkName; String get sdkVersion; String get appVersion; String get appBuild; PlatformInfo get platform;
/// Create a copy of AppContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppContextCopyWith<AppContext> get copyWith => _$AppContextCopyWithImpl<AppContext>(this as AppContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppContext&&(identical(other.sdkName, sdkName) || other.sdkName == sdkName)&&(identical(other.sdkVersion, sdkVersion) || other.sdkVersion == sdkVersion)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appBuild, appBuild) || other.appBuild == appBuild)&&(identical(other.platform, platform) || other.platform == platform));
}


@override
int get hashCode => Object.hash(runtimeType,sdkName,sdkVersion,appVersion,appBuild,platform);

@override
String toString() {
  return 'AppContext(sdkName: $sdkName, sdkVersion: $sdkVersion, appVersion: $appVersion, appBuild: $appBuild, platform: $platform)';
}


}

/// @nodoc
abstract mixin class $AppContextCopyWith<$Res>  {
  factory $AppContextCopyWith(AppContext value, $Res Function(AppContext) _then) = _$AppContextCopyWithImpl;
@useResult
$Res call({
 String sdkName, String sdkVersion, String appVersion, String appBuild, PlatformInfo platform
});


$PlatformInfoCopyWith<$Res> get platform;

}
/// @nodoc
class _$AppContextCopyWithImpl<$Res>
    implements $AppContextCopyWith<$Res> {
  _$AppContextCopyWithImpl(this._self, this._then);

  final AppContext _self;
  final $Res Function(AppContext) _then;

/// Create a copy of AppContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sdkName = null,Object? sdkVersion = null,Object? appVersion = null,Object? appBuild = null,Object? platform = null,}) {
  return _then(_self.copyWith(
sdkName: null == sdkName ? _self.sdkName : sdkName // ignore: cast_nullable_to_non_nullable
as String,sdkVersion: null == sdkVersion ? _self.sdkVersion : sdkVersion // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appBuild: null == appBuild ? _self.appBuild : appBuild // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as PlatformInfo,
  ));
}
/// Create a copy of AppContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlatformInfoCopyWith<$Res> get platform {
  
  return $PlatformInfoCopyWith<$Res>(_self.platform, (value) {
    return _then(_self.copyWith(platform: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppContext].
extension AppContextPatterns on AppContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppContext value)  $default,){
final _that = this;
switch (_that) {
case _AppContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppContext value)?  $default,){
final _that = this;
switch (_that) {
case _AppContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sdkName,  String sdkVersion,  String appVersion,  String appBuild,  PlatformInfo platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppContext() when $default != null:
return $default(_that.sdkName,_that.sdkVersion,_that.appVersion,_that.appBuild,_that.platform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sdkName,  String sdkVersion,  String appVersion,  String appBuild,  PlatformInfo platform)  $default,) {final _that = this;
switch (_that) {
case _AppContext():
return $default(_that.sdkName,_that.sdkVersion,_that.appVersion,_that.appBuild,_that.platform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sdkName,  String sdkVersion,  String appVersion,  String appBuild,  PlatformInfo platform)?  $default,) {final _that = this;
switch (_that) {
case _AppContext() when $default != null:
return $default(_that.sdkName,_that.sdkVersion,_that.appVersion,_that.appBuild,_that.platform);case _:
  return null;

}
}

}

/// @nodoc


class _AppContext extends AppContext {
  const _AppContext({required this.sdkName, required this.sdkVersion, required this.appVersion, required this.appBuild, required this.platform}): super._();
  

@override final  String sdkName;
@override final  String sdkVersion;
@override final  String appVersion;
@override final  String appBuild;
@override final  PlatformInfo platform;

/// Create a copy of AppContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppContextCopyWith<_AppContext> get copyWith => __$AppContextCopyWithImpl<_AppContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppContext&&(identical(other.sdkName, sdkName) || other.sdkName == sdkName)&&(identical(other.sdkVersion, sdkVersion) || other.sdkVersion == sdkVersion)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appBuild, appBuild) || other.appBuild == appBuild)&&(identical(other.platform, platform) || other.platform == platform));
}


@override
int get hashCode => Object.hash(runtimeType,sdkName,sdkVersion,appVersion,appBuild,platform);

@override
String toString() {
  return 'AppContext(sdkName: $sdkName, sdkVersion: $sdkVersion, appVersion: $appVersion, appBuild: $appBuild, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$AppContextCopyWith<$Res> implements $AppContextCopyWith<$Res> {
  factory _$AppContextCopyWith(_AppContext value, $Res Function(_AppContext) _then) = __$AppContextCopyWithImpl;
@override @useResult
$Res call({
 String sdkName, String sdkVersion, String appVersion, String appBuild, PlatformInfo platform
});


@override $PlatformInfoCopyWith<$Res> get platform;

}
/// @nodoc
class __$AppContextCopyWithImpl<$Res>
    implements _$AppContextCopyWith<$Res> {
  __$AppContextCopyWithImpl(this._self, this._then);

  final _AppContext _self;
  final $Res Function(_AppContext) _then;

/// Create a copy of AppContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sdkName = null,Object? sdkVersion = null,Object? appVersion = null,Object? appBuild = null,Object? platform = null,}) {
  return _then(_AppContext(
sdkName: null == sdkName ? _self.sdkName : sdkName // ignore: cast_nullable_to_non_nullable
as String,sdkVersion: null == sdkVersion ? _self.sdkVersion : sdkVersion // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appBuild: null == appBuild ? _self.appBuild : appBuild // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as PlatformInfo,
  ));
}

/// Create a copy of AppContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlatformInfoCopyWith<$Res> get platform {
  
  return $PlatformInfoCopyWith<$Res>(_self.platform, (value) {
    return _then(_self.copyWith(platform: value));
  });
}
}

// dart format on
