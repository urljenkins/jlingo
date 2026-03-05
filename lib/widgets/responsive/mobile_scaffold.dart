import 'package:flutter/material.dart';

class MobileScaffold extends StatelessWidget {
  final Widget body;
  final Widget? topBar;

  const MobileScaffold({
    super.key,
    required this.body,
    this.topBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (topBar != null) topBar!,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
