import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/providers/auth_provider.dart';
import '../domain/feedback.dart';
import '../data/feedback_repository.dart';

class FeedbackBottomSheet extends ConsumerStatefulWidget {
  final String khutbahId;

  const FeedbackBottomSheet({
    super.key,
    required this.khutbahId,
  });

  static Future<bool?> show(BuildContext context, String khutbahId) async {
    return await AppBottomSheet.show<bool>(
      context,
      title: 'feedback.title'.tr(),
      child: FeedbackBottomSheet(khutbahId: khutbahId),
    );
  }

  @override
  ConsumerState<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends ConsumerState<FeedbackBottomSheet> {
  int _rating = 0;
  final List<String> _selectedTags = [];
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  final List<String> _availableTags = [
    'Audio was unclear',
    'Translation delay',
    'Wrong translation',
    'Volume issues',
    'Great quality',
    'Easy to understand',
    'Helpful translation',
    'Voice too robotic',
  ];

  String _getRatingLabel(int rating) {
    if (rating == 0) return '';
    if (rating <= 2) return 'Poor';
    if (rating == 3) return 'Okay';
    if (rating == 4) return 'Good';
    return 'Excellent';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final userId = ref.read(authProvider).userId ?? 'guest';
    
    final feedback = UserFeedback(
      id: '', // Firestore will generate
      userId: userId,
      khutbahId: widget.khutbahId,
      rating: _rating,
      tags: _selectedTags,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await ref.read(feedbackRepositoryProvider).submitFeedback(feedback);
      if (!mounted) return;
      
      // Show success and close
      context.pop(true); // Close bottom sheet with success flag
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('feedback.successMessage'.tr()),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'feedback.errorMessage'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.pureWhite : AppColors.ink;
    final subtitleColor = isDark ? AppColors.doveGray : AppColors.slate;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your feedback helps improve translation quality.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtitleColor,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Rating Section
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected ? Colors.amber : subtitleColor.withOpacity(0.2),
                      size: 48,
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                _getRatingLabel(_rating),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),

        // Quick Feedback Section
        Text(
          'What could be better? (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: AppColors.accentGreen.withOpacity(0.2),
              checkmarkColor: AppColors.accentGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accentGreen : textColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.cloud,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.accentGreen : Colors.transparent,
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Optional Comment
        TextField(
          controller: _commentController,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: 'Additional comments (optional)',
            hintStyle: TextStyle(color: subtitleColor.withOpacity(0.4), fontSize: 14),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.cloud,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
        ),
        const SizedBox(height: 24),

        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],

        AppButton(
          label: 'Submit Feedback',
          onPressed: (_rating == 0 || _isSubmitting) ? null : _submit,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }
}
