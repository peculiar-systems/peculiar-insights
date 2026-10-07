// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Value {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Value);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Value()';
}


}

/// @nodoc
class $ValueCopyWith<$Res>  {
$ValueCopyWith(Value _, $Res Function(Value) __);
}


/// Adds pattern-matching-related methods to [Value].
extension ValuePatterns on Value {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextValue value)?  text,TResult Function( IntegerValue value)?  integer,TResult Function( DecimalValue value)?  decimal,TResult Function( FlagValue value)?  flag,TResult Function( TimeValue value)?  time,TResult Function( ListValue value)?  list,TResult Function( MapValue value)?  map,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextValue() when text != null:
return text(_that);case IntegerValue() when integer != null:
return integer(_that);case DecimalValue() when decimal != null:
return decimal(_that);case FlagValue() when flag != null:
return flag(_that);case TimeValue() when time != null:
return time(_that);case ListValue() when list != null:
return list(_that);case MapValue() when map != null:
return map(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextValue value)  text,required TResult Function( IntegerValue value)  integer,required TResult Function( DecimalValue value)  decimal,required TResult Function( FlagValue value)  flag,required TResult Function( TimeValue value)  time,required TResult Function( ListValue value)  list,required TResult Function( MapValue value)  map,}){
final _that = this;
switch (_that) {
case TextValue():
return text(_that);case IntegerValue():
return integer(_that);case DecimalValue():
return decimal(_that);case FlagValue():
return flag(_that);case TimeValue():
return time(_that);case ListValue():
return list(_that);case MapValue():
return map(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextValue value)?  text,TResult? Function( IntegerValue value)?  integer,TResult? Function( DecimalValue value)?  decimal,TResult? Function( FlagValue value)?  flag,TResult? Function( TimeValue value)?  time,TResult? Function( ListValue value)?  list,TResult? Function( MapValue value)?  map,}){
final _that = this;
switch (_that) {
case TextValue() when text != null:
return text(_that);case IntegerValue() when integer != null:
return integer(_that);case DecimalValue() when decimal != null:
return decimal(_that);case FlagValue() when flag != null:
return flag(_that);case TimeValue() when time != null:
return time(_that);case ListValue() when list != null:
return list(_that);case MapValue() when map != null:
return map(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String value)?  text,TResult Function( int value)?  integer,TResult Function( double value)?  decimal,TResult Function( bool value)?  flag,TResult Function( DateTime value)?  time,TResult Function( IList<Value> values)?  list,TResult Function( IMap<String, Value> entries)?  map,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextValue() when text != null:
return text(_that.value);case IntegerValue() when integer != null:
return integer(_that.value);case DecimalValue() when decimal != null:
return decimal(_that.value);case FlagValue() when flag != null:
return flag(_that.value);case TimeValue() when time != null:
return time(_that.value);case ListValue() when list != null:
return list(_that.values);case MapValue() when map != null:
return map(_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String value)  text,required TResult Function( int value)  integer,required TResult Function( double value)  decimal,required TResult Function( bool value)  flag,required TResult Function( DateTime value)  time,required TResult Function( IList<Value> values)  list,required TResult Function( IMap<String, Value> entries)  map,}) {final _that = this;
switch (_that) {
case TextValue():
return text(_that.value);case IntegerValue():
return integer(_that.value);case DecimalValue():
return decimal(_that.value);case FlagValue():
return flag(_that.value);case TimeValue():
return time(_that.value);case ListValue():
return list(_that.values);case MapValue():
return map(_that.entries);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String value)?  text,TResult? Function( int value)?  integer,TResult? Function( double value)?  decimal,TResult? Function( bool value)?  flag,TResult? Function( DateTime value)?  time,TResult? Function( IList<Value> values)?  list,TResult? Function( IMap<String, Value> entries)?  map,}) {final _that = this;
switch (_that) {
case TextValue() when text != null:
return text(_that.value);case IntegerValue() when integer != null:
return integer(_that.value);case DecimalValue() when decimal != null:
return decimal(_that.value);case FlagValue() when flag != null:
return flag(_that.value);case TimeValue() when time != null:
return time(_that.value);case ListValue() when list != null:
return list(_that.values);case MapValue() when map != null:
return map(_that.entries);case _:
  return null;

}
}

}

/// @nodoc


class TextValue extends Value {
  const TextValue(this.value): super._();
  

 final  String value;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextValueCopyWith<TextValue> get copyWith => _$TextValueCopyWithImpl<TextValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'Value.text(value: $value)';
}


}

/// @nodoc
abstract mixin class $TextValueCopyWith<$Res> implements $ValueCopyWith<$Res> {
  factory $TextValueCopyWith(TextValue value, $Res Function(TextValue) _then) = _$TextValueCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$TextValueCopyWithImpl<$Res>
    implements $TextValueCopyWith<$Res> {
  _$TextValueCopyWithImpl(this._self, this._then);

  final TextValue _self;
  final $Res Function(TextValue) _then;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(TextValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class IntegerValue extends Value {
  const IntegerValue(this.value): super._();
  

 final  int value;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntegerValueCopyWith<IntegerValue> get copyWith => _$IntegerValueCopyWithImpl<IntegerValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntegerValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'Value.integer(value: $value)';
}


}

/// @nodoc
abstract mixin class $IntegerValueCopyWith<$Res> implements $ValueCopyWith<$Res> {
  factory $IntegerValueCopyWith(IntegerValue value, $Res Function(IntegerValue) _then) = _$IntegerValueCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$IntegerValueCopyWithImpl<$Res>
    implements $IntegerValueCopyWith<$Res> {
  _$IntegerValueCopyWithImpl(this._self, this._then);

  final IntegerValue _self;
  final $Res Function(IntegerValue) _then;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(IntegerValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class DecimalValue extends Value {
  const DecimalValue(this.value): super._();
  

 final  double value;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecimalValueCopyWith<DecimalValue> get copyWith => _$DecimalValueCopyWithImpl<DecimalValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecimalValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'Value.decimal(value: $value)';
}


}

/// @nodoc
abstract mixin class $DecimalValueCopyWith<$Res> implements $ValueCopyWith<$Res> {
  factory $DecimalValueCopyWith(DecimalValue value, $Res Function(DecimalValue) _then) = _$DecimalValueCopyWithImpl;
@useResult
$Res call({
 double value
});




}
/// @nodoc
class _$DecimalValueCopyWithImpl<$Res>
    implements $DecimalValueCopyWith<$Res> {
  _$DecimalValueCopyWithImpl(this._self, this._then);

  final DecimalValue _self;
  final $Res Function(DecimalValue) _then;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(DecimalValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class FlagValue extends Value {
  const FlagValue({required this.value}): super._();
  

 final  bool value;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlagValueCopyWith<FlagValue> get copyWith => _$FlagValueCopyWithImpl<FlagValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlagValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'Value.flag(value: $value)';
}


}

/// @nodoc
abstract mixin class $FlagValueCopyWith<$Res> implements $ValueCopyWith<$Res> {
  factory $FlagValueCopyWith(FlagValue value, $Res Function(FlagValue) _then) = _$FlagValueCopyWithImpl;
@useResult
$Res call({
 bool value
});




}
/// @nodoc
class _$FlagValueCopyWithImpl<$Res>
    implements $FlagValueCopyWith<$Res> {
  _$FlagValueCopyWithImpl(this._self, this._then);

  final FlagValue _self;
  final $Res Function(FlagValue) _then;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(FlagValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class TimeValue extends Value {
  const TimeValue(this.value): super._();
  

 final  DateTime value;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeValueCopyWith<TimeValue> get copyWith => _$TimeValueCopyWithImpl<TimeValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeValue&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'Value.time(value: $value)';
}


}

/// @nodoc
abstract mixin class $TimeValueCopyWith<$Res> implements $ValueCopyWith<$Res> {
  factory $TimeValueCopyWith(TimeValue value, $Res Function(TimeValue) _then) = _$TimeValueCopyWithImpl;
@useResult
$Res call({
 DateTime value
});




}
/// @nodoc
class _$TimeValueCopyWithImpl<$Res>
    implements $TimeValueCopyWith<$Res> {
  _$TimeValueCopyWithImpl(this._self, this._then);

  final TimeValue _self;
  final $Res Function(TimeValue) _then;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(TimeValue(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class ListValue extends Value {
  const ListValue(this.values): super._();
  

 final  IList<Value> values;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListValueCopyWith<ListValue> get copyWith => _$ListValueCopyWithImpl<ListValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListValue&&const DeepCollectionEquality().equals(other.values, values));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(values));

@override
String toString() {
  return 'Value.list(values: $values)';
}


}

/// @nodoc
abstract mixin class $ListValueCopyWith<$Res> implements $ValueCopyWith<$Res> {
  factory $ListValueCopyWith(ListValue value, $Res Function(ListValue) _then) = _$ListValueCopyWithImpl;
@useResult
$Res call({
 IList<Value> values
});




}
/// @nodoc
class _$ListValueCopyWithImpl<$Res>
    implements $ListValueCopyWith<$Res> {
  _$ListValueCopyWithImpl(this._self, this._then);

  final ListValue _self;
  final $Res Function(ListValue) _then;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? values = null,}) {
  return _then(ListValue(
null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as IList<Value>,
  ));
}


}

/// @nodoc


class MapValue extends Value {
  const MapValue(this.entries): super._();
  

 final  IMap<String, Value> entries;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapValueCopyWith<MapValue> get copyWith => _$MapValueCopyWithImpl<MapValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapValue&&(identical(other.entries, entries) || other.entries == entries));
}


@override
int get hashCode => Object.hash(runtimeType,entries);

@override
String toString() {
  return 'Value.map(entries: $entries)';
}


}

/// @nodoc
abstract mixin class $MapValueCopyWith<$Res> implements $ValueCopyWith<$Res> {
  factory $MapValueCopyWith(MapValue value, $Res Function(MapValue) _then) = _$MapValueCopyWithImpl;
@useResult
$Res call({
 IMap<String, Value> entries
});




}
/// @nodoc
class _$MapValueCopyWithImpl<$Res>
    implements $MapValueCopyWith<$Res> {
  _$MapValueCopyWithImpl(this._self, this._then);

  final MapValue _self;
  final $Res Function(MapValue) _then;

/// Create a copy of Value
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(MapValue(
null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as IMap<String, Value>,
  ));
}


}

// dart format on
