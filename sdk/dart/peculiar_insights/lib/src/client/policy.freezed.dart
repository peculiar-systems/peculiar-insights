// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConsentPolicy {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentPolicy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConsentPolicy()';
}


}

/// @nodoc
class $ConsentPolicyCopyWith<$Res>  {
$ConsentPolicyCopyWith(ConsentPolicy _, $Res Function(ConsentPolicy) __);
}


/// Adds pattern-matching-related methods to [ConsentPolicy].
extension ConsentPolicyPatterns on ConsentPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AskPolicy value)?  ask,TResult Function( AssumedPolicy value)?  assumed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AskPolicy() when ask != null:
return ask(_that);case AssumedPolicy() when assumed != null:
return assumed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AskPolicy value)  ask,required TResult Function( AssumedPolicy value)  assumed,}){
final _that = this;
switch (_that) {
case AskPolicy():
return ask(_that);case AssumedPolicy():
return assumed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AskPolicy value)?  ask,TResult? Function( AssumedPolicy value)?  assumed,}){
final _that = this;
switch (_that) {
case AskPolicy() when ask != null:
return ask(_that);case AssumedPolicy() when assumed != null:
return assumed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ask,TResult Function( String? analytics,  String? diagnostics)?  assumed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AskPolicy() when ask != null:
return ask();case AssumedPolicy() when assumed != null:
return assumed(_that.analytics,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ask,required TResult Function( String? analytics,  String? diagnostics)  assumed,}) {final _that = this;
switch (_that) {
case AskPolicy():
return ask();case AssumedPolicy():
return assumed(_that.analytics,_that.diagnostics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ask,TResult? Function( String? analytics,  String? diagnostics)?  assumed,}) {final _that = this;
switch (_that) {
case AskPolicy() when ask != null:
return ask();case AssumedPolicy() when assumed != null:
return assumed(_that.analytics,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class AskPolicy implements ConsentPolicy {
  const AskPolicy();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AskPolicy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConsentPolicy.ask()';
}


}




/// @nodoc


class AssumedPolicy implements ConsentPolicy {
  const AssumedPolicy({this.analytics, this.diagnostics});
  

 final  String? analytics;
 final  String? diagnostics;

/// Create a copy of ConsentPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssumedPolicyCopyWith<AssumedPolicy> get copyWith => _$AssumedPolicyCopyWithImpl<AssumedPolicy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssumedPolicy&&(identical(other.analytics, analytics) || other.analytics == analytics)&&(identical(other.diagnostics, diagnostics) || other.diagnostics == diagnostics));
}


@override
int get hashCode => Object.hash(runtimeType,analytics,diagnostics);

@override
String toString() {
  return 'ConsentPolicy.assumed(analytics: $analytics, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class $AssumedPolicyCopyWith<$Res> implements $ConsentPolicyCopyWith<$Res> {
  factory $AssumedPolicyCopyWith(AssumedPolicy value, $Res Function(AssumedPolicy) _then) = _$AssumedPolicyCopyWithImpl;
@useResult
$Res call({
 String? analytics, String? diagnostics
});




}
/// @nodoc
class _$AssumedPolicyCopyWithImpl<$Res>
    implements $AssumedPolicyCopyWith<$Res> {
  _$AssumedPolicyCopyWithImpl(this._self, this._then);

  final AssumedPolicy _self;
  final $Res Function(AssumedPolicy) _then;

/// Create a copy of ConsentPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? analytics = freezed,Object? diagnostics = freezed,}) {
  return _then(AssumedPolicy(
analytics: freezed == analytics ? _self.analytics : analytics // ignore: cast_nullable_to_non_nullable
as String?,diagnostics: freezed == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
