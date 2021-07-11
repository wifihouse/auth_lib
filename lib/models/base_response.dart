import 'package:json_annotation/json_annotation.dart';
part 'base_response.g.dart';

@JsonSerializable()
class BaseResponse<T> {
  int code;
  String? message;
  dynamic results;

  BaseResponse({required this.code, this.message, required this.results});

  factory BaseResponse.fromJson(Map<String, dynamic> json) =>
      _$BaseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BaseResponseToJson(this);

  List<T> parseList<T>(T Function(Map map) jsonConvertor) {
    List items = results["objects"]["rows"];
    return items.map((element) {  return jsonConvertor(element); }).toList();
  }
}