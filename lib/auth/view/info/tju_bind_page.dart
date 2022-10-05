import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mutex/mutex.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:we_pei_yang_flutter/auth/view/info/unbind_dialogs.dart';
import 'package:we_pei_yang_flutter/commons/network/classes_service.dart';
import 'package:we_pei_yang_flutter/commons/preferences/common_prefs.dart';
import 'package:we_pei_yang_flutter/commons/util/router_manager.dart';
import 'package:we_pei_yang_flutter/commons/util/text_util.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/feedback/util/color_util.dart';
import 'package:we_pei_yang_flutter/generated/l10n.dart';
import 'package:we_pei_yang_flutter/gpa/model/gpa_notifier.dart';
import 'package:we_pei_yang_flutter/schedule/model/course_provider.dart';
import 'package:we_pei_yang_flutter/schedule/model/exam_provider.dart';

class TjuBindPage extends StatefulWidget {
  final String routeAfterBind; // 绑定成功后跳转至的路由

  TjuBindPage([this.routeAfterBind]);

  @override
  _TjuBindPageState createState() => _TjuBindPageState();
}

class _TjuBindPageState extends State<TjuBindPage> {
  String tjuuname = "";
  String tjupasswd = "";
  String captcha = "";

  TextEditingController nameController;
  TextEditingController pwController;
  TextEditingController codeController;
  final GlobalKey<CaptchaWidgetState> captchaKey = GlobalKey();
  CaptchaWidget captchaWidget;

  @override
  void initState() {
    captchaWidget = CaptchaWidget(captchaKey);
    codeController = TextEditingController();
    if (CommonPreferences.isBindTju.value) {
      super.initState();
      return;
    }
    tjuuname = CommonPreferences.tjuuname.value == ''
        ? CommonPreferences.account.value
        : CommonPreferences.tjuuname.value;
    tjupasswd = CommonPreferences.tjupasswd.value;
    nameController =
        TextEditingController.fromValue(TextEditingValue(text: tjuuname));
    pwController =
        TextEditingController.fromValue(TextEditingValue(text: tjupasswd));
    super.initState();
  }

  @override
  void dispose() {
    nameController?.dispose();
    pwController?.dispose();
    codeController?.dispose();
    super.dispose();
  }

  void _bind() {
    if (tjuuname == "" || tjupasswd == "" || captcha == "") {
      var message = "";
      if (tjuuname == "")
        message = "用户名不能为空";
      else if (tjupasswd == "")
        message = "密码不能为空";
      else
        message = "验证码不能为空";
      ToastProvider.error(message);
      return;
    }
    ClassesService.login(context, tjuuname, tjupasswd, captcha, onSuccess: () {
      ToastProvider.success("办公网绑定成功");
      ToastProvider.running('数据加载中');
      var gpaProvider = Provider.of<GPANotifier>(context, listen: false);
      var courseProvider = Provider.of<CourseProvider>(context, listen: false);
      var examProvider = Provider.of<ExamProvider>(context, listen: false);
      Future.sync(() async {
        var mtx = Mutex();
        await mtx.acquire();
        // TODO: 重定向错误不知道怎么忽略，多请求一次课程表是可以的，同时把GPA放在课程表
        // 前面，防止刷到辅修成绩的bug情况。此外在判断是否刷新时，去掉了来自课程表页面的
        // 多刷新课程表总能刷出来，所以不判断了，之后要重新对一遍办公网的登录流程
        // 这里provider先拿出来，页面pop掉就没了
        if (widget.routeAfterBind != GPARouter.gpa) {
          gpaProvider.refreshGPA(
            onSuccess: () {
              mtx.release();
            },
            onFailure: (e) {
              mtx.release();
            },
          );
        }
        await mtx.acquire();
        courseProvider.refreshCourse(
          onSuccess: () {
            mtx.release();
          },
          onFailure: (e) {
            mtx.release();
          },
        );

        await mtx.acquire();
        if (widget.routeAfterBind != ScheduleRouter.exam) {
          examProvider.refreshExam(
            onSuccess: () {
              mtx.release();
            },
            onFailure: (e) {
              mtx.release();
            },
          );
        }
        await mtx.acquire();
        courseProvider.refreshCourse(
          onSuccess: () {
            mtx.release();
          },
          onFailure: (e) {
            mtx.release();
          },
        );
      });
      if (widget.routeAfterBind != null) {
        Navigator.pushReplacementNamed(context, widget.routeAfterBind);
        return;
      }
      setState(() {
        tjuuname = "";
        tjupasswd = "";
        nameController = null;
        pwController = null;
      });
    }, onFailure: (e) {
      if (e.error.toString() == '网络连接超时') e.error = '请连接校园网后再次尝试';
      ToastProvider.error(e.error.toString());
      captchaKey.currentState.refresh();
    });
    codeController.clear();
  }

  final FocusNode _accountFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _notRobotFocus = FocusNode();

  final visNotifier = ValueNotifier<bool>(true); // 是否隐藏密码

  Widget _detail(BuildContext context) {
    var hintStyle = TextUtil.base.regular
        .sp(13)
        .customColor(Color.fromRGBO(201, 204, 209, 1));
    if (CommonPreferences.isBindTju.value)
      return Column(children: [
        SizedBox(height: 30),
        Text("${S.current.bind_account}: ${CommonPreferences.tjuuname.value}",
            style: TextUtil.base.bold
                .sp(15)
                .customColor(Color.fromRGBO(79, 88, 107, 1))),
        SizedBox(height: 60),
        SizedBox(
          height: 50,
          width: 120,
          child: ElevatedButton(
            onPressed: () => showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) => TjuUnbindDialog())
                .then((_) => this.setState(() {})),
            child: Text(S.current.unbind,
                style: TextUtil.base.regular.white.sp(13)),
            style: ButtonStyle(
              elevation: MaterialStateProperty.all(3),
              overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.pressed))
                  return Color.fromRGBO(103, 110, 150, 1.0);
                return Color.fromRGBO(79, 88, 107, 1);
              }),
              backgroundColor:
                  MaterialStateProperty.all(Color.fromRGBO(79, 88, 107, 1)),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ]);
    else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(children: [
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              S.current.tju_bind_hint,
              textAlign: TextAlign.center,
              style: TextUtil.base.regular
                  .sp(10)
                  .customColor(Color.fromRGBO(98, 103, 124, 1)),
            ),
          ),
          SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 55),
            child: TextField(
              textInputAction: TextInputAction.next,
              controller: nameController,
              focusNode: _accountFocus,
              cursorColor: ColorUtil.mainColor,
              decoration: InputDecoration(
                  hintText: S.current.tju_account,
                  hintStyle: hintStyle,
                  filled: true,
                  fillColor: Color.fromRGBO(235, 238, 243, 1),
                  isCollapsed: true,
                  contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none)),
              onChanged: (input) => setState(() => tjuuname = input),
              onTap: () {
                nameController?.clear();
                nameController = null;
              },
              onEditingComplete: () {
                _accountFocus.unfocus();
                FocusScope.of(context).requestFocus(_passwordFocus);
              },
            ),
          ),
          SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 55),
            child: ValueListenableBuilder(
              valueListenable: visNotifier,
              builder: (context, value, _) {
                return Theme(
                  data: Theme.of(context)
                      .copyWith(primaryColor: Color.fromRGBO(53, 59, 84, 1)),
                  child: TextField(
                    keyboardType: TextInputType.visiblePassword,
                    controller: pwController,
                    focusNode: _passwordFocus,
                    cursorColor: ColorUtil.mainColor,
                    decoration: InputDecoration(
                      hintText: S.current.password,
                      hintStyle: hintStyle,
                      filled: true,
                      fillColor: Color.fromRGBO(235, 238, 243, 1),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      suffixIcon: GestureDetector(
                        child: Icon(
                          value ? Icons.visibility_off : Icons.visibility,
                          color: ColorUtil.mainColor,
                        ),
                        onTap: () {
                          visNotifier.value = !visNotifier.value;
                        },
                      ),
                    ),
                    obscureText: value,
                    onChanged: (input) => setState(() => tjupasswd = input),
                    onTap: () {
                      pwController?.clear();
                      pwController = null;
                    },
                    onEditingComplete: () {
                      _accountFocus.unfocus();
                      FocusScope.of(context).requestFocus(_notRobotFocus);
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 55,
                  width: 120,
                  child: TextField(
                    controller: codeController,
                    focusNode: _notRobotFocus,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        hintText: S.current.captcha,
                        hintStyle: hintStyle,
                        filled: true,
                        fillColor: Color.fromRGBO(235, 238, 243, 1),
                        isCollapsed: true,
                        contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none)),
                    onChanged: (input) => setState(() => captcha = input),
                    onEditingComplete: () {
                      _notRobotFocus.unfocus();
                    },
                  ),
                ),
              ),
              SizedBox(width: 20),
              SizedBox(height: 55, width: 120, child: captchaWidget)
            ],
          ),
          SizedBox(height: 25),
          SizedBox(
            height: 50,
            width: 400,
            child: ElevatedButton(
              onPressed: _bind,
              child: Text(S.current.bind,
                  style: TextUtil.base.regular.white.sp(13)),
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(5),
                overlayColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.pressed))
                    return Color.fromRGBO(103, 110, 150, 1);
                  return Color.fromRGBO(53, 59, 84, 1);
                }),
                backgroundColor:
                    MaterialStateProperty.all(Color.fromRGBO(53, 59, 84, 1)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
              ),
            ),
          ),
          SizedBox(height: 35),
          Text(
            '应学校要求，校外使用教育教学信息管理系统需先登录天津大学VPN，'
            '故在校外访问微北洋课表、GPA功能也需登录VPN绑定办公网账号后使用。',
            style: TextUtil.base.regular
                .sp(10)
                .customColor(Color.fromRGBO(98, 103, 124, 1)),
          ),
          Row(
            children: [
              Text(
                '办公网网址为 ',
                style: TextUtil.base.regular
                    .sp(10)
                    .customColor(Color.fromRGBO(98, 103, 124, 1)),
              ),
              GestureDetector(
                onTap: () async {
                  String url = 'http://classes.tju.edu.cn/';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    ToastProvider.error('请检查网络状态');
                  }
                },
                child: Text('classes.tju.edu.cn',
                    style: TextUtil.base.regular.blue363C.underLine.sp(10)),
              ),
            ],
          ),
          SizedBox(height: 35),
        ]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Color.fromRGBO(250, 250, 250, 1),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: GestureDetector(
                child: Icon(Icons.arrow_back,
                    color: Color.fromRGBO(53, 59, 84, 1), size: 32),
                onTap: () => Navigator.pop(context)),
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(35, 10, 20, 50),
                  child: Text(S.current.tju_bind,
                      style: TextUtil.base.bold
                          .sp(28)
                          .customColor(Color.fromRGBO(48, 60, 102, 1))),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 22, 0, 50),
                  child: Text(
                      CommonPreferences.isBindTju.value
                          ? S.current.is_bind
                          : S.current.not_bind,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            /// 已绑定/未绑定时三个图标的高度不一样，所以加个间隔控制一下
            SizedBox(height: CommonPreferences.isBindTju.value ? 20 : 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/tju_work.png',
                    height: 50, width: 50),
                SizedBox(width: 20),
                Image.asset('assets/images/bind.png', height: 25, width: 25),
                SizedBox(width: 20),
                Image.asset('assets/images/twt_round.png',
                    height: 50, width: 50),
              ],
            ),
            _detail(context)
          ],
        ),
      ),
    );
  }
}

class CaptchaWidget extends StatefulWidget {
  CaptchaWidget(Key key) : super(key: key);

  @override
  State<CaptchaWidget> createState() => CaptchaWidgetState();
}

class CaptchaWidgetState extends State<CaptchaWidget> {
  void refresh() async {
    id += 0.001;
    try {
      await ClassesService.cookieJar.deleteAll();
    } catch (_) {}
    var res = await ClassesService.fetch(
        "https://sso.tju.edu.cn/cas/images/kaptcha.jpg?id=${id}",
        options: Options(responseType: ResponseType.bytes));
    setState(() {
      data = res.data;
    });
  }

  Uint8List data;
  double id = 0.001;

  @override
  void initState() {
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: refresh,
        child:
            data == null ? CupertinoActivityIndicator() : Image.memory(data));
  }
}
