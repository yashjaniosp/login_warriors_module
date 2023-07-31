import 'package:customwarriorlogin/data/api/base_api.dart';
import 'package:dio/dio.dart';

abstract class IAuthenticationApi {
  Future<ApiDataResponse<LoginTokenDto>> login(
      String userName, String password);
}

class AuthenticationApi extends BaseApi implements IAuthenticationApi {
  AuthenticationApi(Dio dio) : super(dio);

  @override
  Future<ApiDataResponse<LoginTokenDto>> login(
      String userName, String password) async {
    return await wrapDataCall(() async {
      var response = await dio.post("/oauth2/token",
          data: {
            'password': password,
            'grant_type': "client_credentials",
            'username': userName
          },
          options: Options(contentType: Headers.formUrlEncodedContentType));
      return OkData(LoginTokenDto.fromJson(response.data));
    });
  }
}

class LoginTokenDto {
  String accessToken;
  String refreshToken;
  LoginTokenDto({required this.accessToken, required this.refreshToken});

  factory LoginTokenDto.fromJson(Map<String, dynamic> json) {
    return LoginTokenDto(
        accessToken: json['access_token'], refreshToken: json['refresh_token']);
  }
}
