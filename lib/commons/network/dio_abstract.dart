// @dart = 2.12
part of 'wpy_dio.dart';

/// [OnSuccess]和[OnResult]均为请求成功；[OnFailure]为请求失败
typedef OnSuccess = void Function();
typedef OnResult<T> = void Function(T data);
typedef OnFailure = void Function(DioError e);

// TODO: 是否考虑删除 abstract ，这样有些简单使用的地方就不用再继承一个类了？
abstract class DioAbstract {
  String baseUrl = '';
  Map<String, String>? headers;
  List<InterceptorsWrapper> interceptors = [];
  ResponseType responseType = ResponseType.json;

  late final Dio _dio;

  late final Dio _dio_debug;

  DioAbstract() {
    BaseOptions options = BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: 10000,
        receiveTimeout: 10000,
        responseType: responseType,
        headers: headers);
    _dio = Dio()
      ..options = options
      ..interceptors.add(NetCheckInterceptor())
      ..interceptors.addAll(interceptors)
      ..interceptors.add(ErrorInterceptor());
    _dio_debug = Dio()
      ..options = options
      ..interceptors.add(NetCheckInterceptor())
      ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true))
      ..interceptors.addAll(interceptors)
      ..interceptors.add(ErrorInterceptor());
  }

// 不要删除！！！！
// 配置 fiddler 代理
// (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
//     (HttpClient client) {
//   client.findProxy = (uri) {
//     //proxy all request to localhost:8888
//     return 'PROXY 192.168.1.104:8888';
//   };
//   client.badCertificateCallback =
//       (X509Certificate cert, String host, int port) => true;
//   return client;
// };
}

extension DioRequests on DioAbstract {
  /// 普通的[get]、[post]、[put]与[download]方法，返回[Response]
  Future<Response<dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      bool debug = false}) {
    return (debug ? _dio_debug : _dio)
        .get(path, queryParameters: queryParameters, options: options)
        .catchError((error, stack) {
      Logger.reportError(error, stack);
      throw error;
    });
  }

  Future<Response<dynamic>> post(String path,
      {Map<String, dynamic>? queryParameters,
      FormData? formData,
      data,
      Options? options,
      bool debug = false}) {
    return (debug ? _dio_debug : _dio)
        .post(path,
            queryParameters: queryParameters,
            data: formData ?? data,
            options: options)
        .catchError((error, stack) {
      Logger.reportError(error, stack);
      throw error;
    });
  }

  Future<Response<dynamic>> put(String path,
      {Map<String, dynamic>? queryParameters, bool debug = false}) {
    return (debug ? _dio_debug : _dio)
        .put(path, queryParameters: queryParameters)
        .catchError((error, stack) {
      Logger.reportError(error, stack);
      throw error;
    });
  }

  Future<Response<dynamic>> download(String urlPath, String savePath,
      {ProgressCallback? onReceiveProgress,
      Options? options,
      bool debug = false}) {
    return (debug ? _dio_debug : _dio)
        .download(urlPath, savePath,
            onReceiveProgress: onReceiveProgress, options: options)
        .catchError((error, stack) {
      Logger.reportError(error, stack);
      throw error;
    });
  }
}
