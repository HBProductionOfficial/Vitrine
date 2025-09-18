import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrine/l10n/gen/app_localizations.dart';

import '../../../core/biometrics/biometric_service.dart';
import '../../../core/design/palette.dart';
import '../../../core/design/tokens.dart';
import '../../../core/errors.dart';
import '../../../core/router/routes.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/vitrine_mark.dart';
import 'auth_controller.dart';
import 'widgets/biometric_labels.dart';
import 'widgets/or_divider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.prefillDemo = false});

  final bool prefillDemo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _demoUser = 'emilys';
  static const _demoPassword = 'emilyspass';

  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _rememberMe = true;
  bool _submitting = false;
  bool _unlocking = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefillDemo) _fillDemo();
    final auth = ref.read(authControllerProvider);
    if (auth is SignedOut) {
      _error = auth.reason;
      // A saved session with biometrics turned on: ask right away, the way
      // banking apps do, instead of waiting for a tap.
      if (auth.biometricReady) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void didUpdateWidget(LoginScreen old) {
    super.didUpdateWidget(old);
    // go_router reuses this screen when sign-up sends the user back with ?demo=1.
    if (widget.prefillDemo && !old.prefillDemo) _fillDemo();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _fillDemo() {
    _username.text = _demoUser;
    _password.text = _demoPassword;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).login(_username.text, _password.text, rememberMe: _rememberMe);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _unlocking = true;
    });
    try {
      await ref.read(authControllerProvider.notifier).unlockWithBiometrics(l10n.biometricReason);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = context.palette;
    final auth = ref.watch(authControllerProvider);
    final kind = auth is SignedOut ? auth.biometricKind : BiometricKind.none;
    // No sensor, or nothing set up on it: the button couldn't work, so it isn't shown.
    final canUseBiometrics = auth is SignedOut && kind != BiometricKind.none && auth.biometricEnrolled;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Insets.page, Insets.xl, Insets.page, Insets.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Breakpoints.formMaxWidth),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const VitrineMark(size: 40),
                          const SizedBox(width: Insets.md),
                          Text(l10n.appTitle, style: theme.textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: Insets.xxl),
                      Text(l10n.signInTitle, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: Insets.sm),
                      Text(l10n.signInSubtitle, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: Insets.xl),
                      _DemoHint(onFill: () => setState(_fillDemo)),
                      const SizedBox(height: Insets.xl),
                      LabeledField(
                        label: l10n.usernameLabel,
                        controller: _username,
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: (v) => _fieldError(validateLoginUsername(v), l10n),
                      ),
                      const SizedBox(height: Insets.lg),
                      PasswordField(
                        label: l10n.passwordLabel,
                        controller: _password,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) => _fieldError(validateLoginPassword(v), l10n),
                      ),
                      const SizedBox(height: Insets.xs),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              title: Text(l10n.rememberMe, style: theme.textTheme.bodyMedium?.copyWith(color: p.ink)),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(Routes.forgotPassword),
                            child: Text(l10n.forgotPassword),
                          ),
                        ],
                      ),
                      NoticeSlot(message: _error == null ? null : describeError(_error!, l10n)),
                      const SizedBox(height: Insets.lg),
                      PrimaryButton(label: l10n.signInButton, loading: _submitting, onPressed: _submit),
                      if (canUseBiometrics) ...[
                        const SizedBox(height: Insets.lg),
                        OrDivider(label: l10n.orDivider),
                        const SizedBox(height: Insets.lg),
                        SecondaryButton(
                          label: biometricSignInLabel(kind, l10n),
                          leading: BiometricGlyph(kind: kind),
                          onPressed: _unlocking ? null : _unlock,
                        ),
                      ],
                      const SizedBox(height: Insets.xxl),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(l10n.newHere, style: theme.textTheme.bodyMedium),
                          TextButton(onPressed: () => context.push(Routes.signUp), child: Text(l10n.createAccountLink)),
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

  String? _fieldError(FieldError? error, AppLocalizations l10n) =>
      error == null ? null : describeFieldError(error, l10n);
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onFill});

  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: BorderRadius.circular(Corners.input)),
      child: Row(
        children: [
          Icon(Icons.key_outlined, size: 18, color: p.inkSoft),
          const SizedBox(width: Insets.sm),
          Expanded(child: Text(l10n.demoAccountHint, style: Theme.of(context).textTheme.bodyMedium)),
          TextButton(onPressed: onFill, child: Text(l10n.fillDemoAccount)),
        ],
      ),
    );
  }
}
