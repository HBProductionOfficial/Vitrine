import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/palette.dart';
import '../../shop/domain/product.dart';
import 'saved_controller.dart';

class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final saved = ref.watch(savedProvider.select((list) => list.any((s) => s.id == product.id)));
    return IconButton(
      tooltip: saved ? l10n.unsaveProduct : l10n.saveProduct,
      isSelected: saved,
      onPressed: () => ref.read(savedProvider.notifier).toggle(product),
      icon: Icon(Icons.favorite_border_rounded, color: p.inkSoft),
      selectedIcon: Icon(Icons.favorite_rounded, color: p.ink),
    );
  }
}
