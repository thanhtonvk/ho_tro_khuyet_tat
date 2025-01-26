// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'face_detect_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FaceDetectResult {
  List<FaceResult> get result => throw _privateConstructorUsedError;
  KannaRotateResult? get image => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FaceDetectResultCopyWith<FaceDetectResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FaceDetectResultCopyWith<$Res> {
  factory $FaceDetectResultCopyWith(
          FaceDetectResult value, $Res Function(FaceDetectResult) then) =
      _$FaceDetectResultCopyWithImpl<$Res, FaceDetectResult>;
  @useResult
  $Res call({List<FaceResult> result, KannaRotateResult? image});

  $KannaRotateResultCopyWith<$Res>? get image;
}

/// @nodoc
class _$FaceDetectResultCopyWithImpl<$Res, $Val extends FaceDetectResult>
    implements $FaceDetectResultCopyWith<$Res> {
  _$FaceDetectResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = null,
    Object? image = freezed,
  }) {
    return _then(_value.copyWith(
      result: null == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as List<FaceResult>,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as KannaRotateResult?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $KannaRotateResultCopyWith<$Res>? get image {
    if (_value.image == null) {
      return null;
    }

    return $KannaRotateResultCopyWith<$Res>(_value.image!, (value) {
      return _then(_value.copyWith(image: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FaceDetectResultImplCopyWith<$Res>
    implements $FaceDetectResultCopyWith<$Res> {
  factory _$$FaceDetectResultImplCopyWith(_$FaceDetectResultImpl value,
          $Res Function(_$FaceDetectResultImpl) then) =
      __$$FaceDetectResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<FaceResult> result, KannaRotateResult? image});

  @override
  $KannaRotateResultCopyWith<$Res>? get image;
}

/// @nodoc
class __$$FaceDetectResultImplCopyWithImpl<$Res>
    extends _$FaceDetectResultCopyWithImpl<$Res, _$FaceDetectResultImpl>
    implements _$$FaceDetectResultImplCopyWith<$Res> {
  __$$FaceDetectResultImplCopyWithImpl(_$FaceDetectResultImpl _value,
      $Res Function(_$FaceDetectResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? result = null,
    Object? image = freezed,
  }) {
    return _then(_$FaceDetectResultImpl(
      result: null == result
          ? _value._result
          : result // ignore: cast_nullable_to_non_nullable
              as List<FaceResult>,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as KannaRotateResult?,
    ));
  }
}

/// @nodoc

class _$FaceDetectResultImpl
    with DiagnosticableTreeMixin
    implements _FaceDetectResult {
  const _$FaceDetectResultImpl(
      {final List<FaceResult> result = const <FaceResult>[], this.image})
      : _result = result;

  final List<FaceResult> _result;
  @override
  @JsonKey()
  List<FaceResult> get result {
    if (_result is EqualUnmodifiableListView) return _result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_result);
  }

  @override
  final KannaRotateResult? image;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FaceDetectResult(result: $result, image: $image)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'FaceDetectResult'))
      ..add(DiagnosticsProperty('result', result))
      ..add(DiagnosticsProperty('image', image));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FaceDetectResultImpl &&
            const DeepCollectionEquality().equals(other._result, _result) &&
            (identical(other.image, image) || other.image == image));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_result), image);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FaceDetectResultImplCopyWith<_$FaceDetectResultImpl> get copyWith =>
      __$$FaceDetectResultImplCopyWithImpl<_$FaceDetectResultImpl>(
          this, _$identity);
}

abstract class _FaceDetectResult implements FaceDetectResult {
  const factory _FaceDetectResult(
      {final List<FaceResult> result,
      final KannaRotateResult? image}) = _$FaceDetectResultImpl;

  @override
  List<FaceResult> get result;
  @override
  KannaRotateResult? get image;
  @override
  @JsonKey(ignore: true)
  _$$FaceDetectResultImplCopyWith<_$FaceDetectResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
