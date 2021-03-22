import 'package:flutter/material.dart';
import 'package:wei_pei_yang_demo/lounge/lounge_router.dart';
import 'package:wei_pei_yang_demo/schedule/schedule_router.dart';
import 'package:wei_pei_yang_demo/gpa/gpa_router.dart';
import 'package:wei_pei_yang_demo/home/home_router.dart';

class CardBean {
  IconData icon;
  String label;
  String route;

  CardBean(this.icon, this.label, this.route);
}

class GlobalModel {
  GlobalModel._() {
    cards.add(CardBean(Icons.event, '课程表', ScheduleRouter.schedule));
    cards.add(CardBean(Icons.timeline, 'GPA', GPARouter.gpa));
    // cards.add(CardBean(Icons.call, '黄页', HomeRouter.telNum));
    cards
        .add(CardBean(Icons.calendar_today_outlined, "自习室", LoungeRouter.main));
  }

  static final _instance = GlobalModel._();

  factory GlobalModel() => _instance;

  double screenWidth;
  double screenHeight;
  int captchaIndex = 0;
  final List<CardBean> cards = [];

  void increase() => captchaIndex++;
}
