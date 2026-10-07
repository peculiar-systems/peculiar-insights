// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurposeStatus {

 Decision get decision; String get policyVersion;
/// Create a copy of PurposeStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurposeStatusCopyWith<PurposeStatus> get copyWith => _$PurposeStatusCopyWithImpl<PurposeStatus>(this as PurposeStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurposeStatus&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,decision,policyVersion);

@override
String toString() {
  return 'PurposeStatus(decision: $decision, policyVersion: $policyVersion)';
}


}

/// @nodoc
abstract mixin class $PurposeStatusCopyWith<$Res>  {
  factory $PurposeStatusCopyWith(PurposeStatus value, $Res Function(PurposeStatus) _then) = _$PurposeStatusCopyWithImpl;
@useResult
$Res call({
 Decision decision, String policyVersion
});




}
/// @nodoc
class _$PurposeStatusCopyWithImpl<$Res>
    implements $PurposeStatusCopyWith<$Res> {
  _$PurposeStatusCopyWithImpl(this._self, this._then);

  final PurposeStatus _self;
  final $Res Function(PurposeStatus) _then;

/// Create a copy of PurposeStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decision = null,Object? policyVersion = null,}) {
  return _then(_self.copyWith(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as Decision,policyVersion: null == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PurposeStatus].
extension PurposeStatusPatterns on PurposeStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurposeStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurposeStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurposeStatus value)  $default,){
final _that = this;
switch (_that) {
case _PurposeStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurposeStatus value)?  $default,){
final _that = this;
switch (_that) {
case _PurposeStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Decision decision,  String policyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurposeStatus() when $default != null:
return $default(_that.decision,_that.policyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Decision decision,  String policyVersion)  $default,) {final _that = this;
switch (_that) {
case _PurposeStatus():
return $default(_that.decision,_that.policyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Decision decision,  String policyVersion)?  $default,) {final _that = this;
switch (_that) {
case _PurposeStatus() when $default != null:
return $default(_that.decision,_that.policyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _PurposeStatus extends PurposeStatus {
  const _PurposeStatus({required this.decision, required this.policyVersion}): super._();
  

@override final  Decision decision;
@override final  String policyVersion;

/// Create a copy of PurposeStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurposeStatusCopyWith<_PurposeStatus> get copyWith => __$PurposeStatusCopyWithImpl<_PurposeStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurposeStatus&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion));
}


@override
int get hashCode => Object.hash(runtimeType,decision,policyVersion);

@override
String toString() {
  return 'PurposeStatus(decision: $decision, policyVersion: $policyVersion)';
}


}

/// @nodoc
abstract mixin class _$PurposeStatusCopyWith<$Res> implements $PurposeStatusCopyWith<$Res> {
  factory _$PurposeStatusCopyWith(_PurposeStatus value, $Res Function(_PurposeStatus) _then) = __$PurposeStatusCopyWithImpl;
@override @useResult
$Res call({
 Decision decision, String policyVersion
});




}
/// @nodoc
class __$PurposeStatusCopyWithImpl<$Res>
    implements _$PurposeStatusCopyWith<$Res> {
  __$PurposeStatusCopyWithImpl(this._self, this._then);

  final _PurposeStatus _self;
  final $Res Function(_PurposeStatus) _then;

/// Create a copy of PurposeStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decision = null,Object? policyVersion = null,}) {
  return _then(_PurposeStatus(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as Decision,policyVersion: null == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Consent {

 IMap<Purpose, PurposeStatus> get purposes;
/// Create a copy of Consent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentCopyWith<Consent> get copyWith => _$ConsentCopyWithImpl<Consent>(this as Consent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Consent&&(identical(other.purposes, purposes) || other.purposes == purposes));
}


@override
int get hashCode => Object.hash(runtimeType,purposes);

@override
String toString() {
  return 'Consent(purposes: $purposes)';
}


}

/// @nodoc
abstract mixin class $ConsentCopyWith<$Res>  {
  factory $ConsentCopyWith(Consent value, $Res Function(Consent) _then) = _$ConsentCopyWithImpl;
@useResult
$Res call({
 IMap<Purpose, PurposeStatus> purposes
});




}
/// @nodoc
class _$ConsentCopyWithImpl<$Res>
    implements $ConsentCopyWith<$Res> {
  _$ConsentCopyWithImpl(this._self, this._then);

  final Consent _self;
  final $Res Function(Consent) _then;

/// Create a copy of Consent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? purposes = null,}) {
  return _then(_self.copyWith(
purposes: null == purposes ? _self.purposes : purposes // ignore: cast_nullable_to_non_nullable
as IMap<Purpose, PurposeStatus>,
  ));
}

}


/// Adds pattern-matching-related methods to [Consent].
extension ConsentPatterns on Consent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Consent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Consent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Consent value)  $default,){
final _that = this;
switch (_that) {
case _Consent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Consent value)?  $default,){
final _that = this;
switch (_that) {
case _Consent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IMap<Purpose, PurposeStatus> purposes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Consent() when $default != null:
return $default(_that.purposes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IMap<Purpose, PurposeStatus> purposes)  $default,) {final _that = this;
switch (_that) {
case _Consent():
return $default(_that.purposes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IMap<Purpose, PurposeStatus> purposes)?  $default,) {final _that = this;
switch (_that) {
case _Consent() when $default != null:
return $default(_that.purposes);case _:
  return null;

}
}

}

/// @nodoc


class _Consent extends Consent {
  const _Consent({this.purposes = const IMapConst({})}): super._();
  

@override@JsonKey() final  IMap<Purpose, PurposeStatus> purposes;

/// Create a copy of Consent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentCopyWith<_Consent> get copyWith => __$ConsentCopyWithImpl<_Consent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Consent&&(identical(other.purposes, purposes) || other.purposes == purposes));
}


@override
int get hashCode => Object.hash(runtimeType,purposes);

@override
String toString() {
  return 'Consent(purposes: $purposes)';
}


}

/// @nodoc
abstract mixin class _$ConsentCopyWith<$Res> implements $ConsentCopyWith<$Res> {
  factory _$ConsentCopyWith(_Consent value, $Res Function(_Consent) _then) = __$ConsentCopyWithImpl;
@override @useResult
$Res call({
 IMap<Purpose, PurposeStatus> purposes
});




}
/// @nodoc
class __$ConsentCopyWithImpl<$Res>
    implements _$ConsentCopyWith<$Res> {
  __$ConsentCopyWithImpl(this._self, this._then);

  final _Consent _self;
  final $Res Function(_Consent) _then;

/// Create a copy of Consent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? purposes = null,}) {
  return _then(_Consent(
purposes: null == purposes ? _self.purposes : purposes // ignore: cast_nullable_to_non_nullable
as IMap<Purpose, PurposeStatus>,
  ));
}


}

// dart format on
