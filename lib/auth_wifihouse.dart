import 'dart:async';
import 'package:auth_wifihouse/auth_config.dart';
import 'package:auth_wifihouse/services/wf_auth_service.dart';
import 'package:auth_wifihouse/services/wf_local_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/instance_manager.dart';

class AuthWifihouse {
  static const MethodChannel _channel = const MethodChannel('auth_wifihouse');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static void init({required AuthConfig config}) {
     FacebookAuth.instance.webInitialize(
      appId: config.facebookId ?? '',
      cookie: true,
      xfbml: true,
      version: "v11.0",
    );
    Get.put<AuthConfig>(config, permanent: true);
    Get.put<WfLocalService>(WfLocalService(), permanent: true);
    Get.put<WfAuthService>(WfAuthService(localService: Get.find()),
        permanent: true);
  }

  static WfAuthService get authService => Get.find();
}
