import 'package:auth_wifihouse/common/base_service.dart';
import 'package:auth_wifihouse/common/config.dart';
import 'package:auth_wifihouse/models/base_response.dart';
import 'package:auth_wifihouse/modules/code_input_dialog.dart';
import 'package:auth_wifihouse/utils/net_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'wf_local_service.dart';

class WfAuthService<T> extends BaseService {
  String _accessToken;
  GoogleSignIn googleSignIn = GoogleSignIn();
  FacebookLogin facebookLogin = FacebookLogin();

  WfLocalService localService;
  String actualCode;
  FirebaseAuth get fbAuth => FirebaseAuth.instance;
  var firebaseUser = Rx<User>();
  User get currentUser => fbAuth.currentUser;
  WfAuthService({@required this.localService});

  setAccessToken(String token) {
    _accessToken = token;
    localService.cacheToken(token);
  }

  cacheLoginType(String type) {
    localService.write(WfLocalService.LOGIN_TYPE, type);
  }

  String getAccessToken() {
    _accessToken = localService.token;
    if (_accessToken?.isNotEmpty == true) {
      return "Bearer " + _accessToken;
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
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;
      final String token = googleAuth.idToken;
      print('@googleToken $token');
      BaseResponse response = await client.googleLogin({"googleToken": token});
      setAccessToken(response.results['token']);
      cacheLoginType(GOOGLE_LOGIN_TYPE);
      return response.toJson();
    }
    return null;
  }

  Future<Map> signInWithFacebook() async {
    final FacebookLoginResult result = await facebookLogin.logIn(['email']);
    FacebookAccessToken facebookAccessToken = result.accessToken;
    switch (result.status) {
      case FacebookLoginStatus.error:
        return throw Exception("Login error");
        // alertDialog(Get.context,
        //     title: Keys.notificationTitle.tr,
        //     content: Keys.loginFailMessage.tr);
        // // print("Error");
        // // return null;
        break;
      case FacebookLoginStatus.cancelledByUser:
        return throw Exception("Cancelled");
      // print("CancelledByUser");
      // break;
      case FacebookLoginStatus.loggedIn:
        final String token = facebookAccessToken.token;
        print('@facebookToken $token');
        BaseResponse response =
            await client.googleLogin({"facebookToken": token});
        setAccessToken(response.results['token']);
        cacheLoginType(FACEBOOK_LOGIN_TYPE);
        return response.toJson();
    }
    return null;
  }

  Future<Map> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final String token = credential.identityToken;
    print('@appleToken $token');
    BaseResponse response = await client.googleLogin({"appleToken": token});
    setAccessToken(response.results['token']);
    cacheLoginType(APPLE_LOGIN_TYPE);
    return response.toJson();
  }

  Future signInWithPhone(
      String phoneNumber, Function(Map) completed, Function(int code) error) {
    return FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final res = await _parseFirebaseToken(credential);
          completed(res);
        } catch (e) {
          error(1);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        return throw Exception("Verify error $e");
      },
      codeSent: (String verificationId, int resendToken) {
        Navigator.push(
            Get.context,
            new MaterialPageRoute(
              builder: (BuildContext context) => CodeInputDialog(
                  title: 'Verify phone number',
                  phone: phoneNumber,
                  cancelPressed: () {
                    error(0);
                    Get.back();
                  },
                  confirmCodePressed: (code) async {
                    try {
                      PhoneAuthCredential credential =
                          PhoneAuthProvider.credential(
                              verificationId: verificationId, smsCode: code);
                      final res = await _parseFirebaseToken(credential);
                      completed(res);
                    } catch (e) {
                      error(1);
                    }
                  },
                  resendPressed: () {}),
              // fullscreenDialog: true,
            ));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("@phoneauth timeout");
      },
    );
  }

  Future<Map> _parseFirebaseToken(PhoneAuthCredential credential) async {
    UserCredential authResult = await fbAuth.signInWithCredential(credential);
    String token = await authResult.user.getIdToken();
    print("@phonetoken $token");

    BaseResponse response = await client.phoneLogin({"firebaseToken": token});
    setAccessToken(response.results['token']);
    cacheLoginType(PHONE_LOGIN_TYPE);
    return response.toJson();
  }

  Future signOut() async {
    String loginType = localService.read(WfLocalService.LOGIN_TYPE);
    switch (loginType) {
      case GOOGLE_LOGIN_TYPE:
        await googleSignIn.signOut();
        break;
      case FACEBOOK_LOGIN_TYPE:
        facebookLogin.logOut();
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
