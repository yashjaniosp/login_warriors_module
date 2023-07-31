import 'dart:io';

import 'package:dio/dio.dart';

typedef ApiCall = Future<ApiResponse> Function();
typedef ApiDataCall<T> = Future<ApiDataResponse<T>> Function();

abstract class BaseApi {
  late Dio dio;
  BaseApi(this.dio);

  Future<ApiResponse> wrapDatacall(ApiCall call, {Function? onError}) async {
    try {
      return await call.call();
    } on DioException catch (e) {
      onError?.call();
      if (e.response?.data != null &&
          e.response?.data is Map<String, dynamic>) {
        var errorDto = ErrorDto.fromJson(e.response?.data);
        e.response!.statusMessage =
            errorDto.message ?? e.response!.statusMessage;
      }
      if (e.response?.statusCode == HttpStatus.unauthorized) {
        return Bad(
            HttpStatus.unauthorized, "Token expired, Please login again.");
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return Bad(HttpStatus.requestTimeout,
            e.response?.statusMessage ?? "Unable to connect to endpoint");
      }
      return Bad(
          e.response?.statusCode ?? HttpStatus.connectionClosedWithoutResponse,
          e.response?.statusMessage ?? "Unable to connect to endpoint");
    } catch (e) {
      onError?.call();
      return Bad(
          HttpStatus.internalServerError, "Unable to connect to endpoint");
    }
  }
}

Future<ApiDataResponse<TData>> wrapDataCall<TData>(ApiDataCall<TData> call,
    {Function? onError}) async {
  try {
    return await call.call();
  } on DioException catch (e) {
    onError?.call(e);
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      var errorDto = ErrorDto.fromJson(e.response?.data);
      e.response!.statusMessage = errorDto.message ?? e.response!.statusMessage;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return BadData(HttpStatus.requestTimeout,
          e.response?.statusMessage ?? "Unable to connect to endpoint");
    }
    if (e.response?.statusCode == HttpStatus.unauthorized) {
      return BadData(
          HttpStatus.unauthorized, "Token expired, Please login again.");
    }
    return BadData(
        e.response?.statusCode ?? HttpStatus.connectionClosedWithoutResponse,
        e.response?.statusMessage ?? "Unable to connect to endpoint");
  } catch (e) {
    onError?.call(e);
    return BadData(
        HttpStatus.internalServerError, "Unable to connect to endpoint");
  }
}

class ApiResponse {}

class OK extends ApiResponse {}

class Bad extends ApiResponse {
  final int statusCode;
  final String message;

  Bad(this.statusCode, this.message);
}

abstract class ApiDataResponse<TDto> {
  late int statusCode;
}

class OkData<TDto> extends ApiDataResponse<TDto> {
  final TDto dto;

  OkData(this.dto, {int statusCode = 200}) {
    this.statusCode = statusCode;
  }
}

class BadData<TDto> extends ApiDataResponse<TDto> {
  final String message;

  BadData(int statusCode, this.message) {
    this.statusCode = statusCode;
  }
}

class ErrorDto {
  String? message;

  ErrorDto({this.message});

  ErrorDto.fromJson(Map<String, dynamic> json) {
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    return data;
  }
}
