import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/widgets/biometric_offer.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/orders/presentation/order_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/fade_through_branches.dart';
import '../../features/shell/home_shell.dart';
import '../../features/shop/presentation/product_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';
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
      StatefulShellRoute(
        builder: (context, state, shell) => BiometricOffer(child: HomeShell(shell: shell)),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughBranches(currentIndex: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.shop,
                builder: (_, _) => const ShopScreen(),
                routes: [
                  _productRoute(Routes.shop),
                  GoRoute(path: 'saved', builder: (_, _) => const SavedScreen(), routes: [_productRoute(Routes.saved)]),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.devices, builder: (_, _) => const DevicesScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.cart, builder: (_, _) => const CartScreen(), routes: [_productRoute(Routes.cart)]),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
                  GoRoute(
                    path: 'orders',
                    builder: (_, _) => const OrdersScreen(),
                    routes: [
                      GoRoute(
                        path: ':ref',
                        builder: (_, state) => OrderScreen(orderRef: state.pathParameters['ref']!),
                        routes: [_productRoute(Routes.orders)],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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

/// The product page, nested under whichever tab opened it.
GoRoute _productRoute(String scope) {
  return GoRoute(
    path: 'product/:id',
    builder: (_, state) => ProductScreen(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0, heroScope: scope),
  );
}
