// @dart=2.9
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:get_storage/get_storage.dart';

class WfLocalService extends GetxService {
  static const String CONSUMER_KEY = "_consumerKey";
  static const String CONSUMER_SECRET = "_consumerSecret";
  static const String FIREBASE_UUID = "_firebaseUUID";
  static const String USER_PHONE_NUMBER = "_userPhoneNumber";
  static const String COUNT_CLICK_ON = "_countClickOn";
  static const String POSITION_SCROLL = "_positionScroll";
  static const String NOTIFICATION = "_notification";
  static const String FIRST_TIME_USE = "_firstTimeUse";
  static const String NOTICE_SEEN = "_noticeSeen";
  static const String URL_INTRO = "_urlIntro";

  static const String LOGIN_TYPE = "_loginType";

  GetStorage _storage;

  GetStorage get box {
    if (_storage == null) {
      _storage = GetStorage();
    }
    return _storage;
  }

  Future get init => box.initStorage;

  void cacheToken(String token) {
    box.write('_token', token);
  }

  void write(String key, String value) {
    box.write(key, value);
  }

  bool isFistTimeUse() {
    bool v = box.read(FIRST_TIME_USE);
    return v == null;
  }

  Future setUsed() {
    return box.write(FIRST_TIME_USE, false);
  }

  String read(String key) => box.read(key);
  bool has(String key) => box.hasData(key);

  String get token => box.read('_token');
}
