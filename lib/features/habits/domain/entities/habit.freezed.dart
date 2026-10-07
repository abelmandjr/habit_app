// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'habit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Habit {

 String get id; String get title; String get description; String get category; HabitType get type;/// Unidade dos hábitos quantitativos (ex.: "L"); `null` nos sim/não.
 String? get unit;/// Meta diária dos quantitativos; 1 nos sim/não.
 int get goalValue; bool get reminderEnabled; int? get reminderHour; int? get reminderMinute;/// Até à v5 (coluna `startDate`, tarefa 3.4), é também a data de início.
 DateTime get createdAt;
/// Create a copy of Habit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HabitCopyWith<Habit> get copyWith => _$HabitCopyWithImpl<Habit>(this as Habit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Habit&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.goalValue, goalValue) || other.goalValue == goalValue)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,type,unit,goalValue,reminderEnabled,reminderHour,reminderMinute,createdAt);

@override
String toString() {
  return 'Habit(id: $id, title: $title, description: $description, category: $category, type: $type, unit: $unit, goalValue: $goalValue, reminderEnabled: $reminderEnabled, reminderHour: $reminderHour, reminderMinute: $reminderMinute, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $HabitCopyWith<$Res>  {
  factory $HabitCopyWith(Habit value, $Res Function(Habit) _then) = _$HabitCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String category, HabitType type, String? unit, int goalValue, bool reminderEnabled, int? reminderHour, int? reminderMinute, DateTime createdAt
});




}
/// @nodoc
class _$HabitCopyWithImpl<$Res>
    implements $HabitCopyWith<$Res> {
  _$HabitCopyWithImpl(this._self, this._then);

  final Habit _self;
  final $Res Function(Habit) _then;

/// Create a copy of Habit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? type = null,Object? unit = freezed,Object? goalValue = null,Object? reminderEnabled = null,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HabitType,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,goalValue: null == goalValue ? _self.goalValue : goalValue // ignore: cast_nullable_to_non_nullable
as int,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Habit].
extension HabitPatterns on Habit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Habit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Habit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Habit value)  $default,){
final _that = this;
switch (_that) {
case _Habit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Habit value)?  $default,){
final _that = this;
switch (_that) {
case _Habit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String category,  HabitType type,  String? unit,  int goalValue,  bool reminderEnabled,  int? reminderHour,  int? reminderMinute,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Habit() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.type,_that.unit,_that.goalValue,_that.reminderEnabled,_that.reminderHour,_that.reminderMinute,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String category,  HabitType type,  String? unit,  int goalValue,  bool reminderEnabled,  int? reminderHour,  int? reminderMinute,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Habit():
return $default(_that.id,_that.title,_that.description,_that.category,_that.type,_that.unit,_that.goalValue,_that.reminderEnabled,_that.reminderHour,_that.reminderMinute,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String category,  HabitType type,  String? unit,  int goalValue,  bool reminderEnabled,  int? reminderHour,  int? reminderMinute,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Habit() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.type,_that.unit,_that.goalValue,_that.reminderEnabled,_that.reminderHour,_that.reminderMinute,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Habit implements Habit {
  const _Habit({required this.id, required this.title, this.description = '', required this.category, required this.type, this.unit, this.goalValue = 1, this.reminderEnabled = false, this.reminderHour, this.reminderMinute, required this.createdAt});
  

@override final  String id;
@override final  String title;
@override@JsonKey() final  String description;
@override final  String category;
@override final  HabitType type;
/// Unidade dos hábitos quantitativos (ex.: "L"); `null` nos sim/não.
@override final  String? unit;
/// Meta diária dos quantitativos; 1 nos sim/não.
@override@JsonKey() final  int goalValue;
@override@JsonKey() final  bool reminderEnabled;
@override final  int? reminderHour;
@override final  int? reminderMinute;
/// Até à v5 (coluna `startDate`, tarefa 3.4), é também a data de início.
@override final  DateTime createdAt;

/// Create a copy of Habit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HabitCopyWith<_Habit> get copyWith => __$HabitCopyWithImpl<_Habit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Habit&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.goalValue, goalValue) || other.goalValue == goalValue)&&(identical(other.reminderEnabled, reminderEnabled) || other.reminderEnabled == reminderEnabled)&&(identical(other.reminderHour, reminderHour) || other.reminderHour == reminderHour)&&(identical(other.reminderMinute, reminderMinute) || other.reminderMinute == reminderMinute)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description,category,type,unit,goalValue,reminderEnabled,reminderHour,reminderMinute,createdAt);

@override
String toString() {
  return 'Habit(id: $id, title: $title, description: $description, category: $category, type: $type, unit: $unit, goalValue: $goalValue, reminderEnabled: $reminderEnabled, reminderHour: $reminderHour, reminderMinute: $reminderMinute, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HabitCopyWith<$Res> implements $HabitCopyWith<$Res> {
  factory _$HabitCopyWith(_Habit value, $Res Function(_Habit) _then) = __$HabitCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String category, HabitType type, String? unit, int goalValue, bool reminderEnabled, int? reminderHour, int? reminderMinute, DateTime createdAt
});




}
/// @nodoc
class __$HabitCopyWithImpl<$Res>
    implements _$HabitCopyWith<$Res> {
  __$HabitCopyWithImpl(this._self, this._then);

  final _Habit _self;
  final $Res Function(_Habit) _then;

/// Create a copy of Habit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = null,Object? type = null,Object? unit = freezed,Object? goalValue = null,Object? reminderEnabled = null,Object? reminderHour = freezed,Object? reminderMinute = freezed,Object? createdAt = null,}) {
  return _then(_Habit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HabitType,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,goalValue: null == goalValue ? _self.goalValue : goalValue // ignore: cast_nullable_to_non_nullable
as int,reminderEnabled: null == reminderEnabled ? _self.reminderEnabled : reminderEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminderHour: freezed == reminderHour ? _self.reminderHour : reminderHour // ignore: cast_nullable_to_non_nullable
as int?,reminderMinute: freezed == reminderMinute ? _self.reminderMinute : reminderMinute // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
