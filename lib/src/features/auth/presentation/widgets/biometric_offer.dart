import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/biometrics/biometric_service.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/errors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/feedback.dart';
import '../auth_controller.dart';
import 'biometric_labels.dart';

/// After a password sign-in, asks once whether to turn on biometric unlock.
/// Lives above the tab shell so the sheet opens on the first screen the user
/// lands on.
class BiometricOffer extends ConsumerStatefulWidget {
  const BiometricOffer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricOffer> createState() => _BiometricOfferState();
}

class _BiometricOfferState extends ConsumerState<BiometricOffer> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOffer(ref.read(authControllerProvider)));
  }

  Future<void> _maybeOffer(AuthState auth) async {
    if (_showing || !mounted || auth is! SignedIn || !auth.offerBiometrics) return;
    _showing = true;
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(authControllerProvider.notifier);

    final accepted = await showAppSheet<bool>(context, builder: (context) => _OfferSheet(kind: auth.biometricKind));
    if (!mounted) return;
    if (accepted ?? false) {
      try {
        await controller.enableBiometrics(l10n.biometricEnableReason);
      } catch (e) {
        if (mounted) showSnack(context, describeError(e, l10n));
      }
    } else {
      await controller.declineBiometricOffer();
    }
    _showing = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) => _maybeOffer(next));
    return widget.child;
  }
}

class _OfferSheet extends StatelessWidget {
  const _OfferSheet({required this.kind});

  final BiometricKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BiometricGlyph(kind: kind, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: Insets.lg),
          Text(l10n.enableBioTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Insets.sm),
          Text(switch (kind) {
            BiometricKind.face => l10n.enableBioBodyFace,
            BiometricKind.faceOrFingerprint => l10n.enableBioBodyFaceOrFingerprint,
            _ => l10n.enableBioBodyFingerprint,
          }, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Insets.xl),
          PrimaryButton(label: l10n.enableBioConfirm, onPressed: () => Navigator.pop(context, true)),
          const SizedBox(height: Insets.sm),
          SecondaryButton(label: l10n.enableBioLater, onPressed: () => Navigator.pop(context, false)),
        ],
      ),
    );
  }
}
