// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Subject {

 DeviceId get device; UserId? get user; SessionId get session;
/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubjectCopyWith<Subject> get copyWith => _$SubjectCopyWithImpl<Subject>(this as Subject, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subject&&(identical(other.device, device) || other.device == device)&&(identical(other.user, user) || other.user == user)&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,device,user,session);

@override
String toString() {
  return 'Subject(device: $device, user: $user, session: $session)';
}


}

/// @nodoc
abstract mixin class $SubjectCopyWith<$Res>  {
  factory $SubjectCopyWith(Subject value, $Res Function(Subject) _then) = _$SubjectCopyWithImpl;
@useResult
$Res call({
 DeviceId device, UserId? user, SessionId session
});




}
/// @nodoc
class _$SubjectCopyWithImpl<$Res>
    implements $SubjectCopyWith<$Res> {
  _$SubjectCopyWithImpl(this._self, this._then);

  final Subject _self;
  final $Res Function(Subject) _then;

/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? device = null,Object? user = freezed,Object? session = null,}) {
  return _then(_self.copyWith(
device: null == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as DeviceId,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserId?,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SessionId,
  ));
}

}


/// Adds pattern-matching-related methods to [Subject].
extension SubjectPatterns on Subject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subject() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subject value)  $default,){
final _that = this;
switch (_that) {
case _Subject():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subject value)?  $default,){
final _that = this;
switch (_that) {
case _Subject() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeviceId device,  UserId? user,  SessionId session)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subject() when $default != null:
return $default(_that.device,_that.user,_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeviceId device,  UserId? user,  SessionId session)  $default,) {final _that = this;
switch (_that) {
case _Subject():
return $default(_that.device,_that.user,_that.session);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeviceId device,  UserId? user,  SessionId session)?  $default,) {final _that = this;
switch (_that) {
case _Subject() when $default != null:
return $default(_that.device,_that.user,_that.session);case _:
  return null;

}
}

}

/// @nodoc


class _Subject extends Subject {
  const _Subject({required this.device, required this.user, required this.session}): super._();
  

@override final  DeviceId device;
@override final  UserId? user;
@override final  SessionId session;

/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubjectCopyWith<_Subject> get copyWith => __$SubjectCopyWithImpl<_Subject>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subject&&(identical(other.device, device) || other.device == device)&&(identical(other.user, user) || other.user == user)&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,device,user,session);

@override
String toString() {
  return 'Subject(device: $device, user: $user, session: $session)';
}


}

/// @nodoc
abstract mixin class _$SubjectCopyWith<$Res> implements $SubjectCopyWith<$Res> {
  factory _$SubjectCopyWith(_Subject value, $Res Function(_Subject) _then) = __$SubjectCopyWithImpl;
@override @useResult
$Res call({
 DeviceId device, UserId? user, SessionId session
});




}
/// @nodoc
class __$SubjectCopyWithImpl<$Res>
    implements _$SubjectCopyWith<$Res> {
  __$SubjectCopyWithImpl(this._self, this._then);

  final _Subject _self;
  final $Res Function(_Subject) _then;

/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? device = null,Object? user = freezed,Object? session = null,}) {
  return _then(_Subject(
device: null == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as DeviceId,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserId?,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SessionId,
  ));
}


}

/// @nodoc
mixin _$ProfileOperation {

 String get key;
/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileOperationCopyWith<ProfileOperation> get copyWith => _$ProfileOperationCopyWithImpl<ProfileOperation>(this as ProfileOperation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileOperation&&(identical(other.key, key) || other.key == key));
}


@override
int get hashCode => Object.hash(runtimeType,key);

@override
String toString() {
  return 'ProfileOperation(key: $key)';
}


}

/// @nodoc
abstract mixin class $ProfileOperationCopyWith<$Res>  {
  factory $ProfileOperationCopyWith(ProfileOperation value, $Res Function(ProfileOperation) _then) = _$ProfileOperationCopyWithImpl;
@useResult
$Res call({
 String key
});




}
/// @nodoc
class _$ProfileOperationCopyWithImpl<$Res>
    implements $ProfileOperationCopyWith<$Res> {
  _$ProfileOperationCopyWithImpl(this._self, this._then);

  final ProfileOperation _self;
  final $Res Function(ProfileOperation) _then;

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileOperation].
extension ProfileOperationPatterns on ProfileOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SetOperation value)?  set,TResult Function( SetOnceOperation value)?  setOnce,TResult Function( UnsetOperation value)?  unset,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SetOperation() when set != null:
return set(_that);case SetOnceOperation() when setOnce != null:
return setOnce(_that);case UnsetOperation() when unset != null:
return unset(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SetOperation value)  set,required TResult Function( SetOnceOperation value)  setOnce,required TResult Function( UnsetOperation value)  unset,}){
final _that = this;
switch (_that) {
case SetOperation():
return set(_that);case SetOnceOperation():
return setOnce(_that);case UnsetOperation():
return unset(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SetOperation value)?  set,TResult? Function( SetOnceOperation value)?  setOnce,TResult? Function( UnsetOperation value)?  unset,}){
final _that = this;
switch (_that) {
case SetOperation() when set != null:
return set(_that);case SetOnceOperation() when setOnce != null:
return setOnce(_that);case UnsetOperation() when unset != null:
return unset(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String key,  Value value)?  set,TResult Function( String key,  Value value)?  setOnce,TResult Function( String key)?  unset,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SetOperation() when set != null:
return set(_that.key,_that.value);case SetOnceOperation() when setOnce != null:
return setOnce(_that.key,_that.value);case UnsetOperation() when unset != null:
return unset(_that.key);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String key,  Value value)  set,required TResult Function( String key,  Value value)  setOnce,required TResult Function( String key)  unset,}) {final _that = this;
switch (_that) {
case SetOperation():
return set(_that.key,_that.value);case SetOnceOperation():
return setOnce(_that.key,_that.value);case UnsetOperation():
return unset(_that.key);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String key,  Value value)?  set,TResult? Function( String key,  Value value)?  setOnce,TResult? Function( String key)?  unset,}) {final _that = this;
switch (_that) {
case SetOperation() when set != null:
return set(_that.key,_that.value);case SetOnceOperation() when setOnce != null:
return setOnce(_that.key,_that.value);case UnsetOperation() when unset != null:
return unset(_that.key);case _:
  return null;

}
}

}

/// @nodoc


class SetOperation extends ProfileOperation {
  const SetOperation(this.key, this.value): super._();
  

@override final  String key;
 final  Value value;

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetOperationCopyWith<SetOperation> get copyWith => _$SetOperationCopyWithImpl<SetOperation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetOperation&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'ProfileOperation.set(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $SetOperationCopyWith<$Res> implements $ProfileOperationCopyWith<$Res> {
  factory $SetOperationCopyWith(SetOperation value, $Res Function(SetOperation) _then) = _$SetOperationCopyWithImpl;
@override @useResult
$Res call({
 String key, Value value
});


$ValueCopyWith<$Res> get value;

}
/// @nodoc
class _$SetOperationCopyWithImpl<$Res>
    implements $SetOperationCopyWith<$Res> {
  _$SetOperationCopyWithImpl(this._self, this._then);

  final SetOperation _self;
  final $Res Function(SetOperation) _then;

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,}) {
  return _then(SetOperation(
null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as Value,
  ));
}

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ValueCopyWith<$Res> get value {
  
  return $ValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class SetOnceOperation extends ProfileOperation {
  const SetOnceOperation(this.key, this.value): super._();
  

@override final  String key;
 final  Value value;

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetOnceOperationCopyWith<SetOnceOperation> get copyWith => _$SetOnceOperationCopyWithImpl<SetOnceOperation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetOnceOperation&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,key,value);

@override
String toString() {
  return 'ProfileOperation.setOnce(key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class $SetOnceOperationCopyWith<$Res> implements $ProfileOperationCopyWith<$Res> {
  factory $SetOnceOperationCopyWith(SetOnceOperation value, $Res Function(SetOnceOperation) _then) = _$SetOnceOperationCopyWithImpl;
@override @useResult
$Res call({
 String key, Value value
});


$ValueCopyWith<$Res> get value;

}
/// @nodoc
class _$SetOnceOperationCopyWithImpl<$Res>
    implements $SetOnceOperationCopyWith<$Res> {
  _$SetOnceOperationCopyWithImpl(this._self, this._then);

  final SetOnceOperation _self;
  final $Res Function(SetOnceOperation) _then;

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? value = null,}) {
  return _then(SetOnceOperation(
null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as Value,
  ));
}

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ValueCopyWith<$Res> get value {
  
  return $ValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

/// @nodoc


class UnsetOperation extends ProfileOperation {
  const UnsetOperation(this.key): super._();
  

@override final  String key;

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnsetOperationCopyWith<UnsetOperation> get copyWith => _$UnsetOperationCopyWithImpl<UnsetOperation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnsetOperation&&(identical(other.key, key) || other.key == key));
}


@override
int get hashCode => Object.hash(runtimeType,key);

@override
String toString() {
  return 'ProfileOperation.unset(key: $key)';
}


}

/// @nodoc
abstract mixin class $UnsetOperationCopyWith<$Res> implements $ProfileOperationCopyWith<$Res> {
  factory $UnsetOperationCopyWith(UnsetOperation value, $Res Function(UnsetOperation) _then) = _$UnsetOperationCopyWithImpl;
@override @useResult
$Res call({
 String key
});




}
/// @nodoc
class _$UnsetOperationCopyWithImpl<$Res>
    implements $UnsetOperationCopyWith<$Res> {
  _$UnsetOperationCopyWithImpl(this._self, this._then);

  final UnsetOperation _self;
  final $Res Function(UnsetOperation) _then;

/// Create a copy of ProfileOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,}) {
  return _then(UnsetOperation(
null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Outgoing {

 String get id; DateTime get time;
/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingCopyWith<Outgoing> get copyWith => _$OutgoingCopyWithImpl<Outgoing>(this as Outgoing, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Outgoing&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time));
}


@override
int get hashCode => Object.hash(runtimeType,id,time);

@override
String toString() {
  return 'Outgoing(id: $id, time: $time)';
}


}

/// @nodoc
abstract mixin class $OutgoingCopyWith<$Res>  {
  factory $OutgoingCopyWith(Outgoing value, $Res Function(Outgoing) _then) = _$OutgoingCopyWithImpl;
@useResult
$Res call({
 String id, DateTime time
});




}
/// @nodoc
class _$OutgoingCopyWithImpl<$Res>
    implements $OutgoingCopyWith<$Res> {
  _$OutgoingCopyWithImpl(this._self, this._then);

  final Outgoing _self;
  final $Res Function(Outgoing) _then;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? time = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Outgoing].
extension OutgoingPatterns on Outgoing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EventItem value)?  event,TResult Function( IdentifyItem value)?  identify,TResult Function( ProfileItem value)?  profile,TResult Function( CrashItem value)?  crash,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EventItem() when event != null:
return event(_that);case IdentifyItem() when identify != null:
return identify(_that);case ProfileItem() when profile != null:
return profile(_that);case CrashItem() when crash != null:
return crash(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EventItem value)  event,required TResult Function( IdentifyItem value)  identify,required TResult Function( ProfileItem value)  profile,required TResult Function( CrashItem value)  crash,}){
final _that = this;
switch (_that) {
case EventItem():
return event(_that);case IdentifyItem():
return identify(_that);case ProfileItem():
return profile(_that);case CrashItem():
return crash(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EventItem value)?  event,TResult? Function( IdentifyItem value)?  identify,TResult? Function( ProfileItem value)?  profile,TResult? Function( CrashItem value)?  crash,}){
final _that = this;
switch (_that) {
case EventItem() when event != null:
return event(_that);case IdentifyItem() when identify != null:
return identify(_that);case ProfileItem() when profile != null:
return profile(_that);case CrashItem() when crash != null:
return crash(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  DateTime time,  Subject subject,  AppContext context,  String name,  IMap<String, Value> properties)?  event,TResult Function( String id,  DateTime time,  DeviceId deviceId,  UserId userId)?  identify,TResult Function( String id,  DateTime time,  DeviceId deviceId,  UserId userId,  IList<ProfileOperation> operations)?  profile,TResult Function( String id,  DateTime time,  Subject subject,  AppContext context,  String exceptionType,  String message,  IList<Frame> frames,  String rawStackTrace,  bool fatal,  String thread,  IMap<String, Value> customKeys,  IList<LogLine> logs)?  crash,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EventItem() when event != null:
return event(_that.id,_that.time,_that.subject,_that.context,_that.name,_that.properties);case IdentifyItem() when identify != null:
return identify(_that.id,_that.time,_that.deviceId,_that.userId);case ProfileItem() when profile != null:
return profile(_that.id,_that.time,_that.deviceId,_that.userId,_that.operations);case CrashItem() when crash != null:
return crash(_that.id,_that.time,_that.subject,_that.context,_that.exceptionType,_that.message,_that.frames,_that.rawStackTrace,_that.fatal,_that.thread,_that.customKeys,_that.logs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  DateTime time,  Subject subject,  AppContext context,  String name,  IMap<String, Value> properties)  event,required TResult Function( String id,  DateTime time,  DeviceId deviceId,  UserId userId)  identify,required TResult Function( String id,  DateTime time,  DeviceId deviceId,  UserId userId,  IList<ProfileOperation> operations)  profile,required TResult Function( String id,  DateTime time,  Subject subject,  AppContext context,  String exceptionType,  String message,  IList<Frame> frames,  String rawStackTrace,  bool fatal,  String thread,  IMap<String, Value> customKeys,  IList<LogLine> logs)  crash,}) {final _that = this;
switch (_that) {
case EventItem():
return event(_that.id,_that.time,_that.subject,_that.context,_that.name,_that.properties);case IdentifyItem():
return identify(_that.id,_that.time,_that.deviceId,_that.userId);case ProfileItem():
return profile(_that.id,_that.time,_that.deviceId,_that.userId,_that.operations);case CrashItem():
return crash(_that.id,_that.time,_that.subject,_that.context,_that.exceptionType,_that.message,_that.frames,_that.rawStackTrace,_that.fatal,_that.thread,_that.customKeys,_that.logs);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  DateTime time,  Subject subject,  AppContext context,  String name,  IMap<String, Value> properties)?  event,TResult? Function( String id,  DateTime time,  DeviceId deviceId,  UserId userId)?  identify,TResult? Function( String id,  DateTime time,  DeviceId deviceId,  UserId userId,  IList<ProfileOperation> operations)?  profile,TResult? Function( String id,  DateTime time,  Subject subject,  AppContext context,  String exceptionType,  String message,  IList<Frame> frames,  String rawStackTrace,  bool fatal,  String thread,  IMap<String, Value> customKeys,  IList<LogLine> logs)?  crash,}) {final _that = this;
switch (_that) {
case EventItem() when event != null:
return event(_that.id,_that.time,_that.subject,_that.context,_that.name,_that.properties);case IdentifyItem() when identify != null:
return identify(_that.id,_that.time,_that.deviceId,_that.userId);case ProfileItem() when profile != null:
return profile(_that.id,_that.time,_that.deviceId,_that.userId,_that.operations);case CrashItem() when crash != null:
return crash(_that.id,_that.time,_that.subject,_that.context,_that.exceptionType,_that.message,_that.frames,_that.rawStackTrace,_that.fatal,_that.thread,_that.customKeys,_that.logs);case _:
  return null;

}
}

}

/// @nodoc


class EventItem extends Outgoing {
  const EventItem({required this.id, required this.time, required this.subject, required this.context, required this.name, required this.properties}): super._();
  

@override final  String id;
@override final  DateTime time;
 final  Subject subject;
 final  AppContext context;
 final  String name;
 final  IMap<String, Value> properties;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventItemCopyWith<EventItem> get copyWith => _$EventItemCopyWithImpl<EventItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventItem&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.context, context) || other.context == context)&&(identical(other.name, name) || other.name == name)&&(identical(other.properties, properties) || other.properties == properties));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,subject,context,name,properties);

@override
String toString() {
  return 'Outgoing.event(id: $id, time: $time, subject: $subject, context: $context, name: $name, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $EventItemCopyWith<$Res> implements $OutgoingCopyWith<$Res> {
  factory $EventItemCopyWith(EventItem value, $Res Function(EventItem) _then) = _$EventItemCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime time, Subject subject, AppContext context, String name, IMap<String, Value> properties
});


$SubjectCopyWith<$Res> get subject;$AppContextCopyWith<$Res> get context;

}
/// @nodoc
class _$EventItemCopyWithImpl<$Res>
    implements $EventItemCopyWith<$Res> {
  _$EventItemCopyWithImpl(this._self, this._then);

  final EventItem _self;
  final $Res Function(EventItem) _then;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? time = null,Object? subject = null,Object? context = null,Object? name = null,Object? properties = null,}) {
  return _then(EventItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as AppContext,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as IMap<String, Value>,
  ));
}

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubjectCopyWith<$Res> get subject {
  
  return $SubjectCopyWith<$Res>(_self.subject, (value) {
    return _then(_self.copyWith(subject: value));
  });
}/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppContextCopyWith<$Res> get context {
  
  return $AppContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

/// @nodoc


class IdentifyItem extends Outgoing {
  const IdentifyItem({required this.id, required this.time, required this.deviceId, required this.userId}): super._();
  

@override final  String id;
@override final  DateTime time;
 final  DeviceId deviceId;
 final  UserId userId;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IdentifyItemCopyWith<IdentifyItem> get copyWith => _$IdentifyItemCopyWithImpl<IdentifyItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IdentifyItem&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.userId, userId) || other.userId == userId));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,deviceId,userId);

@override
String toString() {
  return 'Outgoing.identify(id: $id, time: $time, deviceId: $deviceId, userId: $userId)';
}


}

/// @nodoc
abstract mixin class $IdentifyItemCopyWith<$Res> implements $OutgoingCopyWith<$Res> {
  factory $IdentifyItemCopyWith(IdentifyItem value, $Res Function(IdentifyItem) _then) = _$IdentifyItemCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime time, DeviceId deviceId, UserId userId
});




}
/// @nodoc
class _$IdentifyItemCopyWithImpl<$Res>
    implements $IdentifyItemCopyWith<$Res> {
  _$IdentifyItemCopyWithImpl(this._self, this._then);

  final IdentifyItem _self;
  final $Res Function(IdentifyItem) _then;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? time = null,Object? deviceId = null,Object? userId = null,}) {
  return _then(IdentifyItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeviceId,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as UserId,
  ));
}


}

/// @nodoc


class ProfileItem extends Outgoing {
  const ProfileItem({required this.id, required this.time, required this.deviceId, required this.userId, required this.operations}): super._();
  

@override final  String id;
@override final  DateTime time;
 final  DeviceId deviceId;
 final  UserId userId;
 final  IList<ProfileOperation> operations;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileItemCopyWith<ProfileItem> get copyWith => _$ProfileItemCopyWithImpl<ProfileItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileItem&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.operations, operations));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,deviceId,userId,const DeepCollectionEquality().hash(operations));

@override
String toString() {
  return 'Outgoing.profile(id: $id, time: $time, deviceId: $deviceId, userId: $userId, operations: $operations)';
}


}

/// @nodoc
abstract mixin class $ProfileItemCopyWith<$Res> implements $OutgoingCopyWith<$Res> {
  factory $ProfileItemCopyWith(ProfileItem value, $Res Function(ProfileItem) _then) = _$ProfileItemCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime time, DeviceId deviceId, UserId userId, IList<ProfileOperation> operations
});




}
/// @nodoc
class _$ProfileItemCopyWithImpl<$Res>
    implements $ProfileItemCopyWith<$Res> {
  _$ProfileItemCopyWithImpl(this._self, this._then);

  final ProfileItem _self;
  final $Res Function(ProfileItem) _then;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? time = null,Object? deviceId = null,Object? userId = null,Object? operations = null,}) {
  return _then(ProfileItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeviceId,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as UserId,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as IList<ProfileOperation>,
  ));
}


}

/// @nodoc


class CrashItem extends Outgoing {
  const CrashItem({required this.id, required this.time, required this.subject, required this.context, required this.exceptionType, required this.message, required this.frames, required this.rawStackTrace, required this.fatal, required this.thread, required this.customKeys, required this.logs}): super._();
  

@override final  String id;
@override final  DateTime time;
 final  Subject subject;
 final  AppContext context;
 final  String exceptionType;
 final  String message;
 final  IList<Frame> frames;
 final  String rawStackTrace;
 final  bool fatal;
 final  String thread;
 final  IMap<String, Value> customKeys;
 final  IList<LogLine> logs;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrashItemCopyWith<CrashItem> get copyWith => _$CrashItemCopyWithImpl<CrashItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrashItem&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.context, context) || other.context == context)&&(identical(other.exceptionType, exceptionType) || other.exceptionType == exceptionType)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.rawStackTrace, rawStackTrace) || other.rawStackTrace == rawStackTrace)&&(identical(other.fatal, fatal) || other.fatal == fatal)&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.customKeys, customKeys) || other.customKeys == customKeys)&&const DeepCollectionEquality().equals(other.logs, logs));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,subject,context,exceptionType,message,const DeepCollectionEquality().hash(frames),rawStackTrace,fatal,thread,customKeys,const DeepCollectionEquality().hash(logs));

@override
String toString() {
  return 'Outgoing.crash(id: $id, time: $time, subject: $subject, context: $context, exceptionType: $exceptionType, message: $message, frames: $frames, rawStackTrace: $rawStackTrace, fatal: $fatal, thread: $thread, customKeys: $customKeys, logs: $logs)';
}


}

/// @nodoc
abstract mixin class $CrashItemCopyWith<$Res> implements $OutgoingCopyWith<$Res> {
  factory $CrashItemCopyWith(CrashItem value, $Res Function(CrashItem) _then) = _$CrashItemCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime time, Subject subject, AppContext context, String exceptionType, String message, IList<Frame> frames, String rawStackTrace, bool fatal, String thread, IMap<String, Value> customKeys, IList<LogLine> logs
});


$SubjectCopyWith<$Res> get subject;$AppContextCopyWith<$Res> get context;

}
/// @nodoc
class _$CrashItemCopyWithImpl<$Res>
    implements $CrashItemCopyWith<$Res> {
  _$CrashItemCopyWithImpl(this._self, this._then);

  final CrashItem _self;
  final $Res Function(CrashItem) _then;

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? time = null,Object? subject = null,Object? context = null,Object? exceptionType = null,Object? message = null,Object? frames = null,Object? rawStackTrace = null,Object? fatal = null,Object? thread = null,Object? customKeys = null,Object? logs = null,}) {
  return _then(CrashItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as Subject,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as AppContext,exceptionType: null == exceptionType ? _self.exceptionType : exceptionType // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as IList<Frame>,rawStackTrace: null == rawStackTrace ? _self.rawStackTrace : rawStackTrace // ignore: cast_nullable_to_non_nullable
as String,fatal: null == fatal ? _self.fatal : fatal // ignore: cast_nullable_to_non_nullable
as bool,thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as String,customKeys: null == customKeys ? _self.customKeys : customKeys // ignore: cast_nullable_to_non_nullable
as IMap<String, Value>,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as IList<LogLine>,
  ));
}

/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubjectCopyWith<$Res> get subject {
  
  return $SubjectCopyWith<$Res>(_self.subject, (value) {
    return _then(_self.copyWith(subject: value));
  });
}/// Create a copy of Outgoing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppContextCopyWith<$Res> get context {
  
  return $AppContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
