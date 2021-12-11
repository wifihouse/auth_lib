import 'dart:async';
import 'package:auth_wifihouse/common/base_service.dart';
import 'package:auth_wifihouse/common/config.dart';
import 'package:auth_wifihouse/models/base_response.dart';
import 'package:auth_wifihouse/modules/code_input_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'wf_local_service.dart';

enum PhoneAuthStatus {
  code_sent,
  completed,
  timeout,
  register_error,
  phone_number_error,
  invalid_code,
  error,
}

class PhoneAuthResult {
  PhoneAuthResult(this.status, {this.verificationId, this.user, this.error});
  PhoneAuthStatus status;
  String? verificationId;
  dynamic user;
  String? error;
}

class WfAuthService<T> extends BaseService {
  WfLocalService localService;
  WfAuthService({required this.localService});

  GoogleSignIn googleSignIn = GoogleSignIn();
  FacebookAuth _facebookAuth = FacebookAuth.instance;

  String? actualCode;
  String? _accessToken;

  FirebaseAuth get fbAuth => FirebaseAuth.instance;
  User? get currentUser => fbAuth.currentUser;

  final Map cancelResponse = {"code": 100, "message": "Canceled"};
  final Map invalidPhoneResponse = {"code": 101, "message": "Invalid phone"};
  Map buildErrorResponse(String message) {
    return {"code": 500, "message": message};
  }

  setAccessToken(String token) {
    _accessToken = token;
    localService.cacheToken(token);
  }

  cacheLoginType(String type) {
    localService.write(WfLocalService.LOGIN_TYPE, type);
  }

  String? getAccessToken() {
    _accessToken = localService.token;
    if (_accessToken?.isNotEmpty == true) {
      return "Bearer " + _accessToken!;
    }
    return null;
  }

  Future<Map> signInWithGoogle() async {
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    print(googleSignInAccount);
    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;
      final String? token = googleAuth.idToken;
      print('@googleToken $token');
      BaseResponse response;
      try {
        response = await client.googleLogin({"googleToken": token});
        setAccessToken(response.results['token']);
        cacheLoginType(GOOGLE_LOGIN_TYPE);
      } catch (e) {
        return buildErrorResponse(e.toString());
      }
      return response.toJson();
    } else {
      return cancelResponse;
    }
  }

  Future<Map?> signInWithFacebook() async {
    print("isWebSdkInitialized ${this._facebookAuth.isWebSdkInitialized}");
    print(
        "isAutoLogAppEventsEnabled ${await this._facebookAuth.isAutoLogAppEventsEnabled}");
    final LoginResult result = await _facebookAuth.login();

    // final FacebookLoginResult result = await facebookLogin.logIn(['email']);
    // FacebookAccessToken facebookAccessToken = result.accessToken;
    switch (result.status) {
      case LoginStatus.failed:
        return buildErrorResponse(result.message!);
      case LoginStatus.cancelled:
        return cancelResponse;
      case LoginStatus.success:
        var token = await this._facebookAuth.accessToken;
        if (token != null) {
          print('@facebookToken ${token.token}}');
          BaseResponse response;
          try {
            response =
                await client.facebookLogin({"facebookToken": token.token});
            if (response.code == 200) {
              setAccessToken(response.results['token']);
              cacheLoginType(FACEBOOK_LOGIN_TYPE);
            }
          } catch (e) {
            return buildErrorResponse(e.toString());
          }
          return response.toJson();
        } else {
          return buildErrorResponse('Invalid FB token');
        }
      default:
    }
    return null;
  }

  Future<bool> supportAppleSignin() {
    return SignInWithApple.isAvailable();
  }

  Future<Map> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final String? token = credential.identityToken;
    print('@appleToken $token');

    BaseResponse response;
    try {
      response = await client.appleLogin({"appleToken": token});
      setAccessToken(response.results['token']);
      cacheLoginType(APPLE_LOGIN_TYPE);
    } catch (e) {
      return buildErrorResponse(e.toString());
    }
    return response.toJson();
  }

  Future<PhoneAuthResult> confirmCodeV2(
      String verificationId, String code) async {
    final credential = await PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    try {
      final res = await _parseFirebaseToken(credential);
      return PhoneAuthResult(PhoneAuthStatus.completed, user: res);
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          return PhoneAuthResult(PhoneAuthStatus.invalid_code);
        }
        return PhoneAuthResult(PhoneAuthStatus.error, error: e.toString());
      }
      return PhoneAuthResult(PhoneAuthStatus.error, error: e.toString());
    }
  }

  void siginInWithPhoneV2(
      String phoneNumber, Function(PhoneAuthResult) onData) {
    FirebaseAuth.instance.verifyPhoneNumber(
      timeout: Duration(seconds: 120),
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final res = await _parseFirebaseToken(credential);
          final completeResponse =
              PhoneAuthResult(PhoneAuthStatus.completed, user: res);
          onData(completeResponse);
        } catch (e) {
          final errorResponse = PhoneAuthResult(PhoneAuthStatus.register_error,
              error: e.toString());
          onData(errorResponse);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          final errorResponse =
              PhoneAuthResult(PhoneAuthStatus.phone_number_error);
          onData(errorResponse);
        } else {
          final errorResponse =
              PhoneAuthResult(PhoneAuthStatus.error, error: e.toString());
          onData(errorResponse);
        }
      },
      codeSent: (verificationId, resendToken) {
        final response = PhoneAuthResult(PhoneAuthStatus.code_sent,
            verificationId: verificationId);
        onData(response);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        final errorResponse = PhoneAuthResult(PhoneAuthStatus.timeout);
        onData(errorResponse);
      },
    );
  }

  Future<dynamic> signInWithPhone(String phoneNumber) {
    Completer completer = Completer<Map>();
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final res = await _parseFirebaseToken(credential);
          completer.complete(res);
        } catch (e) {
          completer.complete(buildErrorResponse(e.toString()));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          completer.complete(invalidPhoneResponse);
        } else {
          completer.complete(buildErrorResponse(e.toString()));
        }
      },
      codeSent: (verificationId, resendToken) {
        Navigator.push(
            Get.context!,
            new MaterialPageRoute(
              builder: (BuildContext context) => CodeInputDialog(
                  title: 'Verify phone number',
                  phone: phoneNumber,
                  cancelPressed: () {
                    completer.complete(cancelResponse);
                    Get.back();
                  },
                  confirmCodePressed: (code) async {
                    PhoneAuthCredential credential =
                        PhoneAuthProvider.credential(
                            verificationId: verificationId, smsCode: code);
                    final res = await _parseFirebaseToken(credential);
                    completer.complete(res);
                  },
                  resendPressed: () {
                    // Todo plz handle this case
                  }),
              // fullscreenDialog: true,
            ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("@phoneauth timeout");
      },
    );

    return completer.future;
  }

  Future<Map> _parseFirebaseToken(PhoneAuthCredential credential) async {
    UserCredential authResult = await fbAuth.signInWithCredential(credential);
    String token = await authResult.user!.getIdToken();
    print("@phonetoken $token");

    BaseResponse response;
    try {
      response = await client.phoneLogin({"firebaseToken": token});
      setAccessToken(response.results['token']);
      cacheLoginType(PHONE_LOGIN_TYPE);
    } catch (e) {
      return buildErrorResponse(e.toString());
    }
    return response.toJson();
  }

  Future signOut() async {
    String loginType = localService.read(WfLocalService.LOGIN_TYPE);
    switch (loginType) {
      case GOOGLE_LOGIN_TYPE:
        await googleSignIn.signOut();
        break;
      case FACEBOOK_LOGIN_TYPE:
        _facebookAuth.logOut();
        break;
      case APPLE_LOGIN_TYPE:
        print("@nothing!");
        break;
      case PHONE_LOGIN_TYPE:
        break;
    }
    localService.cacheToken("");
    cacheLoginType("");
    return Future;
  }
}
