import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/home_shell.dart';

abstract final class Routes {
  static const shop = '/shop';
  static const devices = '/devices';
  static const cart = '/cart';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.shop,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.shop, builder: (_, _) => const _Placeholder('Shop')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.devices, builder: (_, _) => const _Placeholder('Devices')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.cart, builder: (_, _) => const _Placeholder('Cart')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, builder: (_, _) => const _Placeholder('Profile')),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

// TODO(alex): replace with the real tab screens as they land.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
