import 'package:flutter/material.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/format.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/product.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap, this.action});

  final Product product;
  final VoidCallback? onTap;

  /// Sits in the image's top-right corner.
  final Widget? action;

  /// Height of everything under the square image, before text scaling.
  static const textBlockHeight = 94.0;

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
                    tag: productHeroTag(product.id),
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
              Text(formatPrice(context, product.finalPrice), style: theme.textTheme.titleSmall),
              if (product.isDeal) ...[
                const SizedBox(width: 6),
                Text(l10n.percentOff(product.percentOff), style: theme.textTheme.labelSmall?.copyWith(color: p.accent)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          RatingLine(product: product),
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
        if (stockNote != null)
          Flexible(
            child: Text(
              '  ·  $stockNote',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: small?.copyWith(color: p.danger),
            ),
          ),
      ],
    );
  }
}
