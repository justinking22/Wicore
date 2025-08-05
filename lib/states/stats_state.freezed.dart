// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$StatsState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isRefreshing => throw _privateConstructorUsedError;
  StatsResponse? get currentStats => throw _privateConstructorUsedError;
  List<StatsResponse> get historicalStats => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get selectedDate => throw _privateConstructorUsedError;
  StatsTimeRange get timeRange => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $StatsStateCopyWith<StatsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatsStateCopyWith<$Res> {
  factory $StatsStateCopyWith(
          StatsState value, $Res Function(StatsState) then) =
      _$StatsStateCopyWithImpl<$Res, StatsState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isRefreshing,
      StatsResponse? currentStats,
      List<StatsResponse> historicalStats,
      String? error,
      String? selectedDate,
      StatsTimeRange timeRange});
}

/// @nodoc
class _$StatsStateCopyWithImpl<$Res, $Val extends StatsState>
    implements $StatsStateCopyWith<$Res> {
  _$StatsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? currentStats = freezed,
    Object? historicalStats = null,
    Object? error = freezed,
    Object? selectedDate = freezed,
    Object? timeRange = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _value.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      currentStats: freezed == currentStats
          ? _value.currentStats
          : currentStats // ignore: cast_nullable_to_non_nullable
              as StatsResponse?,
      historicalStats: null == historicalStats
          ? _value.historicalStats
          : historicalStats // ignore: cast_nullable_to_non_nullable
              as List<StatsResponse>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedDate: freezed == selectedDate
          ? _value.selectedDate
          : selectedDate // ignore: cast_nullable_to_non_nullable
              as String?,
      timeRange: null == timeRange
          ? _value.timeRange
          : timeRange // ignore: cast_nullable_to_non_nullable
              as StatsTimeRange,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StatsStateImplCopyWith<$Res>
    implements $StatsStateCopyWith<$Res> {
  factory _$$StatsStateImplCopyWith(
          _$StatsStateImpl value, $Res Function(_$StatsStateImpl) then) =
      __$$StatsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isRefreshing,
      StatsResponse? currentStats,
      List<StatsResponse> historicalStats,
      String? error,
      String? selectedDate,
      StatsTimeRange timeRange});
}

/// @nodoc
class __$$StatsStateImplCopyWithImpl<$Res>
    extends _$StatsStateCopyWithImpl<$Res, _$StatsStateImpl>
    implements _$$StatsStateImplCopyWith<$Res> {
  __$$StatsStateImplCopyWithImpl(
      _$StatsStateImpl _value, $Res Function(_$StatsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? currentStats = freezed,
    Object? historicalStats = null,
    Object? error = freezed,
    Object? selectedDate = freezed,
    Object? timeRange = null,
  }) {
    return _then(_$StatsStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _value.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      currentStats: freezed == currentStats
          ? _value.currentStats
          : currentStats // ignore: cast_nullable_to_non_nullable
              as StatsResponse?,
      historicalStats: null == historicalStats
          ? _value._historicalStats
          : historicalStats // ignore: cast_nullable_to_non_nullable
              as List<StatsResponse>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedDate: freezed == selectedDate
          ? _value.selectedDate
          : selectedDate // ignore: cast_nullable_to_non_nullable
              as String?,
      timeRange: null == timeRange
          ? _value.timeRange
          : timeRange // ignore: cast_nullable_to_non_nullable
              as StatsTimeRange,
    ));
  }
}

/// @nodoc

class _$StatsStateImpl extends _StatsState {
  const _$StatsStateImpl(
      {this.isLoading = false,
      this.isRefreshing = false,
      this.currentStats,
      final List<StatsResponse> historicalStats = const [],
      this.error,
      this.selectedDate,
      this.timeRange = StatsTimeRange.today})
      : _historicalStats = historicalStats,
        super._();

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isRefreshing;
  @override
  final StatsResponse? currentStats;
  final List<StatsResponse> _historicalStats;
  @override
  @JsonKey()
  List<StatsResponse> get historicalStats {
    if (_historicalStats is EqualUnmodifiableListView) return _historicalStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_historicalStats);
  }

  @override
  final String? error;
  @override
  final String? selectedDate;
  @override
  @JsonKey()
  final StatsTimeRange timeRange;

  @override
  String toString() {
    return 'StatsState(isLoading: $isLoading, isRefreshing: $isRefreshing, currentStats: $currentStats, historicalStats: $historicalStats, error: $error, selectedDate: $selectedDate, timeRange: $timeRange)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatsStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.currentStats, currentStats) ||
                other.currentStats == currentStats) &&
            const DeepCollectionEquality()
                .equals(other._historicalStats, _historicalStats) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.selectedDate, selectedDate) ||
                other.selectedDate == selectedDate) &&
            (identical(other.timeRange, timeRange) ||
                other.timeRange == timeRange));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      isRefreshing,
      currentStats,
      const DeepCollectionEquality().hash(_historicalStats),
      error,
      selectedDate,
      timeRange);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StatsStateImplCopyWith<_$StatsStateImpl> get copyWith =>
      __$$StatsStateImplCopyWithImpl<_$StatsStateImpl>(this, _$identity);
}

abstract class _StatsState extends StatsState {
  const factory _StatsState(
      {final bool isLoading,
      final bool isRefreshing,
      final StatsResponse? currentStats,
      final List<StatsResponse> historicalStats,
      final String? error,
      final String? selectedDate,
      final StatsTimeRange timeRange}) = _$StatsStateImpl;
  const _StatsState._() : super._();

  @override
  bool get isLoading;
  @override
  bool get isRefreshing;
  @override
  StatsResponse? get currentStats;
  @override
  List<StatsResponse> get historicalStats;
  @override
  String? get error;
  @override
  String? get selectedDate;
  @override
  StatsTimeRange get timeRange;
  @override
  @JsonKey(ignore: true)
  _$$StatsStateImplCopyWith<_$StatsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
