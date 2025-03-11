import 'dart:developer';
import 'dart:io';

import 'package:eClassify/utils/login/apple_login/apple_login.dart';
import 'package:eClassify/utils/login/email_login/email_login.dart';
import 'package:eClassify/utils/login/google_login/google_login.dart';
import 'package:eClassify/utils/login/lib/login_status.dart';
import 'package:eClassify/utils/login/lib/login_system.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/login/phone_login/phone_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthenticationType {
  email,
  google,
  apple,
  phone;
}

abstract class AuthenticationState {}

class AuthenticationInitial extends AuthenticationState {}

class AuthenticationInProcess extends AuthenticationState {
  final AuthenticationType type;

  AuthenticationInProcess(this.type);
}

class AuthenticationSuccess extends AuthenticationState {
  final AuthenticationType type;
  final UserCredential credential;
  final LoginPayload payload;

  AuthenticationSuccess(this.type, this.credential, this.payload);
}

class AuthenticationFail extends AuthenticationState {
  final dynamic error;

  AuthenticationFail(this.error);
}

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit() : super(AuthenticationInitial());
  AuthenticationType? type;
  LoginPayload? payload;
  MMultiAuthentication mMultiAuthentication = MMultiAuthentication({
    "google": GoogleLogin(),
    "email": EmailLogin(),
    if (Platform.isIOS) "apple": AppleLogin(),
    "phone": PhoneLogin()
  });

  void init() {
    mMultiAuthentication.init();
  }

  void setData(
      {required LoginPayload payload, required AuthenticationType type}) {
    this.type = type;
    this.payload = payload;
  }



  void authenticate() async {
    print("auth type***$type****$payload");
    if (type == null && payload == null) {
      return;
    }

    try {
      emit(AuthenticationInProcess(type!));
      mMultiAuthentication.setActive(type!.name);
      mMultiAuthentication.payload = MultiLoginPayload({
        type!.name: payload!,
      });

      UserCredential? credential = await mMultiAuthentication.login();


      LoginPayload? payloadData = (payload);
      print("payloadData***$payloadData");

      if (payloadData is EmailLoginPayload &&
          payloadData.type == EmailLoginType.login) {
        User? user = credential!.user;
        if (user != null && !user.emailVerified) {
          // Handle the case when the user's email is not verified
          emit(AuthenticationFail("Please verify your email first."));
        } else {
          emit(AuthenticationSuccess(type!, credential, payload!));
        }
      } else {
        print('emit auth success');
        emit(AuthenticationSuccess(type!, credential!, payload!));
      }
    }  on FirebaseAuthException catch (e) {
      log(e.toString());

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage =
          "There is no user record corresponding to this identifier. The user may have been deleted.";
          break;
        case 'wrong-password':
          errorMessage =
          "The password is invalid or the user does not have a password.";
          break;
        case 'invalid-email':
          errorMessage = "The email address is badly formatted.";
          break;
        case 'user-disabled':
          errorMessage =
          "The user account has been disabled by an administrator.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many requests. Try again later.";
          break;
        case 'operation-not-allowed':
          errorMessage =
          "This operation is not allowed. Please contact support.";
          break;
        default:
          errorMessage = "An unexpected error occurred. Please try again.";
          break;
      }
      print("Firebase auth error: ${e.code} - ${e.message}");
      emit(AuthenticationFail(errorMessage));

    }  catch (e, stack) {
      print("auth catch***${e.toString()}");
      log(e.toString());
      log('$stack');
      emit(AuthenticationFail(e));
    }
  }

  void listen(Function(MLoginState state) fn) {
    mMultiAuthentication.listen(fn);
  }

  void verify() {
    mMultiAuthentication.setActive(type!.name);
    mMultiAuthentication.payload = MultiLoginPayload({
      type!.name: payload!,
    });
    mMultiAuthentication.requestVerification();
  }

  void signOut() {
    if (state is AuthenticationSuccess) {
      final isGoogleLogin =
          (state as AuthenticationSuccess).type == AuthenticationType.google;
      if (isGoogleLogin) {
        final googleLogin = mMultiAuthentication.systems['google'];

        (googleLogin as GoogleLogin).signOut();

        emit(AuthenticationInitial());
      }
    }
  }
}
