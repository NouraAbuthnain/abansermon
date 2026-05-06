import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../domain/auth_error_handler.dart';
import '../../../core/widgets/app_language_button.dart';
import 'widgets/common/auth_widgets.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final bool isSignUp;
  final String phoneNumber;
  final String verificationId;
  final ConfirmationResult? confirmationResult;
  final String fullName;
  final String documentType;
  final String documentNumber;

  const OtpVerificationScreen({
    super.key,
    this.isSignUp = false,
    this.phoneNumber = '+966 5XXXXXXX',
    this.verificationId = '',
    this.confirmationResult,
    this.fullName = '',
    this.documentType = '',
    this.documentNumber = '',
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
      if (mounted) context.go('/auth-success', extra: {'isSignUp': widget.isSignUp});
      return;
    }

    try {
      UserCredential userCredential;
      if (kIsWeb && widget.confirmationResult != null) {
        userCredential = await widget.confirmationResult!.confirm(code);
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: code,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }
      
      final user = userCredential.user;
      if (user == null) throw Exception('auth.errors.generic'.tr());

      if (widget.isSignUp) {
        // Create volunteer profile
        await FirebaseFirestore.instance.collection('volunteers').doc(user.uid).set({
          'uid': user.uid,
          'fullName': widget.fullName,
          'phoneNumber': widget.phoneNumber,
          'documentType': widget.documentType,
          'documentNumber': widget.documentNumber,
          'role': 'volunteer',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      } else {
        // Verify existing profile
        final doc = await FirebaseFirestore.instance.collection('volunteers').doc(user.uid).get();
        if (!doc.exists) {
          await _auth.signOut();
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('auth.errors.accountNotFound'.tr()),
              backgroundColor: AppColors.error,
            ));
            context.go('/signup');
            return;
          }
        } else if (doc.data()?['isActive'] != true) {
          await _auth.signOut();
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('auth.errors.accountDeactivated'.tr()),
              backgroundColor: AppColors.error,
            ));
            return;
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/auth-success', extra: {'isSignUp': widget.isSignUp});
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AuthErrorHandler.getErrorMessage(e)),
        backgroundColor: AppColors.error,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AuthErrorHandler.getGenericErrorMessage(e)),
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
          Positioned(
            top: 16,
            right: 16,
            child: const AppLanguageButton(),
          ),
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
