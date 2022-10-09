import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:we_pei_yang_flutter/commons/environment/config.dart';
import 'package:we_pei_yang_flutter/commons/extension/extensions.dart';
import 'package:we_pei_yang_flutter/commons/preferences/common_prefs.dart';
import 'package:we_pei_yang_flutter/commons/util/dialog_provider.dart';
import 'package:we_pei_yang_flutter/commons/util/level_util.dart';
import 'package:we_pei_yang_flutter/commons/util/text_util.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/commons/widgets/wpy_pic.dart';
import 'package:we_pei_yang_flutter/feedback/feedback_router.dart';
import 'package:we_pei_yang_flutter/feedback/model/feedback_notifier.dart';
import 'package:we_pei_yang_flutter/feedback/network/feedback_service.dart';
import 'package:we_pei_yang_flutter/feedback/network/post.dart';
import 'package:we_pei_yang_flutter/feedback/view/components/widget/clip_copy.dart';
import 'package:we_pei_yang_flutter/feedback/view/components/widget/icon_widget.dart';
import 'package:we_pei_yang_flutter/feedback/view/components/widget/long_text_shower.dart';
import 'package:we_pei_yang_flutter/feedback/view/components/widget/round_taggings.dart';
import 'package:we_pei_yang_flutter/feedback/view/reply_detail_page.dart';
import 'package:we_pei_yang_flutter/feedback/view/report_question_page.dart';
import 'package:we_pei_yang_flutter/generated/l10n.dart';
import 'package:we_pei_yang_flutter/main.dart';

typedef LikeCallback = void Function(bool, int);
typedef DislikeCallback = void Function(bool);

class NCommentCard extends StatefulWidget {
  final String ancestorName;
  final int ancestorUId;
  final Floor comment;
  final int uid;
  final int commentFloor;
  final int type;
  final LikeCallback likeSuccessCallback;
  final DislikeCallback dislikeSuccessCallback;
  final bool isSubFloor;
  final bool isFullView;
  final bool showBlockButton;

  @override
  _NCommentCardState createState() => _NCommentCardState();

  NCommentCard({
    this.ancestorName,
    this.ancestorUId,
    this.comment,
    this.uid,
    this.commentFloor,
    this.likeSuccessCallback,
    this.dislikeSuccessCallback,
    this.isSubFloor,
    this.isFullView,
    this.type,
    this.showBlockButton = false,
  });
}

class _NCommentCardState extends State<NCommentCard>
    with SingleTickerProviderStateMixin {
  ScrollController _sc;

  //final String picBaseUrl = 'https://qnhdpic.twt.edu.cn/download/';
  final String picBaseUrl = '${EnvConfig.QNHDPIC}download/';
  bool _picFullView = false, _isDeleted = false;

  Future<bool> _showDeleteConfirmDialog(String quote) {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return LakeDialogWidget(
              title: '$quote评论',
              content: Text('您确定要$quote这条评论吗？'),
              cancelText: "取消",
              confirmTextStyle:
                  TextUtil.base.normal.black2A.NotoSansSC.sp(16).w400,
              cancelTextStyle:
                  TextUtil.base.normal.black2A.NotoSansSC.sp(16).w600,
              confirmText: quote == '摧毁' ? 'BOOM' : "确认",
              cancelFun: () {
                Navigator.of(context).pop();
              },
              confirmFun: () {
                Navigator.of(context).pop(true);
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    var commentMenuButton = GestureDetector(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 4.w, 8.w, 12.w),
          child: SvgPicture.asset(
            'assets/svg_pics/lake_butt_icons/more_horizontal.svg',
            width: 18.w,
            color: Colors.black,
          ),
        ),
        onTap: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) {
              return CupertinoActionSheet(
                actions: <Widget>[
                  // 拉黑按钮
                  if (Platform.isIOS && widget.showBlockButton)
                    // 分享按钮
                    CupertinoActionSheetAction(
                      onPressed: () {
                        ToastProvider.success('拉黑用户成功');
                        Navigator.pop(context);
                      },
                      child: Text(
                        '拉黑',
                        style:
                            TextUtil.base.normal.w400.NotoSansSC.black00.sp(16),
                      ),
                    ),
                  // 分享按钮
                  CupertinoActionSheetAction(
                    onPressed: () {
                      String weCo =
                          '我在微北洋发现了个有趣的问题评论，你也来看看吧~\n将本条微口令复制到微北洋求实论坛打开问题 wpy://school_project/${widget.comment.postId}\n【${widget.comment.content}】';
                      ClipboardData data = ClipboardData(text: weCo);
                      Clipboard.setData(data);
                      CommonPreferences.feedbackLastWeCo.value =
                          widget.ancestorUId.toString();
                      ToastProvider.success('微口令复制成功，快去给小伙伴分享吧！');
                      FeedbackService.postShare(
                          id: widget.ancestorUId.toString(),
                          type: 0,
                          onSuccess: () {},
                          onFailure: () {});
                    },
                    child: Text(
                      '分享',
                      style:
                          TextUtil.base.normal.w400.NotoSansSC.black00.sp(16),
                    ),
                  ),

                  CupertinoActionSheetAction(
                    onPressed: () {
                      ClipboardData data =
                          ClipboardData(text: widget.comment.content);
                      Clipboard.setData(data);
                      ToastProvider.success('复制成功');
                      Navigator.pop(context);
                    },
                    child: Text(
                      '复制',
                      style:
                          TextUtil.base.normal.w400.NotoSansSC.black00.sp(16),
                    ),
                  ),
                  widget.comment.isOwner
                      ? CupertinoActionSheetAction(
                          onPressed: () async {
                            bool confirm = await _showDeleteConfirmDialog('删除');
                            if (confirm) {
                              FeedbackService.deleteFloor(
                                id: widget.comment.id,
                                onSuccess: () {
                                  ToastProvider.success(
                                      S.current.feedback_delete_success);
                                  setState(() {
                                    _isDeleted = true;
                                  });
                                },
                                onFailure: (e) {
                                  ToastProvider.error(e.error.toString());
                                },
                              );
                            }
                            Navigator.pop(context);
                          },
                          child: Text(
                            '删除',
                            style: TextUtil.base.normal.w400.NotoSansSC.black00
                                .sp(16),
                          ),
                        )
                      : CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pushNamed(context, FeedbackRouter.report,
                                arguments: ReportPageArgs(
                                    widget.ancestorUId, false,
                                    floorId: widget.comment.id));
                          },
                          child: Text(
                            '举报',
                            style: TextUtil.base.normal.w400.NotoSansSC.black00
                                .sp(16),
                          ),
                        ),
                  if ((CommonPreferences.isSuper.value ||
                          CommonPreferences.isStuAdmin.value) ??
                      false)
                    CupertinoActionSheetAction(
                      onPressed: () async {
                        bool confirm = await _showDeleteConfirmDialog('摧毁');
                        if (confirm) {
                          FeedbackService.adminDeleteReply(
                            floorId: widget.comment.id,
                            onSuccess: () {
                              ToastProvider.success(
                                  S.current.feedback_delete_success);
                              setState(() {
                                _isDeleted = true;
                              });
                            },
                            onFailure: (e) {
                              ToastProvider.error(e.error.toString());
                            },
                          );
                        }
                      },
                      child: Text(
                        '删评',
                        style:
                            TextUtil.base.normal.w400.NotoSansSC.black00.sp(16),
                      ),
                    ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  // 取消按钮
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextUtil.base.normal.w400.NotoSansSC.black00.sp(16),
                  ),
                ),
              );
            },
          );
        });

    var topWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 0.37.sw),
                child: Text(
                  widget.comment.nickname ?? "匿名用户",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextUtil.base.w400.bold.NotoSansSC.sp(16).black2A,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 3),
                child: LevelUtil(
                  width: 24,
                  height: 12,
                  style: TextUtil.base.white.bold.sp(7),
                  level: widget.comment.level.toString(),
                ),
              ),
              if (widget.comment.isOwner != null)
                CommentIdentificationContainer(
                    widget.comment.isOwner
                        ? '我的评论'
                        : widget.comment.uid == widget.uid
                            ? widget.isSubFloor &&
                                    widget.comment.nickname ==
                                        widget.ancestorName
                                ? '楼主 层主'
                                : '楼主'
                            : widget.isSubFloor &&
                                    widget.comment.nickname ==
                                        widget.ancestorName
                                ? '层主'
                                : '',
                    true),
              //回复自己那条时出现
              if (widget.comment.replyToName != '' &&
                  widget.comment.replyTo != widget.ancestorUId)
                widget.comment.isOwner &&
                        widget.comment.replyToName == widget.comment.nickname
                    ? CommentIdentificationContainer('回复我', true)
                    : SizedBox(),
              //后面有东西时出现
              if (widget.comment.replyToName != '' &&
                  widget.comment.replyTo != widget.ancestorUId)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 2),
                    Icon(Icons.play_arrow, size: 10),
                    SizedBox(width: 2),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 0.37.sw),
                      child: Text(
                        widget.comment.replyToName ?? "",
                        style: TextUtil.base.w700.NotoSansSC.sp(16).black2A,
                      ),
                    ),
                    SizedBox(width: 2)
                  ],
                ),
              //回的是楼主并且楼主不是层主或者楼主是层主的时候回复的不是这条评论
              //回的是层主但回复的不是这条评论
              if (widget.comment.isOwner != null &&
                  !widget.comment.isOwner &&
                  widget.comment.replyToName != widget.comment.nickname)
                CommentIdentificationContainer(
                    widget.isSubFloor
                        ? widget.comment.replyToName == 'Owner' &&
                                (widget.ancestorName != 'Owner' ||
                                    (widget.ancestorName == 'Owner' &&
                                        widget.comment.replyTo !=
                                            widget.ancestorUId))
                            ? widget.comment.replyToName ==
                                        widget.ancestorName &&
                                    widget.comment.replyTo != widget.ancestorUId
                                ? '楼主 层主'
                                : '楼主'
                            : widget.comment.replyToName ==
                                        widget.ancestorName &&
                                    widget.comment.replyTo != widget.ancestorUId
                                ? '层主'
                                : ''
                        : '',
                    false),
              // if (widget.isSubFloor &&
              //     widget.comment.replyTo != widget.ancestorUId)
              //   CommentIdentificationContainer(
              //       '回复ID：' + widget.comment.replyTo.toString(), false),
            ],
          ),
        ),
        SizedBox(width: 22.w),
      ],
    );

    var commentContent = widget.comment.content == ''
        ? SizedBox()
        : ClipCopy(
            id: widget.comment.id,
            copy: widget.comment.content,
            toast: '复制评论成功',
            child: ExpandableText(
              text: widget.comment.content,
              maxLines: !widget.isFullView && widget.isSubFloor ? 3 : 8,
              style: TextUtil.base.w400.NotoSansSC.black2A.h(1.8).sp(14),
              expand: false,
              buttonIsShown: true,
              isHTML: false,
              replyTo: widget.comment.replyToName,
            ),
          );

    var commentImage = Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: AnimatedSize(
          duration: Duration(milliseconds: 150),
          curve: Curves.decelerate,
          child: widget.comment.content != ''
              ? InkWell(
                  onTap: () {
                    setState(() {
                      _picFullView = true;
                    });
                  },
                  child: _picFullView
                      ? InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                                context, FeedbackRouter.imageView,
                                arguments: {
                                  "urlList": [widget.comment.imageUrl],
                                  "urlListLength": 1,
                                  "indexNow": 0
                                });
                          },
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxHeight: WePeiYangApp.screenWidth * 2),
                            child: WpyPic(
                              picBaseUrl + 'origin/' + widget.comment.imageUrl,
                              withHolder: true,
                              holderHeight: 64.h,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                child: WpyPic(
                                  picBaseUrl +
                                      'thumb/' +
                                      widget.comment.imageUrl,
                                  width: 70.w,
                                  height: 68.h,
                                  fit: BoxFit.cover,
                                  withHolder: true,
                                )),
                            Spacer()
                          ],
                        ))
              : _picFullView
                  ? InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, FeedbackRouter.imageView,
                            arguments: {
                              "urlList": [widget.comment.imageUrl],
                              "urlListLength": 1,
                              "indexNow": 0
                            });
                      },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: WePeiYangApp.screenWidth * 2),
                        child: WpyPic(
                          picBaseUrl + 'origin/' + widget.comment.imageUrl,
                          withHolder: true,
                          holderHeight: 64.h,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _picFullView = true;
                            });
                          },
                          child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                              child: WpyPic(
                                picBaseUrl + 'thumb/' + widget.comment.imageUrl,
                                width: 70.w,
                                height: 68.h,
                                fit: BoxFit.cover,
                                withHolder: true,
                              )),
                        ),
                        Expanded(
                            child: GestureDetector(
                                onTap: () {
                                  if (Provider.of<NewFloorProvider>(context,
                                          listen: false)
                                      .inputFieldEnabled) {
                                    Provider.of<NewFloorProvider>(context,
                                            listen: false)
                                        .clearAndClose();
                                  } else {
                                    Provider.of<NewFloorProvider>(context,
                                            listen: false)
                                        .inputFieldOpenAndReplyTo(
                                            widget.comment.id);
                                    FocusScope.of(context).requestFocus(
                                        Provider.of<NewFloorProvider>(context,
                                                listen: false)
                                            .focusNode);
                                  }
                                },
                                child: Container(height: 68.h, color: Colors.transparent)))
                      ],
                    ),
        ));

    var subFloor;
    if (widget.comment.subFloors != null && !widget.isSubFloor) {
      subFloor = ListView.custom(
        key: Key('nCommentCardView'),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        controller: _sc,
        childrenDelegate: SliverChildBuilderDelegate(
          (context, index) {
            return NCommentCard(
              uid: widget.uid,
              ancestorName: widget.comment.nickname,
              ancestorUId: widget.comment.id,
              comment: widget.comment.subFloors[index],
              commentFloor: index + 1,
              isSubFloor: true,
              isFullView: widget.isFullView,
            );
          },
          childCount: widget.isFullView
              ? widget.comment.subFloorCnt
              : widget.comment.subFloorCnt > 4
                  ? 4
                  : min(widget.comment.subFloorCnt,
                      widget.comment.subFloors.length),
          findChildIndexCallback: (key) {
            final ValueKey<String> valueKey = key;
            return widget.comment.subFloors
                .indexWhere((m) => 'ncm-${m.id}' == valueKey.value);
          },
        ),
      );
    }

    var likeWidget = IconWidget(IconType.like, count: widget.comment.likeCount,
        onLikePressed: (isLiked, count, success, failure) async {
      await FeedbackService.commentHitLike(
        id: widget.comment.id,
        isLike: widget.comment.isLike,
        onSuccess: () {
          widget.comment.isLike = !widget.comment.isLike;
          widget.comment.likeCount = count;
          if (widget.comment.isLike && widget.comment.isDis) {
            widget.comment.isDis = !widget.comment.isDis;
            setState(() {});
          }
          success.call();
        },
        onFailure: (e) {
          ToastProvider.error(e.error.toString());
          failure.call();
        },
      );
    }, isLike: widget.comment.isLike ?? false);

    var dislikeWidget = DislikeWidget(
      size: 15.w,
      isDislike: widget.comment.isDis ?? false,
      onDislikePressed: (dislikeNotifier) async {
        await FeedbackService.commentHitDislike(
          id: widget.comment.id,
          isDis: widget.comment.isDis,
          onSuccess: () {
            widget.comment.isDis = !widget.comment.isDis;
            if (widget.comment.isDis && widget.comment.isLike) {
              widget.comment.isLike = !widget.comment.isLike;
              widget.comment.likeCount--;
              setState(() {});
            }
          },
          onFailure: (e) {
            ToastProvider.error(e.error.toString());
          },
        );
      },
    );

    var likeAndDislikeWidget = [likeWidget, dislikeWidget];

    var bottomWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...likeAndDislikeWidget,
        Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 4.0, bottom: 1.0),
          child: Text(
            DateTime.now().difference(widget.comment.createAt).inHours >= 11
                ? widget.comment.createAt
                    .toLocal()
                    .toIso8601String()
                    .replaceRange(10, 11, ' ')
                    .replaceAllMapped('-', (_) => '/')
                    .substring(2, 19)
                : DateTime.now()
                    .difference(widget.comment.createAt)
                    .dayHourMinuteSecondFormatted(),
            style: TextUtil.base.ProductSans.grey97.regular
                .sp(12)
                .space(letterSpacing: 0.6),
          ),
        ),
      ],
    );

    var mainBody = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 34,
        height: 34,
        child: ProfileImageWithDetailedPopup(
          widget.comment.id,
            false,
            widget.type,
            widget.comment.avatar ?? widget.comment.nickname,
            widget.comment.uid,
            widget.comment.nickname,
            widget.comment.level.toString()),
      ),
      SizedBox(width: 10.w),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            topWidget,
            SizedBox(height: 6),
            commentContent,
            if (widget.comment.imageUrl != '') commentImage,
            _picFullView == true
                ? TextButton(
                    style: ButtonStyle(
                        alignment: Alignment.topRight,
                        padding: MaterialStateProperty.all(EdgeInsets.zero)),
                    onPressed: () {
                      setState(() {
                        _picFullView = false;
                      });
                    },
                    child: Row(
                      children: [
                        Spacer(),
                        Text('收起',
                            style: TextUtil.base.greyA8.w800.NotoSansSC.sp(12)),
                      ],
                    ))
                : SizedBox(height: 8),
            SizedBox(height: 2),
            bottomWidget,
            SizedBox(height: 4)
          ],
        ),
      )
    ]);

    return _isDeleted
        ? SizedBox(height: 1)
        : Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 14.w, 12.h),
                    color: Colors.transparent,
                    child: mainBody,
                  ),
                  if (!widget.isSubFloor &&
                      !widget.isFullView &&
                      subFloor != null)
                    Padding(
                        padding: EdgeInsets.only(left: 44.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            subFloor,
                            if (widget.comment.subFloorCnt > 0)
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    FeedbackRouter.commentDetail,
                                    arguments: ReplyDetailPageArgs(
                                        widget.comment, widget.uid),
                                  );
                                },
                                child: Row(
                                  children: [
                                    SizedBox(width: 58.w),
                                    // 这里的 padding 是用于让查看全部几条回复的部分与点赞图标对齐
                                    Text(
                                        widget.comment.subFloorCnt > 2
                                            ? '查看全部 ' +
                                                widget.comment.subFloorCnt
                                                    .toString() +
                                                ' 条回复 >'
                                            : '查看回复详情 >',
                                        style: TextUtil.base.NotoSansSC.w400
                                            .sp(12)
                                            .blue2C),
                                    Spacer()
                                  ],
                                ),
                              ),
                            SizedBox(height: 12.h)
                          ],
                        )),
                ],
              ),
              Positioned(right: 8.w, child: commentMenuButton)
            ],
          );
  }
}
