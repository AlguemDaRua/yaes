import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/forms/ya_button.dart';
import '../../shared/widgets/forms/ya_input.dart';
import '../../theme/tokens/colors.dart';
import '../../theme/tokens/dimensions.dart';
import '../../theme/tokens/typography.dart';
import '../widgets/support_common.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    await ref.read(authStateProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final YaColors colors = YaColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(YaSpacing.xxxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SupportCard(
              padding: const EdgeInsets.all(YaSpacing.xxxl),
              child: _sent ? _sentState(colors) : _formState(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formState(YaColors colors) {
    final S s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          s.authForgotPasswordTitle,
          style: YaText.lg.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          s.authForgotPasswordSubtitle,
          style: YaText.sm.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaInput(
          controller: _emailController,
          label: s.commonEmail,
          placeholder: s.authLoginEmailPlaceholder,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaButton.primary(
          label: s.authForgotPasswordButton,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
        const SizedBox(height: YaSpacing.md),
        YaButton.link(
          label: s.authBackToLogin,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _sentState(YaColors colors) {
    final S s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.brandSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.mail, size: 32, color: colors.brand),
        ),
        const SizedBox(height: YaSpacing.xl),
        Text(
          s.authVerifyEmailTitle,
          style: YaText.lg.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: YaSpacing.sm),
        Text(
          s.authForgotPasswordSuccess(_emailController.text.trim()),
          style: YaText.sm.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: YaSpacing.xxl),
        YaButton.secondary(
          label: s.authForgotPasswordResend,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
        const SizedBox(height: YaSpacing.md),
        YaButton.link(
          label: s.commonBack,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
