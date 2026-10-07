import 'package:flutter/material.dart';

import '../../routes/app_navigate.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.scaffoldKey,
    this.showAppbar = true,
    this.title,
    this.titleWidget,
    this.body,
    this.showhamburger = false,
    this.leading,
    this.trailings,
    this.fullscreen = true,
    this.backgroundColor = Colors.white,
    this.foregroundColor,
    this.back = true,
    this.backWidget,
    this.appbarColor = Colors.white,
    this.elevation = 0,
    this.leadingWidth,
    this.onBackPress,
  });

  final bool showAppbar;
  final String? title;
  final Widget? titleWidget;
  final Widget? body;
  final bool showhamburger;
  final Widget? leading;
  final List<Widget>? trailings;
  final bool fullscreen;
  final Color backgroundColor;
  final Color? foregroundColor;
  final Color? appbarColor;
  final bool back;
  final Widget? backWidget;
  final double? elevation;
  final double? leadingWidth;
  final VoidCallback? onBackPress;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      centerTitle: true,
      leadingWidth: (leading == null && showhamburger == false)
          ? 44
          : leadingWidth,
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: appbarColor,
      titleSpacing: 8,
      title: titleWidget != null ? titleWidget! : Text(title ?? ''),
      leading: leading != null
          ? leading!
          : back
          ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (onBackPress != null) {
                  onBackPress?.call();
                } else {
                  AppNavigate.instance.back();
                }
              },
            )
          : backWidget ?? const SizedBox.shrink(),
      actions: trailings ?? [const SizedBox(width: 36, height: 10)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(color: Colors.black, height: 0.5),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(showAppbar ? 44 : 0),
        child: appBar,
      ),
      body: SafeArea(bottom: !fullscreen, child: body ?? Container()),
    );
  }
}
