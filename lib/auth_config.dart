import 'dart:async';

import 'package:auth_wifihouse/services/wf_auth_service.dart';
import 'package:auth_wifihouse/services/wf_local_service.dart';
import 'package:flutter/services.dart';
import 'package:get/instance_manager.dart';

class AuthConfig {
  String? host;

  AuthConfig({this.host});
}
