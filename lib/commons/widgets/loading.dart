// @dart = 2.12
import 'dart:math';

import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final Color? dotOneColor;
  final Color? dotTwoColor;
  final Color? dotThreeColor;
  final Duration duration;
  final DotType dotType;
  final Icon dotIcon;

  const Loading({
    this.dotOneColor,
    this.dotTwoColor,
    this.dotThreeColor,
    this.duration = const Duration(seconds: 1),
    this.dotType = DotType.circle,
    this.dotIcon = const Icon(Icons.adjust),
    Key? key,
  }) : super(key: key);

  @override
  _LoadingState createState() => _LoadingState();
}

extension LoadingDotsColors on ThemeData {
  Color get dotOneColor => const Color(0xFF3884DE);
  Color get dotTwoColor => const Color(0xFF8DBBF1);
  Color get dotThreeColor => const Color(0xFF156ACE);
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late Animation<double> animation_1;
  late Animation<double> animation_2;
  late Animation<double> animation_3;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: widget.duration, vsync: this);

    animation_1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.70, curve: Curves.linear),
      ),
    );

    animation_2 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.1, 0.80, curve: Curves.linear),
      ),
    );

    animation_3 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.2, 0.90, curve: Curves.linear),
      ),
    );

    controller.addListener(() {
      setState(() {});
    });

    controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final dotOneColor = widget.dotOneColor ?? Theme.of(context).dotOneColor;
    final dotTwoColor = widget.dotOneColor ?? Theme.of(context).dotTwoColor;
    final dotThreeColor = widget.dotOneColor ?? Theme.of(context).dotThreeColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Opacity(
          opacity: (animation_1.value <= 0.4
              ? 2.5 * animation_1.value
              : (animation_1.value > 0.40 && animation_1.value <= 0.60)
                  ? 1.0
                  : 2.5 - (2.5 * animation_1.value)),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Dot(
              radius: 10.0,
              color: dotOneColor,
              type: widget.dotType,
              icon: widget.dotIcon,
            ),
          ),
        ),
        Opacity(
          opacity: (animation_2.value <= 0.4
              ? 2.5 * animation_2.value
              : (animation_2.value > 0.40 && animation_2.value <= 0.60)
                  ? 1.0
                  : 2.5 - (2.5 * animation_2.value)),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Dot(
              radius: 10.0,
              color: dotTwoColor,
              type: widget.dotType,
              icon: widget.dotIcon,
            ),
          ),
        ),
        Opacity(
          opacity: (animation_3.value <= 0.4
              ? 2.5 * animation_3.value
              : (animation_3.value > 0.40 && animation_3.value <= 0.60)
                  ? 1.0
                  : 2.5 - (2.5 * animation_3.value)),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Dot(
              radius: 10.0,
              color: dotThreeColor,
              type: widget.dotType,
              icon: widget.dotIcon,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class Dot extends StatelessWidget {
  final double? radius;
  final Color? color;
  final DotType? type;
  final Icon? icon;

  const Dot({
    this.radius,
    this.color,
    this.type,
    this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: type == DotType.icon
          ? Icon(
              icon!.icon,
              color: color,
              size: 1.3 * radius!,
            )
          : Transform.rotate(
              angle: type == DotType.diamond ? pi / 4 : 0.0,
              child: Container(
                width: radius,
                height: radius,
                decoration: BoxDecoration(
                    color: color,
                    shape: type == DotType.circle
                        ? BoxShape.circle
                        : BoxShape.rectangle),
              ),
            ),
    );
  }
}

enum DotType { square, circle, diamond, icon }
