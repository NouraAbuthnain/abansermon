import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth_validator.dart';
import '../domain/auth_error_handler.dart';
import '../../../core/widgets/app_language_button.dart';
import 'widgets/common/auth_widgets.dart';
import 'widgets/legal_content_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/app_dialog.dart';

class VolunteerSignUpScreen extends ConsumerStatefulWidget {
  const VolunteerSignUpScreen({super.key});

  @override
  ConsumerState<VolunteerSignUpScreen> createState() => _VolunteerSignUpScreenState();
}

class _VolunteerSignUpScreenState extends ConsumerState<VolunteerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _docNumberController = TextEditingController();
  
  String _documentTypeKey = 'auth.docTypes.nationalId';
  bool _agreedToTerms = false;
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
          _phoneHelperText = null;
          _phoneErrorText = null;
          _phoneHelperColor = null;
        } else {
          _phoneHelperText = null;
          _phoneErrorText = status.errorKey?.tr();
          _phoneHelperColor = null;
        }
      }
    });
  }



  final List<String> _docTypeKeys = [
    'auth.docTypes.nationalId',
    'auth.docTypes.iqama',
    'auth.docTypes.passport'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _docNumberController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auth.validation.termsRequired'.tr())),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      
      final normalizedPhone = AuthValidator.normalizeSaudiPhone(_phoneController.text);

      try {
        // Check if phone number already exists in volunteers collection
        final existingUser = await FirebaseFirestore.instance
            .collection('volunteers')
            .where('phoneNumber', isEqualTo: normalizedPhone)
            .limit(1)
            .get();

        if (existingUser.docs.isNotEmpty) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          
          await AppDialog.show(
            context,
            type: AppDialogType.info,
            title: 'dialogs.accountExists.title'.tr(),
            message: 'dialogs.accountExists.message'.tr(),
            primaryLabel: 'dialogs.accountExists.logIn'.tr(),
            onPrimaryPressed: () => context.go('/login'),
            secondaryLabel: 'dialogs.accountExists.cancel'.tr(),
            onSecondaryPressed: () => Navigator.pop(context),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error checking existing user: $e');
        // Continue if check fails, but maybe log it
      }
      final extraData = {
        'isSignUp': true,
        'phone': normalizedPhone,
        'fullName': _nameController.text.trim(),
        'documentType': _documentTypeKey,
        'documentNumber': _docNumberController.text.trim(),
      };
      
      if (kIsWeb) {
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
              .signInWithPhoneNumber(normalizedPhone, recaptchaVerifier);

          if (!mounted) return;
          setState(() => _isLoading = false);

          context.push('/otp', extra: {
            ...extraData,
            'confirmationResult': confirmationResult,
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
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: normalizedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-resolution (usually Android only)
            try {
              // Wait, if it auto-resolves on sign-up, we should probably still create the profile!
              // Since we don't have OTP screen, let's just let them go to OTP screen to handle it 
              // or handle it here?
              // The easiest path is to not auto-signin here, but let the user proceed.
              // We'll just wait for codeSent. If auto-resolved, `verificationCompleted` is called.
              // To handle this properly without duplicating profile creation logic, 
              // we will let the OtpVerificationScreen handle the credential sign-in.
            } catch (e) {
              debugPrint('Auto-verification error: $e');
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _phoneErrorText = AuthErrorHandler.getErrorMessage(e);
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            context.push('/otp', extra: {
              ...extraData,
              'verificationId': verificationId,
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
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
            top: 16,
            right: 16,
            child: const AppLanguageButton(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeaderLogo(),
                  const SizedBox(height: 24),
                  Text(
                    'auth.signup.title'.tr(),
                    style: textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auth.signup.subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.doveGray : AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 40),

                  AuthTextField(
                    controller: _nameController,
                    labelText: 'auth.fields.fullName'.tr(),
                    prefixIconPath: 'assets/icons/user.png',
                    validator: (val) => AuthValidator.validateFullName(val)?.tr(),
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _phoneController,
                    labelText: 'auth.fields.phoneNumber'.tr(),
                    hintText: 'auth.fields.phoneHint'.tr(),
                    helperText: _phoneHelperText,
                    helperTextColor: _phoneHelperColor,
                    errorText: _phoneErrorText,
                    prefixIconPath: 'assets/icons/phone.png',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [SaudiPhoneFormatter()],
                    onChanged: _onPhoneChanged,
                    validator: (val) => AuthValidator.validateSaudiPhone(val)?.tr(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Document Type Dropdown (Styled to match AuthTextField)
                  Text(
                    'auth.fields.docType'.tr(),
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.doveGray : AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : AppColors.doveGray.withOpacity(0.35),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _documentTypeKey,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppColors.accentGreen : AppColors.primaryTeal),
                        items: _docTypeKeys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(key.tr(), style: textTheme.bodyLarge),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _documentTypeKey = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  AuthTextField(
                    controller: _docNumberController,
                    labelText: 'auth.fields.docNumber'.tr(args: [_documentTypeKey.tr()]),
                    prefixIconPath: 'assets/icons/id-card.png',
                    keyboardType: _documentTypeKey == 'auth.docTypes.passport' ? TextInputType.text : TextInputType.number,
                    validator: (val) => AuthValidator.validateDocNumber(val, _documentTypeKey)?.tr(),
                  ),
                  const SizedBox(height: 16),

                  
                  // Terms Checkbox
                  // ── Compact Consent Section ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: isDark ? Colors.white38 : AppColors.doveGray,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white70 : AppColors.slate,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: 'auth.signup.agreeTo'.tr()),
                              TextSpan(
                                text: 'auth.signup.termsOfService'.tr(),
                                style: TextStyle(
                                  color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    String content = LegalTexts.termsEn;
                                    final lang = context.locale.languageCode;
                                    if (lang == 'ar') content = LegalTexts.termsAr;
                                    if (lang == 'ur') content = LegalTexts.termsUr;
                                    if (lang == 'bn') content = LegalTexts.termsBn;
                                    LegalContentDialog.show(
                                      context,
                                      title: 'auth.signup.termsOfService'.tr(),
                                      content: content,
                                    );
                                  },
                              ),
                              TextSpan(text: 'auth.signup.and'.tr()),
                              TextSpan(
                                text: 'auth.signup.privacyPolicy'.tr(),
                                style: TextStyle(
                                  color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    String content = LegalTexts.privacyEn;
                                    final lang = context.locale.languageCode;
                                    if (lang == 'ar') content = LegalTexts.privacyAr;
                                    if (lang == 'ur') content = LegalTexts.privacyUr;
                                    if (lang == 'bn') content = LegalTexts.privacyBn;
                                    LegalContentDialog.show(
                                      context,
                                      title: 'auth.signup.privacyPolicy'.tr(),
                                      content: content,
                                    );
                                  },
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  AuthPrimaryButton(
                    label: 'auth.signup.submit'.tr(),
                    isLoading: _isLoading,
                    onPressed: _handleSignUp,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.signup.alreadyHaveAccount'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.doveGray : AppColors.slate,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'auth.login.submit'.tr(),
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
