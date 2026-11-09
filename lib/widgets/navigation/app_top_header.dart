import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../theme/music_library_theme.dart';
import '../../utils/app_translations.dart';

/// Desktop top header shown above the page content next to [AppSidebar]:
/// a search field on the left, notification bell and user identity on the
/// right.
class AppTopHeader extends StatelessWidget {
  const AppTopHeader({
    super.key,
    required this.user,
    this.searchHint,
    this.onSearchChanged,
    this.onNotificationsTap,
    this.onProfileTap,
    this.notificationCount = 0,
  });

  final UserModel user;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final int notificationCount;

  String _roleLabel(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return context.tr('superAdministrator');
      case UserRole.admin:
        return context.tr('navRoleAdmin');
      case UserRole.choirLeader:
        return context.tr('choirLeader');
      case UserRole.choirMember:
        return context.tr('choirMember');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : 'U';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: MusicLibraryColors.card,
        border: Border(bottom: BorderSide(color: MusicLibraryColors.border)),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, minWidth: 220),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: MusicLibraryColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MusicLibraryColors.border),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: mlText(size: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  hintText: searchHint ?? context.tr('navSearchHint'),
                  hintStyle: mlText(
                    size: 13,
                    color: MusicLibraryColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: MusicLibraryColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          _NotificationBell(
            count: notificationCount,
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: MusicLibraryColors.primary,
                    backgroundImage: (user.profileImageUrl?.isNotEmpty == true)
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: (user.profileImageUrl?.isNotEmpty == true)
                        ? null
                        : Text(
                            initial,
                            style: mlText(
                              size: 13,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.fullName.isEmpty
                            ? context.tr('navUserFallback')
                            : user.fullName,
                        style: mlText(size: 13, weight: FontWeight.w600),
                      ),
                      Text(
                        _roleLabel(context, user.role),
                        style: mlText(
                          size: 11,
                          color: MusicLibraryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: MusicLibraryColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: MusicLibraryColors.textSecondary,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MusicLibraryColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
