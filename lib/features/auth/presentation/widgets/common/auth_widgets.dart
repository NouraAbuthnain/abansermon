import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:abansermon/core/theme/app_theme.dart';
import 'package:abansermon/core/widgets/app_back_button.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // adapts correctly to both Light Mode and Dark Mode
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: child,
        ),
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AuthBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: AppBackButton(
        onPressed: onPressed ??
            () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/onboarding');
              }
            },
      ),
    );
  }
}

class AuthHeaderLogo extends StatelessWidget {
  const AuthHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: 'auth_logo',
        child: SvgPicture.asset(
          'assets/svgs/iconLG.svg',
          height: 80,
          // No hardcoded color to let it use original or theme it if needed
        ),
      ),
    );
  }
}

class AuthTextField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? prefixIconPath;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  final Color? helperTextColor;

  const AuthTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIconPath,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.helperTextColor,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.labelText,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withOpacity(0.9) : AppColors.ink.withOpacity(0.8),
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          style: textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white : AppColors.ink,
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.doveGray : AppColors.slate.withOpacity(0.5),
            ),
            helperText: widget.helperText,
            helperMaxLines: 2,
            helperStyle: TextStyle(
              color: widget.helperTextColor ?? (isDark ? AppColors.doveGray : AppColors.slate), 
              fontWeight: widget.helperTextColor != null ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
            errorText: widget.errorText,
            filled: true,
            fillColor: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
            prefixIcon: widget.prefixIconPath != null
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      widget.prefixIconPath!,
                      width: 20,
                      height: 20,
                      color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                    ),
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Image.asset(
                      _obscureText ? 'assets/icons/hide.png' : 'assets/icons/show.png',
                      width: 22,
                      height: 22,
                      color: isDark ? AppColors.doveGray : AppColors.slate,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : AppColors.doveGray.withOpacity(0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? AppColors.accentGreen : AppColors.primaryTeal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class OtpCodeInput extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;

  const OtpCodeInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
  });

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    
    String currentCode = _controllers.map((c) => c.text).join();
    if (currentCode.length == widget.length) {
      widget.onCompleted(currentCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 50,
          height: 56,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            onChanged: (value) => _onChanged(value, index),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.2) : AppColors.doveGray.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? AppColors.accentGreen : AppColors.primaryTeal, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
