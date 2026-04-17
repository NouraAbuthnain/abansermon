import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth_validator.dart';
import 'widgets/common/auth_widgets.dart';

class VolunteerLoginScreen extends StatefulWidget {
  const VolunteerLoginScreen({super.key});

  @override
  State<VolunteerLoginScreen> createState() => _VolunteerLoginScreenState();
}

class _VolunteerLoginScreenState extends State<VolunteerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _phoneHelperText;
  String? _phoneErrorText;
  Color? _phoneHelperColor;
  String? _passwordHelperText;
  Color? _passwordHelperColor;

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

  void _onPasswordChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _passwordHelperText = null;
        _passwordHelperColor = null;
      });
      return;
    }
    
    final status = AuthValidator.getPasswordValidationStatus(value);
    setState(() {
      if (status.isValid) {
        _passwordHelperText = status.errorKey?.tr();
        _passwordHelperColor = status.isWeak ? AppColors.warning : AppColors.accentGreen;
      } else {
        _passwordHelperText = null; // Let the validator handle it on blur or submit, or show here
        _passwordHelperColor = null;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/dashboard');
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
                  const SizedBox(height: 20),
 
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
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, // TODO: Forget password
                      child: Text(
                        'auth.login.forgotPassword'.tr(),
                        style: textTheme.labelLarge?.copyWith(
                          color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
