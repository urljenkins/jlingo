import 'package:flutter/material.dart';

class MobileScaffold extends StatelessWidget {
  final Widget body;
  final Widget? topBar;
  final Widget? bottomNav;

  const MobileScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomNav,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // The nav draws its own bottom inset, so it sits outside this one.
        bottom: false,
        child: Column(
          children: [
            if (topBar != null) topBar!,
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: bottomNav,
    );
  }
}
