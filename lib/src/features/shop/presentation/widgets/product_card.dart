import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/format.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/product.dart';
import 'product_image.dart';

/// Two columns on phones, up to five on wide windows. The tile height is the
/// square image plus the text block, so prices line up across a row.
SliverGridDelegate productGridDelegate(BuildContext context, double width) {
  final columns = (width / 220).floor().clamp(2, 5);
  final tile = (width - (columns - 1) * Insets.md) / columns;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: Insets.md,
    mainAxisSpacing: Insets.lg,
    mainAxisExtent: tile + MediaQuery.textScalerOf(context).scale(ProductCard.textBlockHeight),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.action,
    this.cartButton,
    this.heroScope = Routes.shop,
  });

  final Product product;
  final VoidCallback? onTap;
  final String heroScope;

  /// Sits in the image's top-right corner.
  final Widget? action;

  /// Sits to the right of the price and rating.
  final Widget? cartButton;

  /// Height of everything under the square image, before text scaling.
  static const textBlockHeight = 98.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Hero(
                    tag: productHeroTag(product.id, heroScope),
                    child: ExcludeSemantics(child: ProductImage(url: product.thumbnail)),
                  ),
                ),
                if (action != null) Positioned(top: 2, right: 2, child: action!),
              ],
            ),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: p.ink, height: 1.35),
          ),
          const SizedBox(height: Insets.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(formatPrice(context, product.finalPrice), style: theme.textTheme.titleSmall),
                        if (product.isDeal) ...[
                          const SizedBox(width: 6),
                          Text(
                            l10n.percentOff(product.percentOff),
                            style: theme.textTheme.labelSmall?.copyWith(color: p.accent),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    RatingLine(product: product),
                  ],
                ),
              ),
              ?cartButton,
            ],
          ),
        ],
      ),
    );
  }
}

class RatingLine extends StatelessWidget {
  const RatingLine({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final small = Theme.of(context).textTheme.bodySmall;
    final rating = product.rating.toStringAsFixed(1);

    final String? stockNote = !product.inStock
        ? l10n.outOfStock
        : product.stock <= 5
        ? l10n.lowStock(product.stock)
        : null;

    return Row(
      children: [
        Semantics(
          label: l10n.ratingLabel(rating),
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 15, color: p.inkSoft),
              const SizedBox(width: 2),
              Text(rating, style: small),
            ],
          ),
        ),
        if (stockNote != null) ...[
          const SizedBox(width: Insets.sm),
          Flexible(
            child: Text(
              stockNote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: small?.copyWith(color: p.danger),
            ),
          ),
        ],
      ],
    );
  }
}
