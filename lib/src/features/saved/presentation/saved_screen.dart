import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/tokens.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/presentation/widgets/quick_add_button.dart';
import '../../shop/presentation/widgets/product_card.dart';
import 'save_button.dart';
import 'saved_controller.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(savedProvider);

    return Scaffold(
      // The grid below has no padding of its own, hence the extra page insets.
      appBar: PageAppBar(maxWidth: Breakpoints.contentMaxWidth + 2 * Insets.page, title: Text(l10n.savedTitle)),
      body: saved.isEmpty
          ? MessageView(icon: Icons.favorite_border_rounded, title: l10n.savedEmptyTitle, message: l10n.savedEmptyBody)
          : LayoutBuilder(
              builder: (context, constraints) {
                final gutter = pageGutter(constraints.maxWidth);
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(gutter, Insets.sm, gutter, Insets.xl),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) => SliverGrid(
                          gridDelegate: productGridDelegate(context, constraints.crossAxisExtent),
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final product = saved[i];
                            return FadeSlideIn(
                              delay: FadeSlideIn.stagger(i),
                              child: ProductCard(
                                product: product,
                                heroScope: Routes.saved,
                                action: SaveButton(product: product),
                                cartButton: QuickAddButton(product: product),
                                onTap: () => context.push(Routes.product(product.id, from: Routes.saved)),
                              ),
                            );
                          }, childCount: saved.length),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
