import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../core/design/palette.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/motion.dart';
import '../auth/presentation/auth_controller.dart';
import '../shop/domain/product.dart';
import 'my_reviews_controller.dart';

/// Write or edit your review of one product. Pops true when saved.
class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({super.key, required this.product, this.existing});

  final Product product;
  final Review? existing;

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  static const _maxLength = 300;

  late int _rating = widget.existing?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.existing?.comment);
  bool _tried = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _valid => _rating > 0 && _comment.text.trim().isNotEmpty;

  void _save() {
    setState(() => _tried = true);
    if (!_valid) return;
    final auth = ref.read(authControllerProvider);
    final reviewer = auth is SignedIn ? auth.user.fullName : '';
    ref
        .read(myReviewsProvider.notifier)
        .save(widget.product.id, rating: _rating, comment: _comment.text, reviewer: reviewer);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final missingRating = _tried && _rating == 0;
    final missingComment = _tried && _comment.text.trim().isEmpty;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
      children: [
        Text(widget.existing == null ? l10n.writeReview : l10n.editReview, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Insets.xs),
        Text(widget.product.title, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Insets.xl),
        Text(l10n.yourRating, style: theme.textTheme.labelMedium),
        const SizedBox(height: Insets.xs),
        StarPicker(value: _rating, onChanged: (value) => setState(() => _rating = value)),
        AnimatedSize(
          duration: Motion.base,
          child: missingRating
              ? Padding(
                  padding: const EdgeInsets.only(top: Insets.xs),
                  child: Text(
                    l10n.errorRatingRequired,
                    style: theme.textTheme.bodySmall?.copyWith(color: context.palette.danger),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: Insets.lg),
        Text(l10n.reviewCommentLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: Insets.sm),
        TextField(
          controller: _comment,
          minLines: 3,
          maxLines: 6,
          maxLength: _maxLength,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.reviewCommentHint,
            errorText: missingComment ? l10n.errorFieldRequired : null,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: context.palette.inkFaint),
            const SizedBox(width: Insets.sm),
            Expanded(child: Text(l10n.reviewLocalNote, style: theme.textTheme.bodySmall)),
          ],
        ),
        const SizedBox(height: Insets.lg),
        PrimaryButton(label: l10n.save, onPressed: _save),
      ],
    );
  }
}

/// Five tappable stars. Each one pops as it fills.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i <= value,
            label: l10n.rateStars(i),
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => onChanged(i),
              radius: 24,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: BumpOnChange(
                    value: i <= value ? true : null,
                    amount: 0.35,
                    child: AnimatedSwitcher(
                      duration: Motion.fast,
                      child: Icon(
                        i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                        key: ValueKey(i <= value),
                        size: 34,
                        color: i <= value ? p.ink : p.inkFaint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
