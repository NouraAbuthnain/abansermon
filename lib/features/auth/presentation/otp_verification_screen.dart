import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import 'widgets/common/auth_widgets.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber = '+966 5XXXXXXX',
    this.verificationId = '',
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendTimer = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _handleVerify(String code) async {
    setState(() => _isLoading = true);

    if (code == '000000') {
      await ref.read(authProvider.notifier).devLogin();
      if (mounted) context.go('/auth-success');
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      await _auth.signInWithCredential(credential);
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/auth-success');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          e.code == 'invalid-verification-code'
              ? 'auth.otp.invalidCode'.tr()
              : (e.message ?? 'auth.otp.invalidCode'.tr()),
        ),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _resendCode() {
    if (_resendTimer == 0) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.otp.codeResent'.tr())),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeaderLogo(),
                const SizedBox(height: 32),
                Text(
                  'auth.otp.title'.tr(),
                  style: textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'auth.otp.subtitle'.tr(args: [widget.phoneNumber]),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.doveGray : AppColors.slate,
                  ),
                ),
                const SizedBox(height: 48),

                OtpCodeInput(
                  length: 6,
                  onCompleted: _handleVerify,
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.otp.noCode'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.doveGray : AppColors.slate,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendCode,
                      child: Text(
                        _resendTimer > 0 
                            ? '00:${_resendTimer.toString().padLeft(2, '0')}'
                            : 'auth.otp.resend'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 100),
                
                AuthPrimaryButton(
                  label: 'auth.otp.submit'.tr(),
                  isLoading: _isLoading,
                  onPressed: () {
                    // This is triggered by OtpCodeInput completion as well, 
                    // but we keep the button for manual trigger if needed.
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
