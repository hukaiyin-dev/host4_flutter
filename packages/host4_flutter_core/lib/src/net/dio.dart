

import 'package:dio/dio.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加拦截器
    dio.interceptors.add(_buildInterceptor());
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  InterceptorsWrapper _buildInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 统一处理响应
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // 统一错误处理
        _handleError(e);
        return handler.next(e);
      },
    );
  }

  void _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        print('连接超时');
        break;
      case DioExceptionType.receiveTimeout:
        print('响应超时');
        break;
      case DioExceptionType.badResponse:
        print('服务器错误: ${e.response?.statusCode}');
        break;
      case DioExceptionType.cancel:
        print('请求已取消');
        break;
      default:
        print('未知错误: ${e.message}');
    }
  }
}