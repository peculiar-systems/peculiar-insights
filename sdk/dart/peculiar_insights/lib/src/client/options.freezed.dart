// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppInfo {

 String get version; String get build;
/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppInfoCopyWith<AppInfo> get copyWith => _$AppInfoCopyWithImpl<AppInfo>(this as AppInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppInfo&&(identical(other.version, version) || other.version == version)&&(identical(other.build, build) || other.build == build));
}


@override
int get hashCode => Object.hash(runtimeType,version,build);

@override
String toString() {
  return 'AppInfo(version: $version, build: $build)';
}


}

/// @nodoc
abstract mixin class $AppInfoCopyWith<$Res>  {
  factory $AppInfoCopyWith(AppInfo value, $Res Function(AppInfo) _then) = _$AppInfoCopyWithImpl;
@useResult
$Res call({
 String version, String build
});




}
/// @nodoc
class _$AppInfoCopyWithImpl<$Res>
    implements $AppInfoCopyWith<$Res> {
  _$AppInfoCopyWithImpl(this._self, this._then);

  final AppInfo _self;
  final $Res Function(AppInfo) _then;

/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? build = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,build: null == build ? _self.build : build // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppInfo].
extension AppInfoPatterns on AppInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppInfo value)  $default,){
final _that = this;
switch (_that) {
case _AppInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String build)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
return $default(_that.version,_that.build);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String build)  $default,) {final _that = this;
switch (_that) {
case _AppInfo():
return $default(_that.version,_that.build);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String build)?  $default,) {final _that = this;
switch (_that) {
case _AppInfo() when $default != null:
return $default(_that.version,_that.build);case _:
  return null;

}
}

}

/// @nodoc


class _AppInfo implements AppInfo {
  const _AppInfo({required this.version, required this.build});
  

@override final  String version;
@override final  String build;

/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppInfoCopyWith<_AppInfo> get copyWith => __$AppInfoCopyWithImpl<_AppInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppInfo&&(identical(other.version, version) || other.version == version)&&(identical(other.build, build) || other.build == build));
}


@override
int get hashCode => Object.hash(runtimeType,version,build);

@override
String toString() {
  return 'AppInfo(version: $version, build: $build)';
}


}

/// @nodoc
abstract mixin class _$AppInfoCopyWith<$Res> implements $AppInfoCopyWith<$Res> {
  factory _$AppInfoCopyWith(_AppInfo value, $Res Function(_AppInfo) _then) = __$AppInfoCopyWithImpl;
@override @useResult
$Res call({
 String version, String build
});




}
/// @nodoc
class __$AppInfoCopyWithImpl<$Res>
    implements _$AppInfoCopyWith<$Res> {
  __$AppInfoCopyWithImpl(this._self, this._then);

  final _AppInfo _self;
  final $Res Function(_AppInfo) _then;

/// Create a copy of AppInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? build = null,}) {
  return _then(_AppInfo(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,build: null == build ? _self.build : build // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$InsightsOptions {

 String get sdkName; Duration get flushInterval; int get batchSize; int get bufferLimit; Duration get sessionTimeout; Duration get callTimeout; int get logLimit; IList<String> get inAppPackages; bool get privacyControlSignal; Scrubber? get scrubber;
/// Create a copy of InsightsOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightsOptionsCopyWith<InsightsOptions> get copyWith => _$InsightsOptionsCopyWithImpl<InsightsOptions>(this as InsightsOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightsOptions&&(identical(other.sdkName, sdkName) || other.sdkName == sdkName)&&(identical(other.flushInterval, flushInterval) || other.flushInterval == flushInterval)&&(identical(other.batchSize, batchSize) || other.batchSize == batchSize)&&(identical(other.bufferLimit, bufferLimit) || other.bufferLimit == bufferLimit)&&(identical(other.sessionTimeout, sessionTimeout) || other.sessionTimeout == sessionTimeout)&&(identical(other.callTimeout, callTimeout) || other.callTimeout == callTimeout)&&(identical(other.logLimit, logLimit) || other.logLimit == logLimit)&&const DeepCollectionEquality().equals(other.inAppPackages, inAppPackages)&&(identical(other.privacyControlSignal, privacyControlSignal) || other.privacyControlSignal == privacyControlSignal)&&(identical(other.scrubber, scrubber) || other.scrubber == scrubber));
}


@override
int get hashCode => Object.hash(runtimeType,sdkName,flushInterval,batchSize,bufferLimit,sessionTimeout,callTimeout,logLimit,const DeepCollectionEquality().hash(inAppPackages),privacyControlSignal,scrubber);

@override
String toString() {
  return 'InsightsOptions(sdkName: $sdkName, flushInterval: $flushInterval, batchSize: $batchSize, bufferLimit: $bufferLimit, sessionTimeout: $sessionTimeout, callTimeout: $callTimeout, logLimit: $logLimit, inAppPackages: $inAppPackages, privacyControlSignal: $privacyControlSignal, scrubber: $scrubber)';
}


}

/// @nodoc
abstract mixin class $InsightsOptionsCopyWith<$Res>  {
  factory $InsightsOptionsCopyWith(InsightsOptions value, $Res Function(InsightsOptions) _then) = _$InsightsOptionsCopyWithImpl;
@useResult
$Res call({
 String sdkName, Duration flushInterval, int batchSize, int bufferLimit, Duration sessionTimeout, Duration callTimeout, int logLimit, IList<String> inAppPackages, bool privacyControlSignal, Scrubber? scrubber
});




}
/// @nodoc
class _$InsightsOptionsCopyWithImpl<$Res>
    implements $InsightsOptionsCopyWith<$Res> {
  _$InsightsOptionsCopyWithImpl(this._self, this._then);

  final InsightsOptions _self;
  final $Res Function(InsightsOptions) _then;

/// Create a copy of InsightsOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sdkName = null,Object? flushInterval = null,Object? batchSize = null,Object? bufferLimit = null,Object? sessionTimeout = null,Object? callTimeout = null,Object? logLimit = null,Object? inAppPackages = null,Object? privacyControlSignal = null,Object? scrubber = freezed,}) {
  return _then(_self.copyWith(
sdkName: null == sdkName ? _self.sdkName : sdkName // ignore: cast_nullable_to_non_nullable
as String,flushInterval: null == flushInterval ? _self.flushInterval : flushInterval // ignore: cast_nullable_to_non_nullable
as Duration,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
as int,bufferLimit: null == bufferLimit ? _self.bufferLimit : bufferLimit // ignore: cast_nullable_to_non_nullable
as int,sessionTimeout: null == sessionTimeout ? _self.sessionTimeout : sessionTimeout // ignore: cast_nullable_to_non_nullable
as Duration,callTimeout: null == callTimeout ? _self.callTimeout : callTimeout // ignore: cast_nullable_to_non_nullable
as Duration,logLimit: null == logLimit ? _self.logLimit : logLimit // ignore: cast_nullable_to_non_nullable
as int,inAppPackages: null == inAppPackages ? _self.inAppPackages : inAppPackages // ignore: cast_nullable_to_non_nullable
as IList<String>,privacyControlSignal: null == privacyControlSignal ? _self.privacyControlSignal : privacyControlSignal // ignore: cast_nullable_to_non_nullable
as bool,scrubber: freezed == scrubber ? _self.scrubber : scrubber // ignore: cast_nullable_to_non_nullable
as Scrubber?,
  ));
}

}


/// Adds pattern-matching-related methods to [InsightsOptions].
extension InsightsOptionsPatterns on InsightsOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightsOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightsOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightsOptions value)  $default,){
final _that = this;
switch (_that) {
case _InsightsOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightsOptions value)?  $default,){
final _that = this;
switch (_that) {
case _InsightsOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sdkName,  Duration flushInterval,  int batchSize,  int bufferLimit,  Duration sessionTimeout,  Duration callTimeout,  int logLimit,  IList<String> inAppPackages,  bool privacyControlSignal,  Scrubber? scrubber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightsOptions() when $default != null:
return $default(_that.sdkName,_that.flushInterval,_that.batchSize,_that.bufferLimit,_that.sessionTimeout,_that.callTimeout,_that.logLimit,_that.inAppPackages,_that.privacyControlSignal,_that.scrubber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sdkName,  Duration flushInterval,  int batchSize,  int bufferLimit,  Duration sessionTimeout,  Duration callTimeout,  int logLimit,  IList<String> inAppPackages,  bool privacyControlSignal,  Scrubber? scrubber)  $default,) {final _that = this;
switch (_that) {
case _InsightsOptions():
return $default(_that.sdkName,_that.flushInterval,_that.batchSize,_that.bufferLimit,_that.sessionTimeout,_that.callTimeout,_that.logLimit,_that.inAppPackages,_that.privacyControlSignal,_that.scrubber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sdkName,  Duration flushInterval,  int batchSize,  int bufferLimit,  Duration sessionTimeout,  Duration callTimeout,  int logLimit,  IList<String> inAppPackages,  bool privacyControlSignal,  Scrubber? scrubber)?  $default,) {final _that = this;
switch (_that) {
case _InsightsOptions() when $default != null:
return $default(_that.sdkName,_that.flushInterval,_that.batchSize,_that.bufferLimit,_that.sessionTimeout,_that.callTimeout,_that.logLimit,_that.inAppPackages,_that.privacyControlSignal,_that.scrubber);case _:
  return null;

}
}

}

/// @nodoc


class _InsightsOptions implements InsightsOptions {
  const _InsightsOptions({this.sdkName = "dart", this.flushInterval = const Duration(seconds: 10), this.batchSize = 100, this.bufferLimit = 500, this.sessionTimeout = const Duration(minutes: 30), this.callTimeout = const Duration(seconds: 20), this.logLimit = 64, this.inAppPackages = const IListConst([]), this.privacyControlSignal = false, this.scrubber});
  

@override@JsonKey() final  String sdkName;
@override@JsonKey() final  Duration flushInterval;
@override@JsonKey() final  int batchSize;
@override@JsonKey() final  int bufferLimit;
@override@JsonKey() final  Duration sessionTimeout;
@override@JsonKey() final  Duration callTimeout;
@override@JsonKey() final  int logLimit;
@override@JsonKey() final  IList<String> inAppPackages;
@override@JsonKey() final  bool privacyControlSignal;
@override final  Scrubber? scrubber;

/// Create a copy of InsightsOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightsOptionsCopyWith<_InsightsOptions> get copyWith => __$InsightsOptionsCopyWithImpl<_InsightsOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightsOptions&&(identical(other.sdkName, sdkName) || other.sdkName == sdkName)&&(identical(other.flushInterval, flushInterval) || other.flushInterval == flushInterval)&&(identical(other.batchSize, batchSize) || other.batchSize == batchSize)&&(identical(other.bufferLimit, bufferLimit) || other.bufferLimit == bufferLimit)&&(identical(other.sessionTimeout, sessionTimeout) || other.sessionTimeout == sessionTimeout)&&(identical(other.callTimeout, callTimeout) || other.callTimeout == callTimeout)&&(identical(other.logLimit, logLimit) || other.logLimit == logLimit)&&const DeepCollectionEquality().equals(other.inAppPackages, inAppPackages)&&(identical(other.privacyControlSignal, privacyControlSignal) || other.privacyControlSignal == privacyControlSignal)&&(identical(other.scrubber, scrubber) || other.scrubber == scrubber));
}


@override
int get hashCode => Object.hash(runtimeType,sdkName,flushInterval,batchSize,bufferLimit,sessionTimeout,callTimeout,logLimit,const DeepCollectionEquality().hash(inAppPackages),privacyControlSignal,scrubber);

@override
String toString() {
  return 'InsightsOptions(sdkName: $sdkName, flushInterval: $flushInterval, batchSize: $batchSize, bufferLimit: $bufferLimit, sessionTimeout: $sessionTimeout, callTimeout: $callTimeout, logLimit: $logLimit, inAppPackages: $inAppPackages, privacyControlSignal: $privacyControlSignal, scrubber: $scrubber)';
}


}

/// @nodoc
abstract mixin class _$InsightsOptionsCopyWith<$Res> implements $InsightsOptionsCopyWith<$Res> {
  factory _$InsightsOptionsCopyWith(_InsightsOptions value, $Res Function(_InsightsOptions) _then) = __$InsightsOptionsCopyWithImpl;
@override @useResult
$Res call({
 String sdkName, Duration flushInterval, int batchSize, int bufferLimit, Duration sessionTimeout, Duration callTimeout, int logLimit, IList<String> inAppPackages, bool privacyControlSignal, Scrubber? scrubber
});




}
/// @nodoc
class __$InsightsOptionsCopyWithImpl<$Res>
    implements _$InsightsOptionsCopyWith<$Res> {
  __$InsightsOptionsCopyWithImpl(this._self, this._then);

  final _InsightsOptions _self;
  final $Res Function(_InsightsOptions) _then;

/// Create a copy of InsightsOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sdkName = null,Object? flushInterval = null,Object? batchSize = null,Object? bufferLimit = null,Object? sessionTimeout = null,Object? callTimeout = null,Object? logLimit = null,Object? inAppPackages = null,Object? privacyControlSignal = null,Object? scrubber = freezed,}) {
  return _then(_InsightsOptions(
sdkName: null == sdkName ? _self.sdkName : sdkName // ignore: cast_nullable_to_non_nullable
as String,flushInterval: null == flushInterval ? _self.flushInterval : flushInterval // ignore: cast_nullable_to_non_nullable
as Duration,batchSize: null == batchSize ? _self.batchSize : batchSize // ignore: cast_nullable_to_non_nullable
as int,bufferLimit: null == bufferLimit ? _self.bufferLimit : bufferLimit // ignore: cast_nullable_to_non_nullable
as int,sessionTimeout: null == sessionTimeout ? _self.sessionTimeout : sessionTimeout // ignore: cast_nullable_to_non_nullable
as Duration,callTimeout: null == callTimeout ? _self.callTimeout : callTimeout // ignore: cast_nullable_to_non_nullable
as Duration,logLimit: null == logLimit ? _self.logLimit : logLimit // ignore: cast_nullable_to_non_nullable
as int,inAppPackages: null == inAppPackages ? _self.inAppPackages : inAppPackages // ignore: cast_nullable_to_non_nullable
as IList<String>,privacyControlSignal: null == privacyControlSignal ? _self.privacyControlSignal : privacyControlSignal // ignore: cast_nullable_to_non_nullable
as bool,scrubber: freezed == scrubber ? _self.scrubber : scrubber // ignore: cast_nullable_to_non_nullable
as Scrubber?,
  ));
}


}

// dart format on
