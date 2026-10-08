// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'habit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HabitLog {

 String get habitId;/// Dia de calendário, `YYYY-MM-DD`.
 String get date;/// 1 nos sim/não; o valor registado nos quantitativos.
 double? get value;
/// Create a copy of HabitLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HabitLogCopyWith<HabitLog> get copyWith => _$HabitLogCopyWithImpl<HabitLog>(this as HabitLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HabitLog&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,habitId,date,value);

@override
String toString() {
  return 'HabitLog(habitId: $habitId, date: $date, value: $value)';
}


}

/// @nodoc
abstract mixin class $HabitLogCopyWith<$Res>  {
  factory $HabitLogCopyWith(HabitLog value, $Res Function(HabitLog) _then) = _$HabitLogCopyWithImpl;
@useResult
$Res call({
 String habitId, String date, double? value
});




}
/// @nodoc
class _$HabitLogCopyWithImpl<$Res>
    implements $HabitLogCopyWith<$Res> {
  _$HabitLogCopyWithImpl(this._self, this._then);

  final HabitLog _self;
  final $Res Function(HabitLog) _then;

/// Create a copy of HabitLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? habitId = null,Object? date = null,Object? value = freezed,}) {
  return _then(_self.copyWith(
habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [HabitLog].
extension HabitLogPatterns on HabitLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HabitLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HabitLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HabitLog value)  $default,){
final _that = this;
switch (_that) {
case _HabitLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HabitLog value)?  $default,){
final _that = this;
switch (_that) {
case _HabitLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String habitId,  String date,  double? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HabitLog() when $default != null:
return $default(_that.habitId,_that.date,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String habitId,  String date,  double? value)  $default,) {final _that = this;
switch (_that) {
case _HabitLog():
return $default(_that.habitId,_that.date,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String habitId,  String date,  double? value)?  $default,) {final _that = this;
switch (_that) {
case _HabitLog() when $default != null:
return $default(_that.habitId,_that.date,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _HabitLog implements HabitLog {
  const _HabitLog({required this.habitId, required this.date, this.value});
  

@override final  String habitId;
/// Dia de calendário, `YYYY-MM-DD`.
@override final  String date;
/// 1 nos sim/não; o valor registado nos quantitativos.
@override final  double? value;

/// Create a copy of HabitLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HabitLogCopyWith<_HabitLog> get copyWith => __$HabitLogCopyWithImpl<_HabitLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HabitLog&&(identical(other.habitId, habitId) || other.habitId == habitId)&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,habitId,date,value);

@override
String toString() {
  return 'HabitLog(habitId: $habitId, date: $date, value: $value)';
}


}

/// @nodoc
abstract mixin class _$HabitLogCopyWith<$Res> implements $HabitLogCopyWith<$Res> {
  factory _$HabitLogCopyWith(_HabitLog value, $Res Function(_HabitLog) _then) = __$HabitLogCopyWithImpl;
@override @useResult
$Res call({
 String habitId, String date, double? value
});




}
/// @nodoc
class __$HabitLogCopyWithImpl<$Res>
    implements _$HabitLogCopyWith<$Res> {
  __$HabitLogCopyWithImpl(this._self, this._then);

  final _HabitLog _self;
  final $Res Function(_HabitLog) _then;

/// Create a copy of HabitLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? habitId = null,Object? date = null,Object? value = freezed,}) {
  return _then(_HabitLog(
habitId: null == habitId ? _self.habitId : habitId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
