// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueueRow {

 String get id; QueueKind get kind; Purpose get purpose; Uint8List get payload; int get createdAt; Uint8List? get consent;
/// Create a copy of QueueRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueRowCopyWith<QueueRow> get copyWith => _$QueueRowCopyWithImpl<QueueRow>(this as QueueRow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueRow&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.consent, consent));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,purpose,const DeepCollectionEquality().hash(payload),createdAt,const DeepCollectionEquality().hash(consent));

@override
String toString() {
  return 'QueueRow(id: $id, kind: $kind, purpose: $purpose, payload: $payload, createdAt: $createdAt, consent: $consent)';
}


}

/// @nodoc
abstract mixin class $QueueRowCopyWith<$Res>  {
  factory $QueueRowCopyWith(QueueRow value, $Res Function(QueueRow) _then) = _$QueueRowCopyWithImpl;
@useResult
$Res call({
 String id, QueueKind kind, Purpose purpose, Uint8List payload, int createdAt, Uint8List? consent
});




}
/// @nodoc
class _$QueueRowCopyWithImpl<$Res>
    implements $QueueRowCopyWith<$Res> {
  _$QueueRowCopyWithImpl(this._self, this._then);

  final QueueRow _self;
  final $Res Function(QueueRow) _then;

/// Create a copy of QueueRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? purpose = null,Object? payload = null,Object? createdAt = null,Object? consent = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QueueKind,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as Purpose,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Uint8List,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,consent: freezed == consent ? _self.consent : consent // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueRow].
extension QueueRowPatterns on QueueRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueRow value)  $default,){
final _that = this;
switch (_that) {
case _QueueRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueRow value)?  $default,){
final _that = this;
switch (_that) {
case _QueueRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  QueueKind kind,  Purpose purpose,  Uint8List payload,  int createdAt,  Uint8List? consent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueRow() when $default != null:
return $default(_that.id,_that.kind,_that.purpose,_that.payload,_that.createdAt,_that.consent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  QueueKind kind,  Purpose purpose,  Uint8List payload,  int createdAt,  Uint8List? consent)  $default,) {final _that = this;
switch (_that) {
case _QueueRow():
return $default(_that.id,_that.kind,_that.purpose,_that.payload,_that.createdAt,_that.consent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  QueueKind kind,  Purpose purpose,  Uint8List payload,  int createdAt,  Uint8List? consent)?  $default,) {final _that = this;
switch (_that) {
case _QueueRow() when $default != null:
return $default(_that.id,_that.kind,_that.purpose,_that.payload,_that.createdAt,_that.consent);case _:
  return null;

}
}

}

/// @nodoc


class _QueueRow implements QueueRow {
  const _QueueRow({required this.id, required this.kind, required this.purpose, required this.payload, required this.createdAt, this.consent});
  

@override final  String id;
@override final  QueueKind kind;
@override final  Purpose purpose;
@override final  Uint8List payload;
@override final  int createdAt;
@override final  Uint8List? consent;

/// Create a copy of QueueRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueRowCopyWith<_QueueRow> get copyWith => __$QueueRowCopyWithImpl<_QueueRow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueRow&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.consent, consent));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,purpose,const DeepCollectionEquality().hash(payload),createdAt,const DeepCollectionEquality().hash(consent));

@override
String toString() {
  return 'QueueRow(id: $id, kind: $kind, purpose: $purpose, payload: $payload, createdAt: $createdAt, consent: $consent)';
}


}

/// @nodoc
abstract mixin class _$QueueRowCopyWith<$Res> implements $QueueRowCopyWith<$Res> {
  factory _$QueueRowCopyWith(_QueueRow value, $Res Function(_QueueRow) _then) = __$QueueRowCopyWithImpl;
@override @useResult
$Res call({
 String id, QueueKind kind, Purpose purpose, Uint8List payload, int createdAt, Uint8List? consent
});




}
/// @nodoc
class __$QueueRowCopyWithImpl<$Res>
    implements _$QueueRowCopyWith<$Res> {
  __$QueueRowCopyWithImpl(this._self, this._then);

  final _QueueRow _self;
  final $Res Function(_QueueRow) _then;

/// Create a copy of QueueRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? purpose = null,Object? payload = null,Object? createdAt = null,Object? consent = freezed,}) {
  return _then(_QueueRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QueueKind,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as Purpose,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Uint8List,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,consent: freezed == consent ? _self.consent : consent // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

// dart format on
