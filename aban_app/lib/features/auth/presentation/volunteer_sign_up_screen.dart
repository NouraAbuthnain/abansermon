import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_back_button.dart';

class VolunteerSignUpScreen extends StatefulWidget {
  const VolunteerSignUpScreen({super.key});

  @override
  State<VolunteerSignUpScreen> createState() => _VolunteerSignUpScreenState();
}

class _VolunteerSignUpScreenState extends State<VolunteerSignUpScreen> {
  String _documentType = 'National ID';
  bool _agreedToTerms = false;
  final List<String> _docTypes = ['National ID', 'Iqama', 'Passport'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header Image / Logo area
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                shape: BoxShape.circle,
                boxShadow: AppStyles.cardShadow,
              ),
              child: const Icon(Icons.person_add_outlined,
                  size: 32, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Volunteer Account',
              style: textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Register to help capture and translate khutbahs',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 32),

            // Form container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppStyles.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppTextField(
                    labelText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  const AppTextField(
                    labelText: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    hintText: '+966 5XXXXXXXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // Document Type Dropdown
                  Text(
                    'Document Type',
                    style: textTheme.labelLarge?.copyWith(
                          color: AppColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _documentType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate),
                        items: _docTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: textTheme.bodyLarge),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _documentType = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    labelText: '$_documentType Number',
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  const AppTextField(
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  const AppTextField(
                    labelText: 'Confirm Password',
                    prefixIcon: Icons.lock_clock_outlined,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Terms Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.primaryTeal,
                          onChanged: (val) {
                            setState(() => _agreedToTerms = val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I agree to the Terms and Privacy Policy',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'We ask for your ID to verify your volunteer identity and maintain platform trust.',
                              style: textTheme.labelLarge?.copyWith(
                                    color: AppColors.slate,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  AppButton(
                    label: 'Create Account',
                    onPressed: _agreedToTerms 
                        ? () => context.push('/otp') 
                        : null,
                    variant: AppButtonVariant.primary,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                            ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Log In',
                          style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
