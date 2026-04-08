import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  double textSize = 1.0;
  bool audioFirstMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const AppBackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('Accessibility'),
          _buildSettingCard(
            child: Column(
              children: [
                _buildSwitchTile('Dark Mode', Icons.dark_mode, darkMode,
                    (val) => setState(() => darkMode = val)),
                const Divider(height: 1),
                _buildSwitchTile(
                    'Audio-First Mode',
                    Icons.headset,
                    audioFirstMode,
                    (val) => setState(() => audioFirstMode = val),
                    subtitle: 'Auto-play translation audio on join'),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_fields,
                              color: AppColors.slate, size: 24),
                          const SizedBox(width: 16),
                          const Text('Text Size',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                        ],
                      ),
                      Slider(
                        value: textSize,
                        min: 0.8,
                        max: 2.0,
                        divisions: 4,
                        activeColor: AppColors.primaryTeal,
                        inactiveColor: AppColors.doveGray,
                        onChanged: (val) => setState(() => textSize = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('App Information'),
          _buildSettingCard(
            child: Column(
              children: [
                _buildListTile('Quran Reader', Icons.menu_book,
                    onTap: () => context.push('/quran')),
                const Divider(height: 1),
                _buildListTile('Provide Feedback', Icons.rate_review,
                    onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback flow opened')));
                }),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                const Text('Version 1.0.0-beta',
                    style: TextStyle(
                        color: AppColors.slate, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Designed with ❤️ by Noura Abuthnain',
                    style: TextStyle(color: AppColors.slate, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.slate,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile(
      String title, IconData icon, bool value, ValueChanged<bool> onChanged,
      {String? subtitle}) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.ink)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(color: AppColors.slate, fontSize: 12))
          : null,
      secondary: Icon(icon, color: AppColors.slate),
      value: value,
      activeColor: AppColors.pureWhite,
      activeTrackColor: AppColors.primaryTeal,
      inactiveThumbColor: AppColors.pureWhite,
      inactiveTrackColor: AppColors.doveGray,
      onChanged: onChanged,
    );
  }

  Widget _buildListTile(String title, IconData icon,
      {required VoidCallback onTap}) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.ink)),
      leading: Icon(icon, color: AppColors.slate),
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
      onTap: onTap,
    );
  }
}
