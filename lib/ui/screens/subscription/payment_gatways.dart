import 'dart:convert';
import 'dart:io';

import 'package:eBarterx/settings.dart';
import 'package:eBarterx/utils/constant.dart';
import 'package:eBarterx/utils/extensions/extensions.dart';
import 'package:eBarterx/utils/helper_utils.dart';
import 'package:eBarterx/utils/hive_utils.dart';
import 'package:eBarterx/utils/payment/gateaways/stripe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentGateways {
  static String generateReference(String email) {
    late String platform;
    if (Platform.isIOS) {
      platform = 'I';
    } else if (Platform.isAndroid) {
      platform = 'A';
    }
    String reference =
        '${platform}_${email.split("@").first}_${DateTime.now().millisecondsSinceEpoch}';
    return reference;
  }

  static Future<void> stripe(BuildContext context,
      {required double price,
      required int packageId,
      required dynamic paymentIntent}) async {
    String paymentIntentId = paymentIntent["id"].toString();
    String clientSecret =
        paymentIntent['payment_gateway_response']["client_secret"].toString();

    await StripeService.payWithPaymentSheet(
      context: context,
      merchantDisplayName: Constant.appName,
      amount: paymentIntent["amount"].toString(),
      currency: AppSettings.stripeCurrency,
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
    );
  }

  static Future<void> phonepeCheckSum(
      {required BuildContext context, required dynamic getData}) async {
    PhonePePaymentSdk.init(getData["Phonepe_environment_mode"],
            getData["merchant_id"], getData["appId"], true)
        .then((isInitialized) {
      print("start payment****$isInitialized");
      startPaymentPhonePe(
          context: context,
          jsonData: getData["payload"],
          checksums: getData["checksum"],
          callBackUrl: getData["callback_url"]);
    }).catchError((error) {
      print("error phonepe***${error.toString()}");
      return error;
    });
  }

  static void startPaymentPhonePe(
      {required BuildContext context,
      required Map<String, dynamic> jsonData,
      required String checksums,
      required String callBackUrl}) async {
    try {
      String body = '';
      String base64Data = base64Encode(utf8.encode(jsonEncode(jsonData)));
      body = base64Data;

      PhonePePaymentSdk.startTransaction(
              body, 
              // callBackUrl, checksums, 
              Constant.androidPackageName)
          .then((response) async {
        print("phonepe response***$response");
        print("phone status***${response != null}");
        if (response != null) {
          String status = response['status'].toString();
          print("phone status***45${response['status']}");
          if (status == 'SUCCESS') {
            print("phone status***56${status == 'SUCCESS'}");
            HelperUtils.showSnackBarMessage(
                context, "paymentSuccessfullyCompleted".translate(context));
            print("phone status***67");
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            HelperUtils.showSnackBarMessage(
                context, "purchaseFailed".translate(context),
                type: MessageType.error);
          }
        } else {
          HelperUtils.showSnackBarMessage(
              context, "purchaseFailed".translate(context),
              type: MessageType.error);
        }
      }).catchError((error) {
        HelperUtils.showSnackBarMessage(context, error,
            type: MessageType.error);

        return;
      });
    } catch (error) {}
  }

  static void razorpay(
      {required BuildContext context,
      required price,
      required orderId,
      required packageId}) {
    final Razorpay razorpay = Razorpay();

    var options = {
      'key': AppSettings.razorpayKey,
      'amount': price! * 100,
      'name': HiveUtils.getUserDetails().name ?? "",
      'description': '',
      'order_id': orderId,
      'prefill': {
        'contact': HiveUtils.getUserDetails().mobile ?? "",
        'email': HiveUtils.getUserDetails().email ?? ""
      },
      "notes": {"package_id": packageId, "user_id": HiveUtils.getUserId()},
    };

    if (AppSettings.razorpayKey != "") {
      razorpay.open(options);
      razorpay.on(
        Razorpay.EVENT_PAYMENT_SUCCESS,
        (
          PaymentSuccessResponse response,
        ) async {
          await _purchase(context);
        },
      );
      razorpay.on(
        Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
          HelperUtils.showSnackBarMessage(
              context, "purchaseFailed".translate(context));
        },
      );
      razorpay.on(
        Razorpay.EVENT_EXTERNAL_WALLET,
        (e) {},
      );
    } else {
      HelperUtils.showSnackBarMessage(context, "setAPIkey".translate(context));
    }
  }

  static Future<void> _purchase(BuildContext context) async {
    try {
      Future.delayed(
        Duration.zero,
        () {
          HelperUtils.showSnackBarMessage(context, "success".translate(context),
              type: MessageType.success, messageDuration: 5);

          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } catch (e) {
      HelperUtils.showSnackBarMessage(
          context, "purchaseFailed".translate(context),
          type: MessageType.error);
    }
  }
}
