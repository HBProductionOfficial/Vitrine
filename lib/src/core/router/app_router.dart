import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/widgets/biometric_offer.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/shell/home_shell.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // go_router listens to a Listenable, so mirror the auth state into one.
  final authChanges = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => authChanges.value = next);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authChanges,
    redirect: (context, state) {
      final auth = authChanges.value;
      final at = state.matchedLocation;
      return switch (auth) {
        AuthRestoring() => at == Routes.splash ? null : Routes.splash,
        SignedOut() => Routes.signedOutOnly.contains(at) ? null : Routes.login,
        SignedIn() => (at == Routes.splash || Routes.signedOutOnly.contains(at)) ? Routes.shop : null,
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, state) => LoginScreen(prefillDemo: state.uri.queryParameters['demo'] == '1'),
      ),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => BiometricOffer(child: HomeShell(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.shop, builder: (_, _) => const _Placeholder('Shop')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.devices, builder: (_, _) => const DevicesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.cart, builder: (_, _) => const _Placeholder('Cart')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, builder: (_, _) => const _Placeholder('Profile', canSignOut: true)),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
});

// TODO(alex): replace with the real tab screens as they land.
class _Placeholder extends ConsumerWidget {
  const _Placeholder(this.title, {this.canSignOut = false});

  final String title;
  final bool canSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: canSignOut
            ? OutlinedButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              )
            : const Text('Coming soon'),
      ),
    );
  }
}
