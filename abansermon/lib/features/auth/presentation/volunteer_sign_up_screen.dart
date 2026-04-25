import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../domain/auth_validator.dart';
import 'widgets/common/auth_widgets.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _documentTypeKey = 'auth.docTypes.nationalId';
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _phoneHelperText;
  String? _phoneErrorText;
  Color? _phoneHelperColor;
  String? _passwordHelperText;
  Color? _passwordHelperColor;
  String? _confirmPasswordHelperText;
  Color? _confirmPasswordHelperColor;

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
          _phoneHelperColor = null;
        } else {
          _phoneHelperText = null;
          _phoneErrorText = status.errorKey?.tr();
          _phoneHelperColor = null;
        }
      }
    });
  }

  void _onPasswordChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _passwordHelperText = null;
        _passwordHelperColor = null;
      });
    } else {
      final status = AuthValidator.getPasswordValidationStatus(value);
      setState(() {
        if (status.isValid) {
          _passwordHelperText = status.errorKey?.tr();
          _passwordHelperColor = status.isWeak ? AppColors.warning : AppColors.accentGreen;
        } else {
          _passwordHelperText = null;
          _passwordHelperColor = null;
        }
      });
    }
    _validateConfirmPassword(_confirmPasswordController.text);
  }

  void _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      setState(() {
        _confirmPasswordHelperText = null;
        _confirmPasswordHelperColor = null;
      });
      return;
    }
    setState(() {
      if (value == _passwordController.text) {
        _confirmPasswordHelperText = 'auth.validation.password.valid'.tr(); // Or a specific "Matches" string
        _confirmPasswordHelperColor = AppColors.accentGreen;
      } else {
        _confirmPasswordHelperText = 'auth.validation.password.mismatch'.tr();
        _confirmPasswordHelperColor = AppColors.error;
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (usually Android only)
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) {
              setState(() => _isLoading = false);
              context.go('/auth-success');
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _phoneErrorText = 'Auto-verification failed';
              });
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _phoneErrorText = e.message ?? 'Verification failed';
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            // Proceed to the OTP screen!
            context.push('/otp', extra: {
              'phone': normalizedPhone,
              'verificationId': verificationId,
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout occurred, fallback to UI OTP input
        },
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
                    prefixIconPath: 'assets/icons/telephone.png',
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
                    validator: (val) => AuthValidator.validateDocNumber(val)?.tr(args: [_documentTypeKey.tr()]),
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _passwordController,
                    labelText: 'auth.fields.password'.tr(),
                    prefixIconPath: 'assets/icons/locked-computer.png',
                    isPassword: true,
                    helperText: _passwordHelperText,
                    helperTextColor: _passwordHelperColor,
                    onChanged: _onPasswordChanged,
                    validator: (val) => AuthValidator.validatePassword(val)?.tr(),
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _confirmPasswordController,
                    labelText: 'auth.fields.confirmPassword'.tr(),
                    prefixIconPath: 'assets/icons/locked-computer.png',
                    isPassword: true,
                    helperText: _confirmPasswordHelperText,
                    helperTextColor: _confirmPasswordHelperColor,
                    onChanged: _validateConfirmPassword,
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return 'auth.validation.password.mismatch'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Terms Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            activeColor: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: isDark ? Colors.white38 : AppColors.doveGray,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => _agreedToTerms = val ?? false);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final fullText = 'auth.signup.agreeTerms'.tr();
                            
                            // If placeholders are missing (e.g. app not hot-restarted after JSON change), 
                            // fallback to normal text to avoid showing technical keys
                            if (!fullText.contains('{terms}') || !fullText.contains('{privacy}')) {
                              return Text(
                                fullText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.ink.withOpacity(0.7),
                                  height: 1.5,
                                ),
                              );
                            }

                            // Use unique markers to split the string safely
                            final textWithMarkers = 'auth.signup.agreeTerms'.tr(namedArgs: {
                              'terms': '[[TERMS]]',
                              'privacy': '[[PRIVACY]]',
                            });
                            
                            final termsText = 'auth.signup.termsLink'.tr();
                            final privacyText = 'auth.signup.privacyLink'.tr();

                            final partsByTerms = textWithMarkers.split('[[TERMS]]');
                            final prefix = partsByTerms[0];
                            final rest = partsByTerms.length > 1 ? partsByTerms[1] : '';
                            
                            final partsByPrivacy = rest.split('[[PRIVACY]]');
                            final middle = partsByPrivacy[0];
                            final suffix = partsByPrivacy.length > 1 ? partsByPrivacy[1] : '';

                            final linkColor = isDark ? AppColors.accentGreen : AppColors.primaryTeal;

                            return RichText(
                              text: TextSpan(
                                style: textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white70 : AppColors.ink.withOpacity(0.7),
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: prefix),
                                  TextSpan(
                                    text: termsText,
                                    style: TextStyle(
                                      color: linkColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // Navigate to Terms
                                      },
                                  ),
                                  TextSpan(text: middle),
                                  TextSpan(
                                    text: privacyText,
                                    style: TextStyle(
                                      color: linkColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // Navigate to Privacy
                                      },
                                  ),
                                  TextSpan(text: suffix),
                                ],
                              ),
                            );
                          },
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
