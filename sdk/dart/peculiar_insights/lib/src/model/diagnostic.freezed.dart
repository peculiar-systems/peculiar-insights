// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diagnostic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Diagnostic {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Diagnostic);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Diagnostic()';
}


}

/// @nodoc
class $DiagnosticCopyWith<$Res>  {
$DiagnosticCopyWith(Diagnostic _, $Res Function(Diagnostic) __);
}


/// Adds pattern-matching-related methods to [Diagnostic].
extension DiagnosticPatterns on Diagnostic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RejectedDiagnostic value)?  rejected,TResult Function( TransportFailedDiagnostic value)?  transportFailed,TResult Function( DroppedDiagnostic value)?  dropped,TResult Function( ConversionFailedDiagnostic value)?  conversionFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RejectedDiagnostic() when rejected != null:
return rejected(_that);case TransportFailedDiagnostic() when transportFailed != null:
return transportFailed(_that);case DroppedDiagnostic() when dropped != null:
return dropped(_that);case ConversionFailedDiagnostic() when conversionFailed != null:
return conversionFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RejectedDiagnostic value)  rejected,required TResult Function( TransportFailedDiagnostic value)  transportFailed,required TResult Function( DroppedDiagnostic value)  dropped,required TResult Function( ConversionFailedDiagnostic value)  conversionFailed,}){
final _that = this;
switch (_that) {
case RejectedDiagnostic():
return rejected(_that);case TransportFailedDiagnostic():
return transportFailed(_that);case DroppedDiagnostic():
return dropped(_that);case ConversionFailedDiagnostic():
return conversionFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RejectedDiagnostic value)?  rejected,TResult? Function( TransportFailedDiagnostic value)?  transportFailed,TResult? Function( DroppedDiagnostic value)?  dropped,TResult? Function( ConversionFailedDiagnostic value)?  conversionFailed,}){
final _that = this;
switch (_that) {
case RejectedDiagnostic() when rejected != null:
return rejected(_that);case TransportFailedDiagnostic() when transportFailed != null:
return transportFailed(_that);case DroppedDiagnostic() when dropped != null:
return dropped(_that);case ConversionFailedDiagnostic() when conversionFailed != null:
return conversionFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String outcome,  String reason)?  rejected,TResult Function( int code,  String message,  bool willRetry)?  transportFailed,TResult Function( int count,  String reason)?  dropped,TResult Function( String key,  String type)?  conversionFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RejectedDiagnostic() when rejected != null:
return rejected(_that.id,_that.outcome,_that.reason);case TransportFailedDiagnostic() when transportFailed != null:
return transportFailed(_that.code,_that.message,_that.willRetry);case DroppedDiagnostic() when dropped != null:
return dropped(_that.count,_that.reason);case ConversionFailedDiagnostic() when conversionFailed != null:
return conversionFailed(_that.key,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String outcome,  String reason)  rejected,required TResult Function( int code,  String message,  bool willRetry)  transportFailed,required TResult Function( int count,  String reason)  dropped,required TResult Function( String key,  String type)  conversionFailed,}) {final _that = this;
switch (_that) {
case RejectedDiagnostic():
return rejected(_that.id,_that.outcome,_that.reason);case TransportFailedDiagnostic():
return transportFailed(_that.code,_that.message,_that.willRetry);case DroppedDiagnostic():
return dropped(_that.count,_that.reason);case ConversionFailedDiagnostic():
return conversionFailed(_that.key,_that.type);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String outcome,  String reason)?  rejected,TResult? Function( int code,  String message,  bool willRetry)?  transportFailed,TResult? Function( int count,  String reason)?  dropped,TResult? Function( String key,  String type)?  conversionFailed,}) {final _that = this;
switch (_that) {
case RejectedDiagnostic() when rejected != null:
return rejected(_that.id,_that.outcome,_that.reason);case TransportFailedDiagnostic() when transportFailed != null:
return transportFailed(_that.code,_that.message,_that.willRetry);case DroppedDiagnostic() when dropped != null:
return dropped(_that.count,_that.reason);case ConversionFailedDiagnostic() when conversionFailed != null:
return conversionFailed(_that.key,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class RejectedDiagnostic implements Diagnostic {
  const RejectedDiagnostic({required this.id, required this.outcome, required this.reason});
  

 final  String id;
 final  String outcome;
 final  String reason;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RejectedDiagnosticCopyWith<RejectedDiagnostic> get copyWith => _$RejectedDiagnosticCopyWithImpl<RejectedDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RejectedDiagnostic&&(identical(other.id, id) || other.id == id)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,id,outcome,reason);

@override
String toString() {
  return 'Diagnostic.rejected(id: $id, outcome: $outcome, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $RejectedDiagnosticCopyWith<$Res> implements $DiagnosticCopyWith<$Res> {
  factory $RejectedDiagnosticCopyWith(RejectedDiagnostic value, $Res Function(RejectedDiagnostic) _then) = _$RejectedDiagnosticCopyWithImpl;
@useResult
$Res call({
 String id, String outcome, String reason
});




}
/// @nodoc
class _$RejectedDiagnosticCopyWithImpl<$Res>
    implements $RejectedDiagnosticCopyWith<$Res> {
  _$RejectedDiagnosticCopyWithImpl(this._self, this._then);

  final RejectedDiagnostic _self;
  final $Res Function(RejectedDiagnostic) _then;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? outcome = null,Object? reason = null,}) {
  return _then(RejectedDiagnostic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TransportFailedDiagnostic implements Diagnostic {
  const TransportFailedDiagnostic({required this.code, required this.message, required this.willRetry});
  

 final  int code;
 final  String message;
 final  bool willRetry;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransportFailedDiagnosticCopyWith<TransportFailedDiagnostic> get copyWith => _$TransportFailedDiagnosticCopyWithImpl<TransportFailedDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransportFailedDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.willRetry, willRetry) || other.willRetry == willRetry));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,willRetry);

@override
String toString() {
  return 'Diagnostic.transportFailed(code: $code, message: $message, willRetry: $willRetry)';
}


}

/// @nodoc
abstract mixin class $TransportFailedDiagnosticCopyWith<$Res> implements $DiagnosticCopyWith<$Res> {
  factory $TransportFailedDiagnosticCopyWith(TransportFailedDiagnostic value, $Res Function(TransportFailedDiagnostic) _then) = _$TransportFailedDiagnosticCopyWithImpl;
@useResult
$Res call({
 int code, String message, bool willRetry
});




}
/// @nodoc
class _$TransportFailedDiagnosticCopyWithImpl<$Res>
    implements $TransportFailedDiagnosticCopyWith<$Res> {
  _$TransportFailedDiagnosticCopyWithImpl(this._self, this._then);

  final TransportFailedDiagnostic _self;
  final $Res Function(TransportFailedDiagnostic) _then;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? willRetry = null,}) {
  return _then(TransportFailedDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,willRetry: null == willRetry ? _self.willRetry : willRetry // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class DroppedDiagnostic implements Diagnostic {
  const DroppedDiagnostic({required this.count, required this.reason});
  

 final  int count;
 final  String reason;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DroppedDiagnosticCopyWith<DroppedDiagnostic> get copyWith => _$DroppedDiagnosticCopyWithImpl<DroppedDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DroppedDiagnostic&&(identical(other.count, count) || other.count == count)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,count,reason);

@override
String toString() {
  return 'Diagnostic.dropped(count: $count, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $DroppedDiagnosticCopyWith<$Res> implements $DiagnosticCopyWith<$Res> {
  factory $DroppedDiagnosticCopyWith(DroppedDiagnostic value, $Res Function(DroppedDiagnostic) _then) = _$DroppedDiagnosticCopyWithImpl;
@useResult
$Res call({
 int count, String reason
});




}
/// @nodoc
class _$DroppedDiagnosticCopyWithImpl<$Res>
    implements $DroppedDiagnosticCopyWith<$Res> {
  _$DroppedDiagnosticCopyWithImpl(this._self, this._then);

  final DroppedDiagnostic _self;
  final $Res Function(DroppedDiagnostic) _then;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? count = null,Object? reason = null,}) {
  return _then(DroppedDiagnostic(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ConversionFailedDiagnostic implements Diagnostic {
  const ConversionFailedDiagnostic({required this.key, required this.type});
  

 final  String key;
 final  String type;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversionFailedDiagnosticCopyWith<ConversionFailedDiagnostic> get copyWith => _$ConversionFailedDiagnosticCopyWithImpl<ConversionFailedDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversionFailedDiagnostic&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,key,type);

@override
String toString() {
  return 'Diagnostic.conversionFailed(key: $key, type: $type)';
}


}

/// @nodoc
abstract mixin class $ConversionFailedDiagnosticCopyWith<$Res> implements $DiagnosticCopyWith<$Res> {
  factory $ConversionFailedDiagnosticCopyWith(ConversionFailedDiagnostic value, $Res Function(ConversionFailedDiagnostic) _then) = _$ConversionFailedDiagnosticCopyWithImpl;
@useResult
$Res call({
 String key, String type
});




}
/// @nodoc
class _$ConversionFailedDiagnosticCopyWithImpl<$Res>
    implements $ConversionFailedDiagnosticCopyWith<$Res> {
  _$ConversionFailedDiagnosticCopyWithImpl(this._self, this._then);

  final ConversionFailedDiagnostic _self;
  final $Res Function(ConversionFailedDiagnostic) _then;

/// Create a copy of Diagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,Object? type = null,}) {
  return _then(ConversionFailedDiagnostic(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
