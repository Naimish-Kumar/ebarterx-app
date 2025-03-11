

import 'package:eClassify/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetApiKeysCubit extends Cubit<GetApiKeysState> {
  GetApiKeysCubit() : super(GetApiKeysInitial());

  Future<void> fetch() async {
    try {
      emit(GetApiKeysInProgress());
      Map<String, dynamic> result =
          await Api.get(url: Api.getPaymentSettingsApi);
      var data = result['data'] ?? {};

      emit(GetApiKeysSuccess(
        razorPayApiKey: _getData(data, 'Razorpay', 'api_key'),
        razorPayCurrency: _getData(data, 'Razorpay', 'currency_code'),
        razorPayStatus: _getIntData(data, 'Razorpay', 'status'),
        payStackApiKey: _getData(data, 'Paystack', 'api_key'),
        payStackStatus: _getIntData(data, 'Paystack', 'status'),
        payStackCurrency: _getData(data, 'Paystack', 'currency_code'),
        stripeCurrency: _getData(data, 'Stripe', 'currency_code'),
        stripePublishableKey: _getData(data, 'Stripe', 'api_key'),
        stripeStatus: _getIntData(data, 'Stripe', 'status'),
        phonePeKey: _getData(data, 'PhonePe', 'api_key'),
        phonePeCurrency: _getData(data, 'PhonePe', 'currency_code'),
        phonePeStatus: _getIntData(data, 'PhonePe', 'status'),
        flutterWaveKey: _getData(data, 'flutterwave', 'api_key'),
        flutterWaveCurrency: _getData(data, 'flutterwave', 'currency_code'),
        flutterWaveStatus: _getIntData(data, 'flutterwave', 'status'),
      ));
    } catch (e) {
      emit(GetApiKeysFail(e.toString()));
    }
  }

  String? _getData(Map<String, dynamic> data, String type, String key) =>
      data[type]?[key]?.toString();

  int _getIntData(Map<String, dynamic> data, String type, String key) =>
      int.tryParse(_getData(data, type, key) ?? '0') ?? 0;
}

abstract class GetApiKeysState {}

class GetApiKeysInitial extends GetApiKeysState {}

class GetApiKeysInProgress extends GetApiKeysState {}

class GetApiKeysFail extends GetApiKeysState {
  final dynamic error;

  GetApiKeysFail(this.error);
}

class GetApiKeysSuccess extends GetApiKeysState {
  final String? razorPayApiKey,
      razorPayCurrency,
      payStackApiKey,
      payStackCurrency,
      stripeCurrency,
      stripePublishableKey,
      phonePeKey,
      phonePeCurrency,
      flutterWaveKey,
      flutterWaveCurrency;
  final int razorPayStatus,
      payStackStatus,
      stripeStatus,
      phonePeStatus,
      flutterWaveStatus;

  GetApiKeysSuccess({
    this.razorPayApiKey,
    this.razorPayCurrency,
    this.payStackApiKey,
    this.payStackCurrency,
    this.stripeCurrency,
    this.stripePublishableKey,
    this.phonePeKey,
    this.phonePeCurrency,
    this.flutterWaveKey,
    this.flutterWaveCurrency,
    this.razorPayStatus = 0,
    this.payStackStatus = 0,
    this.stripeStatus = 0,
    this.phonePeStatus = 0,
    this.flutterWaveStatus = 0,
  });
}
