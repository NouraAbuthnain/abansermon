import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/mosque_repository.dart';
import '../../domain/mosque.dart';

/// Bottom sheet shown when a volunteer wants to record a sermon at an offline
/// mosque. Renders the 10 instructions, an agreement checkbox, and gates the
/// recording start until the user agrees and the mosque has no active recorder.
class RecordingTermsSheet extends ConsumerStatefulWidget {
  final Mosque mosque;

  const RecordingTermsSheet({super.key, required this.mosque});

  static Future<void> show(
    BuildContext context, {
    required Mosque mosque,
  }) {
    return AppBottomSheet.show<void>(
      context,
      title: 'discovery.terms.title'.tr(),
      child: RecordingTermsSheet(mosque: mosque),
    );
  }

  @override
  ConsumerState<RecordingTermsSheet> createState() =>
      _RecordingTermsSheetState();
}

class _RecordingTermsSheetState extends ConsumerState<RecordingTermsSheet> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.secondaryDarkBg : AppColors.pureWhite;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    // Watch the tick to force re-evaluation of isLive (heartbeat) periodically
    ref.watch(statusRefreshTickProvider);

    final liveMosque = ref.watch(mosqueRepositoryProvider.select((asyncList) {
      final list = asyncList.valueOrNull ?? [];
      for (final m in list) {
        if (m.id == widget.mosque.id) return m;
      }
      return widget.mosque;
    }));

    final isBusy = liveMosque.isBeingRecorded;

    // Dynamically load instructions from i18n
    final instructions = <String>[];
    int i = 1;
    while (true) {
      final key = 'discovery.terms.item$i';
      final text = key.tr();
      if (text == key || text.isEmpty) break;
      instructions.add(text);
      i++;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.mosque.name,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'discovery.terms.subtitle'.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.slate),
          ),
          if (isBusy) ...[
            const SizedBox(height: 12),
            _Banner(
              icon: Icons.error_outline,
              color: AppColors.error,
              message: 'discovery.terms.alreadyRecording'.tr(),
            ),
          ],
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: instructions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _InstructionRow(
                index: index + 1,
                text: instructions[index],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AgreementCheckbox(
            value: _agreed,
            onChanged: isBusy
                ? null
                : (val) => setState(() => _agreed = val ?? false),
            label: 'discovery.terms.agree'.tr(),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'discovery.terms.start'.tr(),
            onPressed: (_agreed && !isBusy)
                ? () => _onStart(context)
                : null,
            variant: AppButtonVariant.primary,
          ),
          SizedBox(height: bottomInset > 0 ? bottomInset : 16),
        ],
      ),
    );
  }

  void _onStart(BuildContext context) {
    // startRecording() is called on the capture screen when the volunteer
    // actually presses "Start Live Capture", not here. This keeps the mosque
    // status accurate — it only goes "active" when audio capture begins.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/capture/${widget.mosque.id}');
  }
}

class _AgreementCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;

  const _AgreementCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.primaryTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? AppColors.primaryTeal : (isDark ? Colors.white24 : Colors.black12),
                  width: 2,
                ),
              ),
              child: value
                  ? Center(
                      child: Image.asset(
                        'assets/icons/accept.png',
                        width: 14,
                        height: 14,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final int index;
  final String text;

  const _InstructionRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryTeal,
                AppColors.primaryTeal.withValues(alpha: 0.8),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontSize: 14,
                  color: isDark ? Colors.white.withOpacity(0.9) : AppColors.ink.withOpacity(0.8),
                ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/warning.png',
            width: 22,
            height: 22,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
