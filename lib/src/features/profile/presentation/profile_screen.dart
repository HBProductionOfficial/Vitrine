import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/app_info.dart';
import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/links.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/vitrine_mark.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/widgets/sign_out.dart';
import '../../saved/presentation/saved_controller.dart';
import '../../settings/widgets/settings_rows.dart';
import '../../shop/presentation/widgets/product_image.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showAbout(BuildContext context, String? version) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showAppSheet<void>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const VitrineMark(size: 40),
                  const SizedBox(width: Insets.md),
                  Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: Insets.lg),
              Text(l10n.aboutBody, style: theme.textTheme.bodyMedium),
              if (version != null) ...[
                const SizedBox(height: Insets.sm),
                Text(l10n.versionLabel(version), style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: Insets.xl),
              SecondaryButton(
                label: l10n.sourceCode,
                icon: Icons.code_rounded,
                onPressed: () => openLink(sheet, Links.source),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final auth = ref.watch(authControllerProvider);
    final version = ref.watch(appVersionProvider).value;
    // The router sends signed-out users to the login screen; this only covers the frame in between.
    if (auth is! SignedIn) return const SizedBox.shrink();

    return Scaffold(
      appBar: PageAppBar(
        maxWidth: 640,
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: PageBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Insets.page, Insets.sm, Insets.page, Insets.xxl),
          children: [
            _IdentityCard(user: auth.user),
            const SizedBox(height: Insets.md),
            const _SavedCard(),
            const SizedBox(height: Insets.xl),
            SettingsGroup(title: l10n.contactDetails, children: const [_ContactDetails()]),
            SettingsGroup(
              title: l10n.account,
              children: [
                // Also reachable from the gear; a list of account things without it reads as an omission.
                SettingsRow(
                  icon: Icons.settings_outlined,
                  label: l10n.settings,
                  onTap: () => context.push(Routes.settings),
                ),
                SettingsRow(
                  icon: Icons.info_outline_rounded,
                  label: l10n.about,
                  onTap: () => _showAbout(context, version),
                ),
                SettingsRow(
                  icon: Icons.logout_rounded,
                  label: l10n.signOut,
                  color: p.danger,
                  onTap: () => confirmSignOut(context, ref),
                ),
              ],
            ),
            if (version != null)
              Center(child: Text('${l10n.appTitle} $version', style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Corners.card),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: p.surfaceMuted,
            foregroundImage: user.image == null ? null : CachedNetworkImageProvider(user.image!),
            child: Text(user.initials, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('@${user.username}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final theme = Theme.of(context);
    final saved = ref.watch(savedProvider);

    return Material(
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.card),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        onTap: () => context.go(Routes.saved),
        child: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: p.surfaceMuted, shape: BoxShape.circle),
                child: Icon(Icons.favorite_border_rounded, size: 20, color: p.ink),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.savedItems, style: theme.textTheme.titleSmall),
                    Text(l10n.savedCount(saved.length), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              // A glimpse of what's in there, newest first.
              for (final product in saved.take(3))
                Padding(
                  padding: const EdgeInsets.only(left: Insets.xs),
                  child: SizedBox.square(
                    dimension: 36,
                    child: ExcludeSemantics(child: ProductImage(url: product.thumbnail, padding: 3, radius: 8)),
                  ),
                ),
              const SizedBox(width: Insets.xs),
              Icon(Icons.chevron_right_rounded, color: p.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactDetails extends ConsumerWidget {
  const _ContactDetails();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return ref
        .watch(currentUserProvider)
        .when(
          data: (user) => Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.sm),
            child: Column(
              children: [
                _InfoRow(icon: Icons.mail_outline_rounded, label: l10n.contactEmail, value: user.email),
                if (user.phone != null)
                  _InfoRow(icon: Icons.phone_outlined, label: l10n.contactPhone, value: user.phone!),
                if (user.address != null)
                  _InfoRow(icon: Icons.home_outlined, label: l10n.contactAddress, value: user.address!),
              ],
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(Insets.lg),
            child: Shimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 200),
                  SizedBox(height: Insets.md),
                  SkeletonBox(width: 150),
                  SizedBox(height: Insets.md),
                  SkeletonBox(width: 240),
                ],
              ),
            ),
          ),
          error: (_, _) => SettingsRow(
            icon: Icons.error_outline_rounded,
            label: l10n.profileLoadFailed,
            color: p.danger,
            trailing: TextButton(onPressed: () => ref.invalidate(currentUserProvider), child: Text(l10n.retry)),
          ),
        );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: p.inkSoft),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: p.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
