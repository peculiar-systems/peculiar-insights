// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buffer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingBuffer {

 int get limit; IMap<Purpose, IList<Outgoing>> get held;
/// Create a copy of PendingBuffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingBufferCopyWith<PendingBuffer> get copyWith => _$PendingBufferCopyWithImpl<PendingBuffer>(this as PendingBuffer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingBuffer&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.held, held) || other.held == held));
}


@override
int get hashCode => Object.hash(runtimeType,limit,held);

@override
String toString() {
  return 'PendingBuffer(limit: $limit, held: $held)';
}


}

/// @nodoc
abstract mixin class $PendingBufferCopyWith<$Res>  {
  factory $PendingBufferCopyWith(PendingBuffer value, $Res Function(PendingBuffer) _then) = _$PendingBufferCopyWithImpl;
@useResult
$Res call({
 int limit, IMap<Purpose, IList<Outgoing>> held
});




}
/// @nodoc
class _$PendingBufferCopyWithImpl<$Res>
    implements $PendingBufferCopyWith<$Res> {
  _$PendingBufferCopyWithImpl(this._self, this._then);

  final PendingBuffer _self;
  final $Res Function(PendingBuffer) _then;

/// Create a copy of PendingBuffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = null,Object? held = null,}) {
  return _then(_self.copyWith(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as IMap<Purpose, IList<Outgoing>>,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingBuffer].
extension PendingBufferPatterns on PendingBuffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingBuffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingBuffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingBuffer value)  $default,){
final _that = this;
switch (_that) {
case _PendingBuffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingBuffer value)?  $default,){
final _that = this;
switch (_that) {
case _PendingBuffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int limit,  IMap<Purpose, IList<Outgoing>> held)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingBuffer() when $default != null:
return $default(_that.limit,_that.held);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int limit,  IMap<Purpose, IList<Outgoing>> held)  $default,) {final _that = this;
switch (_that) {
case _PendingBuffer():
return $default(_that.limit,_that.held);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int limit,  IMap<Purpose, IList<Outgoing>> held)?  $default,) {final _that = this;
switch (_that) {
case _PendingBuffer() when $default != null:
return $default(_that.limit,_that.held);case _:
  return null;

}
}

}

/// @nodoc


class _PendingBuffer extends PendingBuffer {
  const _PendingBuffer({required this.limit, this.held = const IMapConst({})}): super._();
  

@override final  int limit;
@override@JsonKey() final  IMap<Purpose, IList<Outgoing>> held;

/// Create a copy of PendingBuffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingBufferCopyWith<_PendingBuffer> get copyWith => __$PendingBufferCopyWithImpl<_PendingBuffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingBuffer&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.held, held) || other.held == held));
}


@override
int get hashCode => Object.hash(runtimeType,limit,held);

@override
String toString() {
  return 'PendingBuffer(limit: $limit, held: $held)';
}


}

/// @nodoc
abstract mixin class _$PendingBufferCopyWith<$Res> implements $PendingBufferCopyWith<$Res> {
  factory _$PendingBufferCopyWith(_PendingBuffer value, $Res Function(_PendingBuffer) _then) = __$PendingBufferCopyWithImpl;
@override @useResult
$Res call({
 int limit, IMap<Purpose, IList<Outgoing>> held
});




}
/// @nodoc
class __$PendingBufferCopyWithImpl<$Res>
    implements _$PendingBufferCopyWith<$Res> {
  __$PendingBufferCopyWithImpl(this._self, this._then);

  final _PendingBuffer _self;
  final $Res Function(_PendingBuffer) _then;

/// Create a copy of PendingBuffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? limit = null,Object? held = null,}) {
  return _then(_PendingBuffer(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,held: null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as IMap<Purpose, IList<Outgoing>>,
  ));
}


}

// dart format on
