import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../core/design/tokens.dart';
import '../cart/presentation/cart_controller.dart';

/// Bottom navigation on phones, a rail on wider screens. The branches keep
/// their own navigation stacks, so switching tabs doesn't lose scroll
/// position or an open product page.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(cartProvider.select((c) => c.count));
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium;

    final destinations = [
      (Icons.storefront_outlined, Icons.storefront_rounded, l10n.tabShop),
      (Icons.devices_other_outlined, Icons.devices_other_rounded, l10n.tabDevices),
      (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, l10n.tabCart),
      (Icons.person_outline_rounded, Icons.person_rounded, l10n.tabProfile),
    ];

    Widget icon(int i, IconData data) {
      if (i != 2 || cartCount == 0) return Icon(data);
      return Badge.count(count: cartCount, child: Icon(data));
    }

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (i, d) in destinations.indexed)
                  NavigationRailDestination(icon: icon(i, d.$1), selectedIcon: icon(i, d.$2), label: Text(d.$3)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final (i, d) in destinations.indexed)
            NavigationDestination(icon: icon(i, d.$1), selectedIcon: icon(i, d.$2), label: d.$3),
        ],
      ),
    );
  }
}
