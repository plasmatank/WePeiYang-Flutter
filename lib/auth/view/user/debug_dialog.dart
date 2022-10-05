import 'package:flutter/material.dart';
import 'package:we_pei_yang_flutter/commons/util/router_manager.dart';
import 'package:we_pei_yang_flutter/commons/util/text_util.dart';
import 'package:we_pei_yang_flutter/generated/l10n.dart';

class DebugDialog extends Dialog {
  static final _hintStyle = TextUtil.base.bold.noLine
      .sp(15)
      .customColor(Color.fromRGBO(98, 103, 123, 1));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color.fromRGBO(237, 240, 244, 1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text("确定要进入日志页面吗？",
                style: TextUtil.base.normal.noLine
                    .sp(13)
                    .customColor(Color.fromRGBO(79, 88, 107, 1))),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    child: Text(S.current.cancel, style: _hintStyle),
                  ),
                ),
                SizedBox(width: 30),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AuthRouter.debug),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    child: Text(S.current.ok, style: _hintStyle),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
