// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClientState {

 DeviceId get deviceId; bool get devicePersisted; UserId? get userId; Consent get consent; Session get session; PendingBuffer get buffer; IList<LogLine> get logs;
/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientStateCopyWith<ClientState> get copyWith => _$ClientStateCopyWithImpl<ClientState>(this as ClientState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientState&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.devicePersisted, devicePersisted) || other.devicePersisted == devicePersisted)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.consent, consent) || other.consent == consent)&&(identical(other.session, session) || other.session == session)&&(identical(other.buffer, buffer) || other.buffer == buffer)&&const DeepCollectionEquality().equals(other.logs, logs));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,devicePersisted,userId,consent,session,buffer,const DeepCollectionEquality().hash(logs));

@override
String toString() {
  return 'ClientState(deviceId: $deviceId, devicePersisted: $devicePersisted, userId: $userId, consent: $consent, session: $session, buffer: $buffer, logs: $logs)';
}


}

/// @nodoc
abstract mixin class $ClientStateCopyWith<$Res>  {
  factory $ClientStateCopyWith(ClientState value, $Res Function(ClientState) _then) = _$ClientStateCopyWithImpl;
@useResult
$Res call({
 DeviceId deviceId, bool devicePersisted, UserId? userId, Consent consent, Session session, PendingBuffer buffer, IList<LogLine> logs
});


$ConsentCopyWith<$Res> get consent;$SessionCopyWith<$Res> get session;$PendingBufferCopyWith<$Res> get buffer;

}
/// @nodoc
class _$ClientStateCopyWithImpl<$Res>
    implements $ClientStateCopyWith<$Res> {
  _$ClientStateCopyWithImpl(this._self, this._then);

  final ClientState _self;
  final $Res Function(ClientState) _then;

/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? devicePersisted = null,Object? userId = freezed,Object? consent = null,Object? session = null,Object? buffer = null,Object? logs = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeviceId,devicePersisted: null == devicePersisted ? _self.devicePersisted : devicePersisted // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as UserId?,consent: null == consent ? _self.consent : consent // ignore: cast_nullable_to_non_nullable
as Consent,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,buffer: null == buffer ? _self.buffer : buffer // ignore: cast_nullable_to_non_nullable
as PendingBuffer,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as IList<LogLine>,
  ));
}
/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsentCopyWith<$Res> get consent {
  
  return $ConsentCopyWith<$Res>(_self.consent, (value) {
    return _then(_self.copyWith(consent: value));
  });
}/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res> get session {
  
  return $SessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingBufferCopyWith<$Res> get buffer {
  
  return $PendingBufferCopyWith<$Res>(_self.buffer, (value) {
    return _then(_self.copyWith(buffer: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClientState].
extension ClientStatePatterns on ClientState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientState value)  $default,){
final _that = this;
switch (_that) {
case _ClientState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientState value)?  $default,){
final _that = this;
switch (_that) {
case _ClientState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeviceId deviceId,  bool devicePersisted,  UserId? userId,  Consent consent,  Session session,  PendingBuffer buffer,  IList<LogLine> logs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientState() when $default != null:
return $default(_that.deviceId,_that.devicePersisted,_that.userId,_that.consent,_that.session,_that.buffer,_that.logs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeviceId deviceId,  bool devicePersisted,  UserId? userId,  Consent consent,  Session session,  PendingBuffer buffer,  IList<LogLine> logs)  $default,) {final _that = this;
switch (_that) {
case _ClientState():
return $default(_that.deviceId,_that.devicePersisted,_that.userId,_that.consent,_that.session,_that.buffer,_that.logs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeviceId deviceId,  bool devicePersisted,  UserId? userId,  Consent consent,  Session session,  PendingBuffer buffer,  IList<LogLine> logs)?  $default,) {final _that = this;
switch (_that) {
case _ClientState() when $default != null:
return $default(_that.deviceId,_that.devicePersisted,_that.userId,_that.consent,_that.session,_that.buffer,_that.logs);case _:
  return null;

}
}

}

/// @nodoc


class _ClientState extends ClientState {
  const _ClientState({required this.deviceId, required this.devicePersisted, required this.userId, required this.consent, required this.session, required this.buffer, this.logs = const IListConst([])}): super._();
  

@override final  DeviceId deviceId;
@override final  bool devicePersisted;
@override final  UserId? userId;
@override final  Consent consent;
@override final  Session session;
@override final  PendingBuffer buffer;
@override@JsonKey() final  IList<LogLine> logs;

/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientStateCopyWith<_ClientState> get copyWith => __$ClientStateCopyWithImpl<_ClientState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientState&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.devicePersisted, devicePersisted) || other.devicePersisted == devicePersisted)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.consent, consent) || other.consent == consent)&&(identical(other.session, session) || other.session == session)&&(identical(other.buffer, buffer) || other.buffer == buffer)&&const DeepCollectionEquality().equals(other.logs, logs));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,devicePersisted,userId,consent,session,buffer,const DeepCollectionEquality().hash(logs));

@override
String toString() {
  return 'ClientState(deviceId: $deviceId, devicePersisted: $devicePersisted, userId: $userId, consent: $consent, session: $session, buffer: $buffer, logs: $logs)';
}


}

/// @nodoc
abstract mixin class _$ClientStateCopyWith<$Res> implements $ClientStateCopyWith<$Res> {
  factory _$ClientStateCopyWith(_ClientState value, $Res Function(_ClientState) _then) = __$ClientStateCopyWithImpl;
@override @useResult
$Res call({
 DeviceId deviceId, bool devicePersisted, UserId? userId, Consent consent, Session session, PendingBuffer buffer, IList<LogLine> logs
});


@override $ConsentCopyWith<$Res> get consent;@override $SessionCopyWith<$Res> get session;@override $PendingBufferCopyWith<$Res> get buffer;

}
/// @nodoc
class __$ClientStateCopyWithImpl<$Res>
    implements _$ClientStateCopyWith<$Res> {
  __$ClientStateCopyWithImpl(this._self, this._then);

  final _ClientState _self;
  final $Res Function(_ClientState) _then;

/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? devicePersisted = null,Object? userId = freezed,Object? consent = null,Object? session = null,Object? buffer = null,Object? logs = null,}) {
  return _then(_ClientState(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeviceId,devicePersisted: null == devicePersisted ? _self.devicePersisted : devicePersisted // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as UserId?,consent: null == consent ? _self.consent : consent // ignore: cast_nullable_to_non_nullable
as Consent,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as Session,buffer: null == buffer ? _self.buffer : buffer // ignore: cast_nullable_to_non_nullable
as PendingBuffer,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as IList<LogLine>,
  ));
}

/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsentCopyWith<$Res> get consent {
  
  return $ConsentCopyWith<$Res>(_self.consent, (value) {
    return _then(_self.copyWith(consent: value));
  });
}/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionCopyWith<$Res> get session {
  
  return $SessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of ClientState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingBufferCopyWith<$Res> get buffer {
  
  return $PendingBufferCopyWith<$Res>(_self.buffer, (value) {
    return _then(_self.copyWith(buffer: value));
  });
}
}

// dart format on
