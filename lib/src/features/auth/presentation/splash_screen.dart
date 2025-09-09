import 'package:flutter/material.dart';

import '../../../core/widgets/vitrine_mark.dart';

/// Shown for the moment it takes to check for a saved session.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: VitrineMark(size: 72)));
  }
}
