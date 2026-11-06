import 'package:flutter/material.dart';

import '../../screens/home/dashboard_screen.dart' show NavItem;
import '../../theme/music_library_theme.dart';
import '../../utils/app_translations.dart';

/// Persistent desktop navigation sidebar. Shown in place of the mobile
/// bottom nav bar once the window is wide enough (see
/// [ResponsiveUtils.isDesktop]) so the same navigation stays reachable
/// without a redesign of every other tab.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.canAccess,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool Function(int index) canAccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: MusicLibraryColors.sidebarDark,
      child: SafeArea(
        right: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: MusicLibraryColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.church, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('navAppName'),
                      style: mlText(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedIndex;
                  final enabled = canAccess(index);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isSelected
                          ? MusicLibraryColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: enabled ? () => onSelect(index) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                enabled ? items[index].icon : Icons.lock_outline,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : enabled
                                        ? Colors.white70
                                        : Colors.white30,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  items[index].label,
                                  style: mlText(
                                    size: 14,
                                    weight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : enabled
                                            ? Colors.white70
                                            : Colors.white30,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
