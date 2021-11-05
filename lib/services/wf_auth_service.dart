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

  // Future getCodeWithPhoneNumber(String phoneNumber, String routes) {
  //   showWaitingDialog(Get.context);
  //   return fbAuth.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       timeout: const Duration(seconds: 60),
  //       verificationCompleted: (AuthCredential credential) async {
  //         await fbAuth
  //             .signInWithCredential(credential)
  //             .then((UserCredential authResult) {
  //           if (authResult != null && authResult.user != null) {
  //             print('Authentication successful');
  //             handleAuthResult(authResult.user, routes);
  //           } else {
  //             alertDialog(Get.context,
  //                 title:
  //                     AppLocalizations.of(Get.context).translate("errorTitle"),
  //                 content: "Thất bại" //Keys.invalidPhone.tr
  //                 );
  //           }
  //         }).catchError((error) {
  //           alertDialog(Get.context,
  //               title: AppLocalizations.of(Get.context).translate("errorTitle"),
  //               content: AppLocalizations.of(Get.context)
  //                   .translate("tryAgainError"));
  //         });
  //       },
  //       verificationFailed: (FirebaseAuthException authException) {
  //         // Todo please show error from error object
  //         print('Error message: ' +
  //             authException.code +
  //             "..." +
  //             authException.message);
  //         var errorMessage = authException.message;
  //         if (authException.code == 'too-many-requests') {
  //           errorMessage =
  //               AppLocalizations.of(Get.context).translate('exceedingCode');
  //         }
  //         Get.back();
  //         alertDialog(Get.context,
  //             title: AppLocalizations.of(Get.context).translate("errorTitle"),
  //             content: errorMessage);
  //         // isLoginLoading = false;
  //       },
  //       codeSent: (String verificationId, [int forceResendingToken]) async {
  //         Get.back();
  //         actualCode = verificationId;
  //         //  isLoginLoading = false;
  //         Get.toNamed(Routes.CODE, arguments: {
  //           'phone': phoneNumber,
  //           'verificationId': actualCode,
  //           'routes': routes
  //         });
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         actualCode = verificationId;
  //       });
  // }

  // Future<void> handleAuthResult(User user, String routes) async {
  //   // Todo try to login here
  //   firebaseUser.value = user;
  //   var account = await firebaseService.checkUId(firebaseUser.value.uid);

  //   if (account == null) {
  //     account = Account(
  //         id: firebaseUser.value.uid,
  //         phone: firebaseUser.value.phoneNumber,
  //         email: firebaseUser.value.email,
  //         avatar: firebaseUser.value.photoURL,
  //         progress: {});
  //     // firebaseService.createUser(account);
  //     Get.offAllNamed(Routes.REGISTER_PROFILE, arguments: account);
  //   } else {
  //     accountService.me.value = account;
  //     accountService.resetLocalNotice();
  //     accountService.listenNoticeOfMeChange();
  //     lessonService.syncLessonStatus();
  //     lessonService.syncAllTaskList();
  //     accountService.registerMeChange();

  //     if (routes == "null" || routes == null) {
  //       Get.offAllNamed(Routes.HOME);
  //       showToast(
  //           AppLocalizations.of(Get.context).translate("loginSuccessMessage"));
  //     } else {
  //       Get.offNamedUntil(routes, ModalRoute.withName(routes));
  //       showToast(
  //           AppLocalizations.of(Get.context).translate("loginSuccessMessage"));
  //     }
  //   }
  // }

  // validateOtpAndLogin(
  //     BuildContext context, String smsCode, String routes) async {
  //   //isOtpLoading = true;
  //   final AuthCredential _authCredential = PhoneAuthProvider.credential(
  //       verificationId: actualCode, smsCode: smsCode);
  //   await fbAuth.signInWithCredential(_authCredential).catchError((error) {
  //     print("Lỗi OTP " + error);
  //     //isOtpLoading = false;
  //     Get.back();
  //     alertDialog(context,
  //         title: "OTP",
  //         content: AppLocalizations.of(context).translate("invalidOTP"));
  //   }).then((UserCredential authResult) {
  //     if (authResult != null && authResult.user != null) {
  //       handleAuthResult(authResult.user, routes);
  //     }
  //   });
  // }

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
            response = await client.facebookLogin({"facebookToken": token.token});
            if (response.code == 200) {
              setAccessToken(response.results['token']);
              cacheLoginType(FACEBOOK_LOGIN_TYPE);
            }
          } catch (e) {
            return buildErrorResponse(e.toString());
          }
          return response.toJson();
        } else {
          return null;
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
