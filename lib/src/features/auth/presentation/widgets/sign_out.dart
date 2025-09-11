import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../../core/widgets/feedback.dart';
import '../auth_controller.dart';

/// Asks first, because signing out also forgets biometric unlock.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final ok = await confirm(
    context,
    title: l10n.signOutConfirmTitle,
    message: l10n.signOutConfirmBody,
    confirmLabel: l10n.signOut,
    destructive: true,
  );
  if (ok) await ref.read(authControllerProvider.notifier).signOut();
}
