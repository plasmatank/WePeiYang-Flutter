import 'package:flutter/material.dart';

class DaTab extends StatefulWidget {
  @required
  final String text;
  @required
  final bool withDropDownButton;

  const DaTab({Key key, this.text, this.withDropDownButton})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DaTabState();
  }
}

class _DaTabState extends State<DaTab> {
  _DaTabState();

  @override
  Widget build(BuildContext context) {
    var _tabPaddingWidth = MediaQuery.of(context).size.width / 30;
    return widget.withDropDownButton
        ? Tab(
            child: Row(
              children: [
                SizedBox(width: _tabPaddingWidth),
                Text(widget.text),
                Icon(
                  Icons.arrow_drop_down,
                  size: 10,
                ),
                if (_tabPaddingWidth > 10)
                  SizedBox(width: _tabPaddingWidth - 10)
              ],
            ),
          )
        : Tab(
            child: Row(
            children: [
              SizedBox(width: _tabPaddingWidth),
              Text(widget.text),
              SizedBox(width: _tabPaddingWidth),
            ],
          ));
  }
}
