import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/errors.dart';
import '../../../core/router/routes.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/notice.dart';
import '../data/dummy_json_auth_repository.dart';
import '../domain/user.dart';
import 'widgets/password_strength_meter.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  bool _accepted = false;
  bool _showTermsError = false;
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _username, _password, _repeat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() {
      _showTermsError = !_accepted;
      _error = null;
    });
    if (!valid || !_accepted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).signUp(SignUpRequest(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
          ));
      if (mounted) await _showCreated();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showCreated() async {
    final l10n = AppLocalizations.of(context);
    final useDemo = await showAppSheet<bool>(
      context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.signUpDoneTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Insets.sm),
            Text(l10n.signUpDoneBody, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: Insets.xl),
            PrimaryButton(label: l10n.signUpUseDemo, onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (useDemo ?? false) {
      context.go('${Routes.login}?demo=1');
    }
  }

  String? _err(FieldError? e, AppLocalizations l10n) => e == null ? null : describeFieldError(e, l10n);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Insets.page, 0, Insets.page, Insets.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Breakpoints.formMaxWidth),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.signUpTitle, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: Insets.xl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LabeledField(
                              label: l10n.firstNameLabel,
                              controller: _firstName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.givenName],
                              validator: (v) => _err(validateRequired(v), l10n),
                            ),
                          ),
                          const SizedBox(width: Insets.md),
                          Expanded(
                            child: LabeledField(
                              label: l10n.lastNameLabel,
                              controller: _lastName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.familyName],
                              validator: (v) => _err(validateRequired(v), l10n),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                      LabeledField(
                        label: l10n.emailLabel,
                        controller: _email,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        hintText: 'email@example.com',
                        validator: (v) => _err(validateEmail(v), l10n),
                      ),
                      const SizedBox(height: Insets.lg),
                      LabeledField(
                        label: l10n.usernameLabel,
                        controller: _username,
                        prefixIcon: Icons.alternate_email_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        validator: (v) => _err(validateNewUsername(v), l10n),
                      ),
                      const SizedBox(height: Insets.lg),
                      PasswordField(
                        label: l10n.passwordLabel,
                        controller: _password,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (_) => setState(() {}),
                        validator: (v) => _err(validateNewPassword(v), l10n),
                      ),
                      const SizedBox(height: Insets.sm),
                      PasswordStrengthMeter(strength: passwordStrength(_password.text)),
                      const SizedBox(height: Insets.lg),
                      PasswordField(
                        label: l10n.confirmPasswordLabel,
                        controller: _repeat,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => _err(validateRepeatPassword(v, _password.text), l10n),
                      ),
                      const SizedBox(height: Insets.md),
                      CheckboxListTile(
                        value: _accepted,
                        onChanged: (v) => setState(() {
                          _accepted = v ?? false;
                          if (_accepted) _showTermsError = false;
                        }),
                        title: Text(l10n.acceptTerms, style: theme.textTheme.bodyMedium?.copyWith(color: p.ink)),
                        subtitle: _showTermsError
                            ? Text(l10n.errorTermsRequired, style: theme.textTheme.bodySmall?.copyWith(color: p.danger))
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: Insets.md),
                        Notice(message: describeError(_error!, l10n)),
                      ],
                      const SizedBox(height: Insets.lg),
                      PrimaryButton(label: l10n.signUpButton, loading: _submitting, onPressed: _submit),
                      const SizedBox(height: Insets.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(l10n.haveAccount, style: theme.textTheme.bodyMedium),
                          TextButton(onPressed: () => context.go(Routes.login), child: Text(l10n.signInLink)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
