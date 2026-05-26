import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/animations/animated_fade_slide.dart';
import '../../../../common_widgets/atoms/app_button.dart';
import '../../../../common_widgets/molecules/app_text_field.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/color_tokens.dart';
import '../../../../theme/gradients.dart';
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 120) {
      return 'Name must be less than 120 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final email = value.trim().toLowerCase();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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
      context.push(RouteNames.classSelection);
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
                    decoration: BoxDecoration(
                      gradient: AppGradients.hero,
                      borderRadius: BorderRadius.circular(20),
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
                    _isLoginMode ? 'Welcome Back' : 'Create Your Profile',
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
                        ? 'Sign in to continue your learning journey.'
                        : 'Tell us a little about yourself so we can personalize your study experience.',
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
                      label: 'Full Name',
                      hint: 'Enter your full name',
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
                    label: 'Email Address',
                    hint: 'your.email@example.com',
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
                    label: 'Password',
                    hint: 'Enter your password',
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
                    label: _isLoginMode ? 'Sign In' : 'Continue',
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
                            ? "Don't have an account? Register"
                            : 'Already have an account? Sign In',
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
