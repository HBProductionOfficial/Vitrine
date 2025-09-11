import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/palette.dart';
import '../../../../core/design/tokens.dart';

/// [scope] keeps two grids showing the same product (shop and saved) from
/// trading heroes with each other.
Object productHeroTag(int id, String scope) => '$scope/product-image-$id';

/// A product photo on a muted "shelf", so cut-out images on transparent
/// backgrounds still read as a tile.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.placeholderUrl,
    this.padding = Insets.md,
    this.radius = Corners.card,
  });

  final String url;

  /// Shown while [url] loads, usually the already cached thumbnail.
  final String? placeholderUrl;
  final double padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget image(String src, {bool fade = true}) => CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.contain,
      fadeInDuration: fade ? Motion.base : Duration.zero,
      placeholder: placeholderUrl == null || src == placeholderUrl
          ? null
          : (_, _) => image(placeholderUrl!, fade: false),
      errorWidget: (_, _, _) => Icon(Icons.image_not_supported_outlined, color: p.inkFaint),
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(radius)),
      child: Padding(padding: EdgeInsets.all(padding), child: image(url)),
    );
  }
}
