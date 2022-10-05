// @dart = 2.12
import 'package:flutter/material.dart' show Widget;
import 'package:we_pei_yang_flutter/home/view/home_page.dart';
import 'package:we_pei_yang_flutter/home/view/map_calender_page.dart';
import 'package:we_pei_yang_flutter/home/view/web_views/fifty_two_hz_page.dart';
import 'package:we_pei_yang_flutter/home/view/web_views/wiki_page.dart';
import 'package:we_pei_yang_flutter/home/view/web_views/notices_page.dart';

class HomeRouter {
  static String home = 'home/home';
  static String wiki = 'home/wiki';
  static String hz = 'home/52hz';
  static String mapCalenderPage = 'home/mapCalenderPage';
  static String restartGame = 'home/restartGame';
  static String notice = 'home/notice';
  static final Map<String, Widget Function(dynamic arguments)> routers = {
    home: (_) => HomePage(),
    wiki: (_) => WikiPage(),
    mapCalenderPage: (_) => MapCalenderPage(),
    hz: (_) => FiftyTwoHzPage(),
    notice:(_) => NoticesPage()
  };
}
