// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signature_request_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;


final _privateConstructorUsedError = UnsupportedError('It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SignatureRequestData {

 ParsedSigningRequest get ledgerSignRequest => throw _privateConstructorUsedError; CardanoPubAccount get ledgerPubAccount => throw _privateConstructorUsedError;







/// Create a copy of SignatureRequestData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
$SignatureRequestDataCopyWith<SignatureRequestData> get copyWith => throw _privateConstructorUsedError;

}

/// @nodoc
abstract class $SignatureRequestDataCopyWith<$Res>  {
  factory $SignatureRequestDataCopyWith(SignatureRequestData value, $Res Function(SignatureRequestData) then) = _$SignatureRequestDataCopyWithImpl<$Res, SignatureRequestData>;
@useResult
$Res call({
 ParsedSigningRequest ledgerSignRequest, CardanoPubAccount ledgerPubAccount
});


$ParsedSigningRequestCopyWith<$Res> get ledgerSignRequest;$CardanoPubAccountCopyWith<$Res> get ledgerPubAccount;
}

/// @nodoc
class _$SignatureRequestDataCopyWithImpl<$Res,$Val extends SignatureRequestData> implements $SignatureRequestDataCopyWith<$Res> {
  _$SignatureRequestDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

/// Create a copy of SignatureRequestData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ledgerSignRequest = null,Object? ledgerPubAccount = null,}) {
  return _then(_value.copyWith(
ledgerSignRequest: null == ledgerSignRequest ? _value.ledgerSignRequest : ledgerSignRequest // ignore: cast_nullable_to_non_nullable
as ParsedSigningRequest,ledgerPubAccount: null == ledgerPubAccount ? _value.ledgerPubAccount : ledgerPubAccount // ignore: cast_nullable_to_non_nullable
as CardanoPubAccount,
  )as $Val);
}
/// Create a copy of SignatureRequestData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParsedSigningRequestCopyWith<$Res> get ledgerSignRequest {
  
  return $ParsedSigningRequestCopyWith<$Res>(_value.ledgerSignRequest, (value) {
    return _then(_value.copyWith(ledgerSignRequest: value) as $Val);
  });
}/// Create a copy of SignatureRequestData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardanoPubAccountCopyWith<$Res> get ledgerPubAccount {
  
  return $CardanoPubAccountCopyWith<$Res>(_value.ledgerPubAccount, (value) {
    return _then(_value.copyWith(ledgerPubAccount: value) as $Val);
  });
}
}


/// @nodoc
abstract class _$$SignatureRequestDataImplCopyWith<$Res> implements $SignatureRequestDataCopyWith<$Res> {
  factory _$$SignatureRequestDataImplCopyWith(_$SignatureRequestDataImpl value, $Res Function(_$SignatureRequestDataImpl) then) = __$$SignatureRequestDataImplCopyWithImpl<$Res>;
@override @useResult
$Res call({
 ParsedSigningRequest ledgerSignRequest, CardanoPubAccount ledgerPubAccount
});


@override $ParsedSigningRequestCopyWith<$Res> get ledgerSignRequest;@override $CardanoPubAccountCopyWith<$Res> get ledgerPubAccount;
}

/// @nodoc
class __$$SignatureRequestDataImplCopyWithImpl<$Res> extends _$SignatureRequestDataCopyWithImpl<$Res, _$SignatureRequestDataImpl> implements _$$SignatureRequestDataImplCopyWith<$Res> {
  __$$SignatureRequestDataImplCopyWithImpl(_$SignatureRequestDataImpl _value, $Res Function(_$SignatureRequestDataImpl) _then)
      : super(_value, _then);


/// Create a copy of SignatureRequestData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ledgerSignRequest = null,Object? ledgerPubAccount = null,}) {
  return _then(_$SignatureRequestDataImpl(
ledgerSignRequest: null == ledgerSignRequest ? _value.ledgerSignRequest : ledgerSignRequest // ignore: cast_nullable_to_non_nullable
as ParsedSigningRequest,ledgerPubAccount: null == ledgerPubAccount ? _value.ledgerPubAccount : ledgerPubAccount // ignore: cast_nullable_to_non_nullable
as CardanoPubAccount,
  ));
}


}

/// @nodoc


class _$SignatureRequestDataImpl extends _SignatureRequestData  {
  const _$SignatureRequestDataImpl({required this.ledgerSignRequest, required this.ledgerPubAccount}): super._();

  

@override final  ParsedSigningRequest ledgerSignRequest;
@override final  CardanoPubAccount ledgerPubAccount;

@override
String toString() {
  return 'SignatureRequestData(ledgerSignRequest: $ledgerSignRequest, ledgerPubAccount: $ledgerPubAccount)';
}


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _$SignatureRequestDataImpl&&(identical(other.ledgerSignRequest, ledgerSignRequest) || other.ledgerSignRequest == ledgerSignRequest)&&(identical(other.ledgerPubAccount, ledgerPubAccount) || other.ledgerPubAccount == ledgerPubAccount));
}


@override
int get hashCode => Object.hash(runtimeType,ledgerSignRequest,ledgerPubAccount);

/// Create a copy of SignatureRequestData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@override
@pragma('vm:prefer-inline')
_$$SignatureRequestDataImplCopyWith<_$SignatureRequestDataImpl> get copyWith => __$$SignatureRequestDataImplCopyWithImpl<_$SignatureRequestDataImpl>(this, _$identity);








}


abstract class _SignatureRequestData extends SignatureRequestData {
  const factory _SignatureRequestData({required final  ParsedSigningRequest ledgerSignRequest, required final  CardanoPubAccount ledgerPubAccount}) = _$SignatureRequestDataImpl;
  const _SignatureRequestData._(): super._();

  

@override ParsedSigningRequest get ledgerSignRequest;@override CardanoPubAccount get ledgerPubAccount;
/// Create a copy of SignatureRequestData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
_$$SignatureRequestDataImplCopyWith<_$SignatureRequestDataImpl> get copyWith => throw _privateConstructorUsedError;

}
