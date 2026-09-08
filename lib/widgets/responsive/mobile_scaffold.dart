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
        // A nav draws its own bottom inset, so it sits outside this one.
        // Without one, the body is what meets the gesture bar and keyboard,
        // and has to keep clear of them itself.
        bottom: bottomNav == null,
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
