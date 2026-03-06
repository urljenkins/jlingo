import 'package:flutter/material.dart';

class DesktopScaffold extends StatelessWidget {
  final Widget body;
  final Widget? sideNav;
  final Widget? topBar;

  const DesktopScaffold({
    super.key,
    required this.body,
    this.sideNav,
    this.topBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sideNav != null)
            SizedBox(
              width: 250,
              child: sideNav,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (topBar != null) topBar!,
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
