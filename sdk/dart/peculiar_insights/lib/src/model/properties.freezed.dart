// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'properties.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Converted {

 IMap<String, Value> get values; IList<Diagnostic> get failures;
/// Create a copy of Converted
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertedCopyWith<Converted> get copyWith => _$ConvertedCopyWithImpl<Converted>(this as Converted, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Converted&&(identical(other.values, values) || other.values == values)&&const DeepCollectionEquality().equals(other.failures, failures));
}


@override
int get hashCode => Object.hash(runtimeType,values,const DeepCollectionEquality().hash(failures));

@override
String toString() {
  return 'Converted(values: $values, failures: $failures)';
}


}

/// @nodoc
abstract mixin class $ConvertedCopyWith<$Res>  {
  factory $ConvertedCopyWith(Converted value, $Res Function(Converted) _then) = _$ConvertedCopyWithImpl;
@useResult
$Res call({
 IMap<String, Value> values, IList<Diagnostic> failures
});




}
/// @nodoc
class _$ConvertedCopyWithImpl<$Res>
    implements $ConvertedCopyWith<$Res> {
  _$ConvertedCopyWithImpl(this._self, this._then);

  final Converted _self;
  final $Res Function(Converted) _then;

/// Create a copy of Converted
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? values = null,Object? failures = null,}) {
  return _then(_self.copyWith(
values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as IMap<String, Value>,failures: null == failures ? _self.failures : failures // ignore: cast_nullable_to_non_nullable
as IList<Diagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Converted].
extension ConvertedPatterns on Converted {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Converted value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Converted() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Converted value)  $default,){
final _that = this;
switch (_that) {
case _Converted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Converted value)?  $default,){
final _that = this;
switch (_that) {
case _Converted() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IMap<String, Value> values,  IList<Diagnostic> failures)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Converted() when $default != null:
return $default(_that.values,_that.failures);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IMap<String, Value> values,  IList<Diagnostic> failures)  $default,) {final _that = this;
switch (_that) {
case _Converted():
return $default(_that.values,_that.failures);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IMap<String, Value> values,  IList<Diagnostic> failures)?  $default,) {final _that = this;
switch (_that) {
case _Converted() when $default != null:
return $default(_that.values,_that.failures);case _:
  return null;

}
}

}

/// @nodoc


class _Converted extends Converted {
  const _Converted({required this.values, required this.failures}): super._();
  

@override final  IMap<String, Value> values;
@override final  IList<Diagnostic> failures;

/// Create a copy of Converted
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConvertedCopyWith<_Converted> get copyWith => __$ConvertedCopyWithImpl<_Converted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Converted&&(identical(other.values, values) || other.values == values)&&const DeepCollectionEquality().equals(other.failures, failures));
}


@override
int get hashCode => Object.hash(runtimeType,values,const DeepCollectionEquality().hash(failures));

@override
String toString() {
  return 'Converted(values: $values, failures: $failures)';
}


}

/// @nodoc
abstract mixin class _$ConvertedCopyWith<$Res> implements $ConvertedCopyWith<$Res> {
  factory _$ConvertedCopyWith(_Converted value, $Res Function(_Converted) _then) = __$ConvertedCopyWithImpl;
@override @useResult
$Res call({
 IMap<String, Value> values, IList<Diagnostic> failures
});




}
/// @nodoc
class __$ConvertedCopyWithImpl<$Res>
    implements _$ConvertedCopyWith<$Res> {
  __$ConvertedCopyWithImpl(this._self, this._then);

  final _Converted _self;
  final $Res Function(_Converted) _then;

/// Create a copy of Converted
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? values = null,Object? failures = null,}) {
  return _then(_Converted(
values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as IMap<String, Value>,failures: null == failures ? _self.failures : failures // ignore: cast_nullable_to_non_nullable
as IList<Diagnostic>,
  ));
}


}

// dart format on
