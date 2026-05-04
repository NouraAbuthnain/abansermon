import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth_validator.dart';
import '../domain/auth_error_handler.dart';
import '../../../core/widgets/app_language_button.dart';
import 'widgets/common/auth_widgets.dart';

class VolunteerLoginScreen extends StatefulWidget {
  const VolunteerLoginScreen({super.key});

  @override
  State<VolunteerLoginScreen> createState() => _VolunteerLoginScreenState();
}

class _VolunteerLoginScreenState extends State<VolunteerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _phoneHelperText;
  String? _phoneErrorText;
  Color? _phoneHelperColor;

  void _onPhoneChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _phoneHelperText = null;
        _phoneErrorText = null;
        _phoneHelperColor = null;
      });
      return;
    }
    final status = AuthValidator.getPhoneValidationStatus(value);
    setState(() {
      if (status.isValid) {
        _phoneHelperText = status.errorKey?.tr();
        _phoneErrorText = null;
        _phoneHelperColor = AppColors.accentGreen;
      } else {
        String digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.startsWith('5') || digits.startsWith('05')) {
          _phoneHelperText = 'auth.validation.phone.preview'.tr(args: [status.normalizedValue ?? '']);
          _phoneErrorText = null;
          _phoneHelperColor = null; // Default color for preview
        } else {
          _phoneHelperText = null;
          _phoneErrorText = status.errorKey?.tr();
          _phoneHelperColor = null;
        }
      }
    });
  }



  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final phone = AuthValidator.normalizeSaudiPhone(_phoneController.text);

    if (kIsWeb) {
      // --- WEB: uses signInWithPhoneNumber + RecaptchaVerifier ---
      try {
        final recaptchaVerifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          onSuccess: () => debugPrint('reCAPTCHA solved'),
          onError: (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('auth.errors.generic'.tr()),
                backgroundColor: AppColors.error,
              ));
            }
          },
          onExpired: () => debugPrint('reCAPTCHA expired'),
        );

        final confirmationResult = await FirebaseAuth.instance
            .signInWithPhoneNumber(phone, recaptchaVerifier);

        if (!mounted) return;
        setState(() => _isLoading = false);

        context.push('/otp', extra: {
          'phone': phone,
          'confirmationResult': confirmationResult,
          'isSignUp': false,
        });
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AuthErrorHandler.getErrorMessage(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } else {
      // --- MOBILE (Android / iOS): uses verifyPhoneNumber ---
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) context.go('/auth-success');
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AuthErrorHandler.getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          context.push('/otp', extra: {
            'phone': phone,
            'verificationId': verificationId,
            'isSignUp': false,
          });
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthBackground(
      child: Stack(
        children: [
          const AuthBackButton(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: const AppLanguageButton(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeaderLogo(),
                  const SizedBox(height: 32),
                  Text(
                    'auth.login.welcomeBack'.tr(),
                    style: textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auth.login.subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.doveGray : AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 48),

                  AuthTextField(
                    controller: _phoneController,
                    labelText: 'auth.fields.phoneNumber'.tr(),
                    hintText: 'auth.fields.phoneHint'.tr(),
                    helperText: _phoneHelperText,
                    helperTextColor: _phoneHelperColor,
                    errorText: _phoneErrorText,
                    prefixIconPath: 'assets/icons/telephone.png',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [SaudiPhoneFormatter()],
                    onChanged: _onPhoneChanged,
                    validator: (val) => AuthValidator.validateSaudiPhone(val)?.tr(),
                  ),
                  const SizedBox(height: 32),

                  AuthPrimaryButton(
                    label: 'auth.login.submit'.tr(),
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.login.noAccount'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.doveGray : AppColors.slate,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text(
                          'auth.login.createAccount'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
