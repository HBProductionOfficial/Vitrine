import 'package:flutter/material.dart';

import 'package:vitrine/l10n/gen/app_localizations.dart';
import '../design/palette.dart';
import '../design/tokens.dart';
import 'motion.dart';

/// Centered message for empty and error screens. [action] is the one thing
/// the user can do to fix it.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.title, this.message, this.action, this.tone});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Insets.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: p.surfaceMuted, shape: BoxShape.circle),
                child: Icon(icon, size: 28, color: tone ?? p.inkSoft),
              ),
              const SizedBox(height: Insets.lg),
              Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: Insets.sm),
                Text(message!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: Insets.xl), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MessageView(
      icon: Icons.cloud_off_rounded,
      tone: context.palette.danger,
      title: message,
      action: ScaleOnPress(
        builder: (states) => OutlinedButton.icon(
          statesController: states,
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: Text(l10n.retry),
        ),
      ),
    );
  }
}
