import 'package:auth_wifihouse/models/base_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rest_api.g.dart';

@RestApi(baseUrl: "")
abstract class RestAPI {
  factory RestAPI(Dio dio, {String baseUrl}) = _RestAPI;

  @POST("/auth/login_with_google")
  Future<BaseResponse> googleLogin(@Body() Map<String, dynamic> body);

  @POST("/auth/login_with_facebook")
  Future<BaseResponse> facebookLogin(@Body() Map<String, dynamic> body);

  @POST("/auth/login_with_apple")
  Future<BaseResponse> appleLogin(@Body() Map<String, dynamic> body);

@POST("/auth/login_with_phone")
  Future<BaseResponse> phoneLogin(@Body() Map<String, dynamic> body);

  @PUT("/auth/register")
  Future<BaseResponse> wpRegister(@Body() Map<String, dynamic> body);

  @POST("/auth/login")
  Future<BaseResponse> wpLogin(@Body() Map<String, dynamic> body);

  // Account
  @GET("/user/me")
  Future<BaseResponse> getProfile();
}
