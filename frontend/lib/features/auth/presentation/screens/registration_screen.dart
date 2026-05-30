import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/atoms/app_button.dart';
import '../../../../common_widgets/molecules/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/neu_decoration.dart';
import '../providers/auth_providers.dart';

/// Student registration / login screen with form validation.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoginMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _l10n.authValidateName;
    }
    if (value.trim().length < 2) {
      return _l10n.authValidateNameShort;
    }
    if (value.trim().length > 120) {
      return _l10n.authValidateNameLong;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _l10n.authValidateEmail;
    }
    final email = value.trim().toLowerCase();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return _l10n.authValidateEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _l10n.authValidatePassword;
    }
    if (value.length < 6) {
      return _l10n.authValidatePasswordShort;
    }
    return null;
  }

  void _continue() {
    setState(() => _isSubmitted = true);
    if (!_formKey.currentState!.validate()) return;

    ref.read(registrationNameProvider.notifier).state =
        _nameController.text.trim();
    ref.read(registrationEmailProvider.notifier).state =
        _emailController.text.trim().toLowerCase();
    ref.read(registrationPasswordProvider.notifier).state =
        _passwordController.text;

    if (_isLoginMode) {
      _performLogin();
    } else {
      try {
        context.push(RouteNames.classSelection);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigation error: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _performLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      await ref.read(loginProvider.notifier).login(
            email: email,
            password: password,
          );

      if (mounted) {
        context.go(RouteNames.home);
      }
    } catch (_) {
      if (mounted) {
        final state = ref.read(loginProvider);
        state.whenOrNull(
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.danger,
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isLoading = _isLoginMode
        ? ref.watch(loginProvider).isLoading
        : ref.watch(registerStudentProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            autovalidateMode: _isSubmitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                AnimatedFadeSlide(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: NeuDecoration.colored(
                      color: AppColors.primary,
                      radius: 20,
                    ),
                    child: Icon(
                      _isLoginMode
                          ? Icons.login_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    _isLoginMode ? l10n.authWelcomeBack : l10n.authCreateProfile,
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    _isLoginMode
                        ? l10n.authLoginSubtitle
                        : l10n.authRegisterSubtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (!_isLoginMode)
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: AppTextField(
                      controller: _nameController,
                      label: l10n.authFullName,
                      hint: l10n.authFullNameHint,
                      prefixIcon: const Icon(Icons.person_outline),
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                  ),
                if (!_isLoginMode) const SizedBox(height: 24),
                AnimatedFadeSlide(
                  delay: Duration(milliseconds: _isLoginMode ? 300 : 400),
                  child: AppTextField(
                    controller: _emailController,
                    label: l10n.authEmailLabel,
                    hint: l10n.authEmailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedFadeSlide(
                  delay: Duration(milliseconds: _isLoginMode ? 400 : 500),
                  child: AppTextField(
                    controller: _passwordController,
                    label: l10n.authPassword,
                    hint: l10n.authPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    onSubmitted: (_) => _continue(),
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedFadeSlide(
                  delay: Duration(milliseconds: _isLoginMode ? 500 : 600),
                  child: AppButton(
                    label: _isLoginMode ? l10n.authSignIn : l10n.commonContinue,
                    isLoading: isLoading,
                    onPressed: _continue,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedFadeSlide(
                  delay: Duration(milliseconds: _isLoginMode ? 600 : 700),
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(
                          () => _isLoginMode = !_isLoginMode),
                      child: Text(
                        _isLoginMode
                            ? l10n.authToggleToRegister
                            : l10n.authToggleToLogin,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
