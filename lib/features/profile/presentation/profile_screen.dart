import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/presentation/widgets/scaffold_with_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/volunteer_profile_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../auth/presentation/widgets/legal_content_dialog.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/language_selector.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.role == UserRole.guest;
    final profileAsync = ref.watch(volunteerProfileProvider);
    final profile = profileAsync.valueOrNull;

    // Derive display values from Firestore profile
    final userName = isGuest
        ? 'profile.guest'.tr()
        : (profile?.fullName ?? 'Volunteer');
    final userPhone = isGuest
        ? ''
        : (profile?.phoneNumber ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '');
    final userInitial = isGuest
        ? 'G'
        : (profile?.initial ?? 'V');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final cardColor = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;
    final dividerColor = isDark
        ? AppColors.pureWhite.withOpacity(0.06)
        : AppColors.doveGray.withOpacity(0.25);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + NavBarHeight.of(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Profile Header ──
              _buildProfileHeader(context, cardColor, textColor, subtitleColor, isDark, isGuest, userName, userPhone, userInitial),
              const SizedBox(height: 24),

              // ── Volunteer CTA (Guest Only) ──
              if (isGuest) ...[
                _buildVolunteerCTA(context, isDark),
                const SizedBox(height: 24),
              ],

              // ── Navigation Section ──
              _buildSectionLabel('profile.sections.appSettings'.tr(), subtitleColor),
              const SizedBox(height: 8),
              _buildCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  _buildRow(
                    context,
                    icon: 'assets/icons/setting.png',
                    label: 'profile.nav.settings'.tr(),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                    onTap: () => context.push('/settings'),
                  ),
                  if (isGuest) ...[
                    _buildDivider(dividerColor),
                    _buildRow(
                      context,
                      icon: 'assets/icons/translate.png',
                      label: 'settings.language'.tr(),
                      trailingText: getLanguageName(ref.watch(settingsProvider).language),
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                      onTap: () => showLanguageSelector(context, ref),
                    ),
                  ],
                ],
                dividerColor: dividerColor,
              ),
              const SizedBox(height: 24),

              // ── Support Section ──
              _buildSectionLabel('profile.sections.support'.tr(), subtitleColor),
              const SizedBox(height: 8),
              _buildCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [

                  _buildRow(
                    context,
                    icon: 'assets/icons/support.png',
                    label: 'profile.support.help'.tr(),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                    onTap: () => context.push('/help-support'),
                  ),
                ],
                dividerColor: dividerColor,
              ),
              const SizedBox(height: 24),

              // ── About Section ──
              _buildSectionLabel('profile.sections.about'.tr(), subtitleColor),
              const SizedBox(height: 8),
              _buildCard(
                cardColor: cardColor,
                isDark: isDark,
                children: [
                  _buildRow(
                    context,
                    icon: 'assets/icons/information.png',
                    label: 'profile.about.aban'.tr(),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                    onTap: () => context.push('/about'),
                  ),
                  _buildDivider(dividerColor),
                  _buildRow(
                    context,
                    icon: 'assets/icons/google-docs.png',
                    label: 'profile.about.terms'.tr(),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                    onTap: () {
                      final lang = context.locale.languageCode;
                      String content = LegalTexts.termsEn;
                      if (lang == 'ar') content = LegalTexts.termsAr;
                      if (lang == 'ur') content = LegalTexts.termsUr;
                      if (lang == 'bn') content = LegalTexts.termsBn;
                      
                      LegalContentDialog.show(
                        context,
                        title: 'profile.about.terms'.tr(),
                        content: content,
                      );
                    },
                  ),
                  _buildDivider(dividerColor),
                  _buildRow(
                    context,
                    icon: 'assets/icons/privacy.png',
                    label: 'profile.about.privacy'.tr(),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                    onTap: () {
                      final lang = context.locale.languageCode;
                      String content = LegalTexts.privacyEn;
                      if (lang == 'ar') content = LegalTexts.privacyAr;
                      if (lang == 'ur') content = LegalTexts.privacyUr;
                      if (lang == 'bn') content = LegalTexts.privacyBn;
                      
                      LegalContentDialog.show(
                        context,
                        title: 'profile.about.privacy'.tr(),
                        content: content,
                      );
                    },
                  ),
                ],
                dividerColor: dividerColor,
              ),

              // ── Account Section (Signed-in Only) ──
              if (!isGuest) ...[
                const SizedBox(height: 24),
                _buildSectionLabel('profile.sections.account'.tr(), subtitleColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  isDark: isDark,
                  children: [
                    _buildRow(
                      context,
                      icon: 'assets/icons/sign-out.png',
                      label: 'profile.account.signOut'.tr(),
                      textColor: AppColors.error,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () async {
                        final bool? confirm = await AppDialog.show<bool>(
                          context,
                          type: AppDialogType.warning,
                          title: 'dialogs.signOut.title'.tr(),
                          message: 'dialogs.signOut.message'.tr(),
                          primaryLabel: 'dialogs.signOut.confirm'.tr(),
                          secondaryLabel: 'dialogs.signOut.cancel'.tr(),
                          isDestructive: true,
                          onPrimaryPressed: () => Navigator.pop(context, true),
                          onSecondaryPressed: () => Navigator.pop(context, false),
                        );

                        if (confirm == true) {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            AppDialog.show(
                              context,
                              type: AppDialogType.success,
                              title: 'dialogs.signOutSuccess.title'.tr(),
                              message: 'dialogs.signOutSuccess.message'.tr(),
                              primaryLabel: 'dialogs.signOutSuccess.logIn'.tr(),
                              onPrimaryPressed: () {
                                Navigator.pop(context);
                                context.go('/login');
                              },
                              secondaryLabel: 'dialogs.signOutSuccess.home'.tr(),
                              onSecondaryPressed: () {
                                Navigator.pop(context);
                                context.go('/home');
                              },
                            );
                          }
                        }
                      },
                    ),
                  ],
                  dividerColor: dividerColor,
                ),
              ],

              const SizedBox(height: 32),

              // ── App Info Footer ──
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'common.version'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: subtitleColor.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'common.teamLabel'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: subtitleColor.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Profile Header Card
  // ─────────────────────────────────────────────
  Widget _buildProfileHeader(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
    bool isGuest,
    String userName,
    String userPhone,
    String userInitial,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppStyles.cardShadow,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              userInitial,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
          ),
          const SizedBox(width: 16),

          // Name and Phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (userPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    userPhone,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (isGuest) ...[
                  const SizedBox(height: 2),
                  Text(
                    'profile.browsingAsGuest'.tr(),
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Edit Profile (signed-in only)
          if (!isGuest)
            AppIconButton(
              iconPath: 'assets/icons/edit.png',
              onPressed: () => context.push('/profile/edit'),
              size: 36,
              iconSize: 18,
              hasShadow: true,
              tooltip: 'profile.edit.title'.tr(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Volunteer CTA (Guest Only)
  // ─────────────────────────────────────────────
  Widget _buildVolunteerCTA(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/login'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.accentGreen.withOpacity(0.08)
              : AppColors.accentGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accentGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_add_rounded,
                  color: AppColors.accentGreen,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.cta.title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppColors.accentGreen
                              : AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'profile.cta.subtitle'.tr(),
                    style: TextStyle(
                      color: isDark ? AppColors.doveGray : AppColors.slate,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.accentGreen : AppColors.primaryTeal,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section Label
  // ─────────────────────────────────────────────
  Widget _buildSectionLabel(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section Card Container
  // ─────────────────────────────────────────────
  Widget _buildCard({
    required Color cardColor,
    required bool isDark,
    required List<Widget> children,
    required Color dividerColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppStyles.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  // ─────────────────────────────────────────────
  // Row Item
  // ─────────────────────────────────────────────
  Widget _buildRow(
    BuildContext context, {
    required String? icon,
    required String label,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
    String? trailingText,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (icon != null)
                  Image.asset(
                    icon,
                    width: 20,
                    height: 20,
                    color: isDestructive
                        ? AppColors.error
                        : (isDark ? AppColors.doveGray : AppColors.slate),
                  )
                else
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                if (!isDestructive)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: subtitleColor.withOpacity(0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Divider
  // ─────────────────────────────────────────────
  Widget _buildDivider(Color dividerColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 50, right: 16),
      child: Divider(height: 1, color: dividerColor),
    );
  }
}
