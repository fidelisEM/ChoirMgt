import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/language_controller.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../utils/app_translations.dart';
import 'custom_widgets.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.showAsBottomSheet = true});
  final bool showAsBottomSheet;

  @override
  Widget build(BuildContext context) {
    if (showAsBottomSheet) {
      return _buildBottomSheet(context);
    } else {
      return _buildInlineSelector(context);
    }
  }

  Widget _buildBottomSheet(BuildContext context) {
    return CustomBottomSheet(
      title: context.tr('selectLanguage'),
      child: _buildLanguageList(context),
    );
  }

  Widget _buildInlineSelector(BuildContext context) {
    return _buildLanguageList(context);
  }

  Widget _buildLanguageList(BuildContext context) {
    return Consumer<LanguageController>(
      builder: (context, languageController, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: L10n.all.map((locale) {
            final isSelected =
                languageController.locale.languageCode == locale.languageCode;

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () async {
                if (!isSelected) {
                  final success = await languageController.changeLanguage(
                    locale.languageCode,
                  );
                  if (success) {
                    if (showAsBottomSheet && context.mounted) {
                      Navigator.pop(context);
                    }
                    Get.snackbar(
                      context.tr('language'),
                      context.tr('languageChanged'),
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                    );
                  }
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        L10n.getFlag(locale.languageCode),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLocalizedLanguageName(
                            context,
                            locale.languageCode,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.gray800,
                          ),
                        ),
                        Text(
                          L10n.getLanguageName(locale.languageCode),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getLocalizedLanguageName(BuildContext context, String languageCode) {
    switch (languageCode) {
      case 'en':
        return context.tr('english');
      case 'sw':
        return context.tr('swahili');
      default:
        return context.tr('english');
    }
  }
}

class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageController>(
      builder: (context, languageController, child) {
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => const LanguageSelector(),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.getFlag(languageController.currentLanguageCode),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                L10n.getLanguageName(languageController.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.gray600,
              ),
            ],
          ),
        );
      },
    );
  }
}
