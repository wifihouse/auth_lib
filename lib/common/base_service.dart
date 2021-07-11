import 'package:auth_wifihouse/auth_config.dart';
import 'package:auth_wifihouse/common/rest_api.dart';
import 'package:auth_wifihouse/services/wf_auth_service.dart';
import 'package:auth_wifihouse/utils/net_utils.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class BaseService extends GetxService {
  late RestAPI client;
  final dio = Dio();

  @override
  void onInit() {
    dio.interceptors.add(LogInterceptor(
        responseHeader: false,
        responseBody: true,
        request: true,
        requestBody: true,
        logPrint: NetUtils.printCustom));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      dio.interceptors.requestLock.lock();
      WfAuthService authService = Get.find();
      final token = authService.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = token;
      }
      print(options.headers);
      dio.interceptors.requestLock.unlock();
      handler.next(options);
    }));
    AuthConfig config = Get.find();
    client = RestAPI(dio, baseUrl: config.host ?? "http://localhost:4000");
    super.onInit();
  }
}
