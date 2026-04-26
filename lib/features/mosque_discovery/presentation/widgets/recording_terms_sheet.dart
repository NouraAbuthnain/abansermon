import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordingTermsSheet(mosque: mosque),
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

    final liveMosque = ref.watch(mosqueRepositoryProvider.select((asyncList) {
      final list = asyncList.valueOrNull ?? [];
      for (final m in list) {
        if (m.id == widget.mosque.id) return m;
      }
      return widget.mosque;
    }));

    final isBusy = liveMosque.isBeingRecorded;

    final instructions = List<String>.generate(
      10,
      (i) => 'discovery.terms.item${i + 1}'.tr(),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.doveGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'discovery.terms.title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.mosque.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.accentGreen),
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
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: instructions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _InstructionRow(
                      index: index + 1,
                      text: instructions[index],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: isBusy
                      ? null
                      : (val) => setState(() => _agreed = val ?? false),
                  title: Text(
                    'discovery.terms.agree'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accentGreen,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'discovery.terms.start'.tr(),
                  onPressed: (_agreed && !isBusy)
                      ? () => _onStart(context)
                      : null,
                  variant: AppButtonVariant.primary,
                ),
              ],
            ),
          ),
        );
      },
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

class _InstructionRow extends StatelessWidget {
  final int index;
  final String text;

  const _InstructionRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.accentGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
