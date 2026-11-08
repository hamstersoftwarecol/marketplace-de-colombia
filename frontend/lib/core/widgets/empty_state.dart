import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? message;
  final String? actionLabel;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.search_off_outlined,
    this.title = 'No hay resultados',
    this.subtitle,
    this.message,
    this.actionLabel,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSubtitle = subtitle ?? message;
    final effectiveActionLabel = actionLabel ?? buttonText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (effectiveSubtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                effectiveSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (effectiveActionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(effectiveActionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
