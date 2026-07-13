import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_user.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../widgets/support_common.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    this.redirectTo,
    super.key,
  });

  final String? redirectTo;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _submitting = false;
  bool _resetting = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    final YaColors colors = YaColors.of(context);
    final S s = S.of(context);
    final bool needsVerify = authNotifier.needsEmailVerification;

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(YaSpacing.xxxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'YA',
                  textAlign: TextAlign.center,
                  style: YaText.serif(
                    size: 48,
                    height: 52,
                    weight: FontWeight.w500,
                  ).copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'PAINEL',
                  textAlign: TextAlign.center,
                  style: YaText.eyebrowRole.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: YaSpacing.huge2),
                SupportCard(
                  padding: const EdgeInsets.all(YaSpacing.xxxl),
                  child: needsVerify
                      ? _verifyEmailScreen(colors)
                      : _emailPasswordForm(colors),
                ),
                const SizedBox(height: YaSpacing.xxxl),
                Text(
                  s.authLoginNoAccount,
                  textAlign: TextAlign.center,
                  style: YaText.sans(size: 12, height: 16)
                      .copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailPasswordForm(YaColors colors) {
    final S s = S.of(context);
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            s.authLoginTitle,
            style: YaText.lg.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            s.authLoginSubtitle,
            style: YaText.sm.copyWith(color: colors.textSecondary),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: YaSpacing.lg),
            _MessageBox(
              message: _error!,
              color: colors.danger,
              bg: colors.dangerSubtle,
            ),
          ],
          if (_info != null) ...<Widget>[
            const SizedBox(height: YaSpacing.lg),
            _MessageBox(
              message: _info!,
              color: colors.success,
              bg: colors.successSubtle,
            ),
          ],
          const SizedBox(height: YaSpacing.xxl),
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: YaInput(
              label: s.commonEmail,
              controller: _emailController,
              placeholder: s.authLoginEmailPlaceholder,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              enabled: !_submitting,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: YaSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  s.authLoginPasswordLabel,
                  style: YaText.sans(
                    size: 12,
                    height: 16,
                    weight: FontWeight.w500,
                  ).copyWith(color: colors.textSecondary),
                ),
              ),
              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: YaButton.link(
                  label:
                      _resetting ? s.commonLoading : s.authLoginForgotPassword,
                  size: YaButtonSize.sm,
                  onPressed: _resetting ? null : _sendReset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: YaInput(
              controller: _passwordController,
              placeholder: '********',
              obscureText: true,
              enabled: !_submitting,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: YaSpacing.xxl),
          FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: YaButton.primary(
              label: _submitting ? s.authLoginButtonLoading : s.authLoginButton,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifyEmailScreen(YaColors colors) {
    final S s = S.of(context);
    final String email = authNotifier.pendingEmail ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.authVerifyEmailTitle,
          style: YaText.lg.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          s.authVerifyEmailBody(email),
          style: YaText.sm.copyWith(color: colors.textSecondary),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: YaSpacing.lg),
          _MessageBox(
            message: _error!,
            color: colors.danger,
            bg: colors.dangerSubtle,
          ),
        ],
        if (_info != null) ...<Widget>[
          const SizedBox(height: YaSpacing.lg),
          _MessageBox(
            message: _info!,
            color: colors.success,
            bg: colors.successSubtle,
          ),
        ],
        const SizedBox(height: YaSpacing.xxl),
        YaButton.primary(
          label: _submitting
              ? s.authVerifyEmailButtonLoading
              : s.authVerifyEmailButton,
          loading: _submitting,
          onPressed: _submitting ? null : _checkVerified,
        ),
        const SizedBox(height: YaSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: YaButton.secondary(
                label: s.authVerifyEmailResend,
                onPressed: _submitting ? null : _resendVerification,
              ),
            ),
            const SizedBox(width: YaSpacing.sm),
            Expanded(
              child: YaButton.secondary(
                label: s.commonExit,
                onPressed: _submitting
                    ? null
                    : () async {
                        await ref.read(authStateProvider.notifier).signOut();
                        if (mounted) setState(() => _info = null);
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = S.of(context).authLoginEmailRequired;
        _info = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });

    final bool ok = await ref
        .read(authStateProvider.notifier)
        .signInWithEmail(email, password);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (authNotifier.needsEmailVerification) {
      // o build refresca para o ecra de verificacao
      return;
    }

    if (!ok) {
      setState(() {
        _error =
            authNotifier.lastError ?? S.of(context).authLoginInvalidCredentials;
      });
      return;
    }

    _goToLanding();
  }

  Future<void> _sendReset() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = S.of(context).authLoginEmailResetRequired);
      return;
    }
    setState(() {
      _resetting = true;
      _error = null;
      _info = null;
    });
    final bool ok =
        await ref.read(authStateProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _resetting = false;
      if (ok) {
        _info = S.of(context).authResetSentInfo(email);
      } else {
        _error = authNotifier.lastError ?? S.of(context).authLoginResetFailed;
      }
    });
  }

  Future<void> _resendVerification() async {
    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });
    final bool ok =
        await ref.read(authStateProvider.notifier).sendEmailVerification();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _info = S.of(context).authVerifyEmailResent;
      } else {
        _error = authNotifier.lastError ?? S.of(context).authLoginResetFailed;
      }
    });
  }

  Future<void> _checkVerified() async {
    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });
    final bool ok = await ref.read(authStateProvider.notifier).refreshUser();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok || authNotifier.needsEmailVerification) {
      setState(() {
        _error = S.of(context).authVerifyEmailNotConfirmed;
      });
      return;
    }
    _goToLanding();
  }

  void _goToLanding() {
    final AuthUser? user = authNotifier.user ?? ref.read(authStateProvider);
    final String fallback = user?.role.landingRoute ?? '/admin/dashboard';
    context.go(widget.redirectTo ?? fallback);
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.color,
    required this.bg,
  });

  final String message;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: YaRadius.brMd,
      ),
      child: Text(
        message,
        style: YaText.sans(size: 12, height: 16).copyWith(color: color),
      ),
    );
  }
}
