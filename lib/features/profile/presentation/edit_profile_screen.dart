import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/volunteer_profile_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/language_selector.dart';
import '../../auth/presentation/widgets/common/auth_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(volunteerProfileProvider).valueOrNull;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      if (authState.userId == null) return;

      await ref.read(volunteerProfileRepositoryProvider).updateProfile(
            uid: authState.userId!,
            fullName: _nameController.text.trim(),
            preferredLanguage: ref.read(settingsProvider).language,
          );

      if (mounted) {
        AppDialog.show(
          context,
          type: AppDialogType.success,
          title: 'profile.edit.successTitle'.tr(),
          message: 'profile.edit.successMessage'.tr(),
          primaryLabel: 'common.ok'.tr(),
          onPrimaryPressed: () {
            Navigator.pop(context);
            context.pop();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context,
          type: AppDialogType.error,
          title: 'profile.edit.errorTitle'.tr(),
          message: 'profile.edit.errorMessage'.tr(),
          primaryLabel: 'common.ok'.tr(),
          onPrimaryPressed: () => Navigator.pop(context),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;
    final currentLanguageCode = ref.watch(settingsProvider).language;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'profile.edit.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Preview
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'V',
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name Field
              AuthTextField(
                labelText: 'profile.fields.fullName'.tr(),
                hintText: 'John Doe',
                controller: _nameController,
                prefixIconPath: 'assets/icons/user.png',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'auth.validation.fullNameEmpty'.tr();
                  }
                  if (val.trim().length < 3) {
                    return 'auth.validation.fullNameShort'.tr();
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Language Selector Row
              Text(
                'profile.fields.language'.tr(),
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withOpacity(0.9) : AppColors.ink.withOpacity(0.8),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showLanguageSelector(context, ref),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : AppColors.doveGray.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icons/translate.png',
                          width: 20,
                          height: 20,
                          color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            getLanguageName(currentLanguageCode),
                            style: textTheme.bodyLarge,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: subtitleColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              AuthPrimaryButton(
                label: 'common.save'.tr(),
                onPressed: _handleSave,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
