import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/tokens.dart';
import '../../../core/errors.dart';
import '../../../core/router/routes.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/state_views.dart';
import '../data/dummy_json_auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await ref.read(authRepositoryProvider).sendPasswordReset(_email.text.trim());
    if (mounted) {
      setState(() {
        _sending = false;
        _sentTo = _email.text.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: _sentTo != null
            ? MessageView(
                icon: Icons.mark_email_read_outlined,
                title: l10n.forgotDoneTitle,
                message: l10n.forgotDoneBody(_sentTo!),
                action: SecondaryButton(label: l10n.backToSignIn, onPressed: () => context.go(Routes.login)),
              )
            : Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Insets.page, 0, Insets.page, Insets.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Breakpoints.formMaxWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.forgotTitle, style: theme.textTheme.headlineMedium),
                          const SizedBox(height: Insets.sm),
                          Text(l10n.forgotBody, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: Insets.xl),
                          LabeledField(
                            label: l10n.emailLabel,
                            controller: _email,
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.email],
                            hintText: 'email@example.com',
                            onSubmitted: (_) => _send(),
                            validator: (v) {
                              final e = validateEmail(v);
                              return e == null ? null : describeFieldError(e, l10n);
                            },
                          ),
                          const SizedBox(height: Insets.xl),
                          PrimaryButton(label: l10n.sendResetLink, loading: _sending, onPressed: _send),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
