// @dart = 2.12
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:path/path.dart' as p;
import 'package:we_pei_yang_flutter/commons/extension/extensions.dart';
import 'package:we_pei_yang_flutter/commons/network/cookie_manager.dart';
import 'package:we_pei_yang_flutter/commons/network/wpy_dio.dart';
import 'package:we_pei_yang_flutter/commons/preferences/common_prefs.dart';
import 'package:we_pei_yang_flutter/commons/util/storage_util.dart';

class _SpiderDio extends DioAbstract {
  static final cookieJar = PersistCookieJar(
      storage: FileStorage(p.join(StorageUtil.tempDir.path, 'cookie')));
  @override
  List<InterceptorsWrapper> interceptors = [
    CookieManager(cookieJar),
    ClassesErrorInterceptor()
  ];
}

class ClassesService {
  /// 登录总流程：获取session与 execution -> 填写captcha -> 进行sso登录
  static void login(
      BuildContext context, String name, String pw, String captcha,
      {required OnSuccess onSuccess, required OnFailure onFailure}) async {
    try {
      /// 登录sso
      final execution = await _getExecution();
      await _ssoLogin(name, pw, captcha, execution);

      /// 获取classes的cookies
      // await _getClassesCookies(tgc);

      CommonPreferences.tjuuname.value = name;
      CommonPreferences.tjupasswd.value = pw;
      CommonPreferences.isBindTju.value = true;
      onSuccess();
    } on DioError catch (e) {
      onFailure(e);
    }
  }

  /// 退出登录
  static void logout() async {
    await fetch("http://classes.tju.edu.cn/eams/logoutExt.action");
    await _SpiderDio.cookieJar.deleteAll();
  }

  /// 获取包含 session、execution 的 map
  static Future<String> _getExecution() async {
    var response = await fetch("https://sso.tju.edu.cn/cas/login");
    return response.data.toString().find(r'name="execution" value="(\w+)"');
  }

  /// 进行sso登录
  static Future<dynamic> _ssoLogin(
      String name, String pw, String captcha, String execution) async {
    await fetch("https://sso.tju.edu.cn/cas/login", isPost: true, params: {
      "username": name,
      "password": pw,
      "captcha": captcha,
      "execution": execution,
      "_eventId": "submit"
    });
    return;
  }

  static final _spiderDio = _SpiderDio();

  static CookieJar get cookieJar => _SpiderDio.cookieJar;

  /// 负责爬虫请求的方法
  static Future<Response<dynamic>> fetch(String url,
      {String? cookie,
      List<String>? cookieList,
      Map<String, dynamic>? params,
      bool isPost = false,
      Options? options}) {
    if (isPost) {
      if (options == null)
        options = Options(
            contentType: Headers.formUrlEncodedContentType,
            followRedirects: false);
      else {
        options.contentType = Headers.formUrlEncodedContentType;
        options.followRedirects = false;
      }
      return _spiderDio.post(url, data: params, options: options);
    } else
      return _spiderDio.get(url, queryParameters: params, options: options);
  }
}
