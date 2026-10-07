// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceChange {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceChange);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeviceChange()';
}


}

/// @nodoc
class $DeviceChangeCopyWith<$Res>  {
$DeviceChangeCopyWith(DeviceChange _, $Res Function(DeviceChange) __);
}


/// Adds pattern-matching-related methods to [DeviceChange].
extension DeviceChangePatterns on DeviceChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConsentedChange value)?  consented,TResult Function( ErasedChange value)?  erased,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConsentedChange() when consented != null:
return consented(_that);case ErasedChange() when erased != null:
return erased(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConsentedChange value)  consented,required TResult Function( ErasedChange value)  erased,}){
final _that = this;
switch (_that) {
case ConsentedChange():
return consented(_that);case ErasedChange():
return erased(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConsentedChange value)?  consented,TResult? Function( ErasedChange value)?  erased,}){
final _that = this;
switch (_that) {
case ConsentedChange() when consented != null:
return consented(_that);case ErasedChange() when erased != null:
return erased(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Consent consent)?  consented,TResult Function()?  erased,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConsentedChange() when consented != null:
return consented(_that.consent);case ErasedChange() when erased != null:
return erased();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Consent consent)  consented,required TResult Function()  erased,}) {final _that = this;
switch (_that) {
case ConsentedChange():
return consented(_that.consent);case ErasedChange():
return erased();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Consent consent)?  consented,TResult? Function()?  erased,}) {final _that = this;
switch (_that) {
case ConsentedChange() when consented != null:
return consented(_that.consent);case ErasedChange() when erased != null:
return erased();case _:
  return null;

}
}

}

/// @nodoc


class ConsentedChange implements DeviceChange {
  const ConsentedChange(this.consent);
  

 final  Consent consent;

/// Create a copy of DeviceChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentedChangeCopyWith<ConsentedChange> get copyWith => _$ConsentedChangeCopyWithImpl<ConsentedChange>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentedChange&&(identical(other.consent, consent) || other.consent == consent));
}


@override
int get hashCode => Object.hash(runtimeType,consent);

@override
String toString() {
  return 'DeviceChange.consented(consent: $consent)';
}


}

/// @nodoc
abstract mixin class $ConsentedChangeCopyWith<$Res> implements $DeviceChangeCopyWith<$Res> {
  factory $ConsentedChangeCopyWith(ConsentedChange value, $Res Function(ConsentedChange) _then) = _$ConsentedChangeCopyWithImpl;
@useResult
$Res call({
 Consent consent
});


$ConsentCopyWith<$Res> get consent;

}
/// @nodoc
class _$ConsentedChangeCopyWithImpl<$Res>
    implements $ConsentedChangeCopyWith<$Res> {
  _$ConsentedChangeCopyWithImpl(this._self, this._then);

  final ConsentedChange _self;
  final $Res Function(ConsentedChange) _then;

/// Create a copy of DeviceChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? consent = null,}) {
  return _then(ConsentedChange(
null == consent ? _self.consent : consent // ignore: cast_nullable_to_non_nullable
as Consent,
  ));
}

/// Create a copy of DeviceChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsentCopyWith<$Res> get consent {
  
  return $ConsentCopyWith<$Res>(_self.consent, (value) {
    return _then(_self.copyWith(consent: value));
  });
}
}

/// @nodoc


class ErasedChange implements DeviceChange {
  const ErasedChange();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErasedChange);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeviceChange.erased()';
}


}




// dart format on
