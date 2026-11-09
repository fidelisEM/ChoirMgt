import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../models/models.dart';
import '../../utils/logger.dart';
import 'choir_detail_screen.dart';
import 'create_choir_screen.dart';
import 'edit_choir_screen.dart';

class ChoirListScreen extends StatefulWidget {
  const ChoirListScreen({super.key});

  @override
  State<ChoirListScreen> createState() => _ChoirListScreenState();
}

class _ChoirListScreenState extends State<ChoirListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChoirs();
    });
  }

  void _loadChoirs() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );

    if (authController.currentUser != null) {
      choirController.loadChoirs(
        userId: authController.currentUser!.id,
        adminView: authController.isAdmin,
      );
    }
  }

  void _searchChoirs(String query) {
    Logger.debug('Search called with query: "$query"');
    // Just trigger a rebuild - filtering will be done in the build method
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choirs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            color: Colors.blue.withAlpha(50), // Make it visible
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search choirs...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: _searchChoirs,
            ),
          ),
        ),
      ),
      body: Consumer2<ChoirController, AuthController>(
        builder: (context, choirController, authController, child) {
          if (choirController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (choirController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading choirs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    choirController.errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      choirController.clearError();
                      _loadChoirs();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Filter choirs based on search query
          final allChoirs = choirController.choirs;
          Logger.debug('All choirs count: ${allChoirs.length}');
          Logger.debug('Search text: "${_searchController.text}"');

          final choirs = _searchController.text.isEmpty
              ? allChoirs
              : allChoirs.where((choir) {
                  final query = _searchController.text.toLowerCase();
                  final matches =
                      choir.name.toLowerCase().contains(query) ||
                      choir.description.toLowerCase().contains(query);
                  Logger.debug(
                    'Choir "${choir.name}" matches "$query": $matches',
                  );
                  return matches;
                }).toList();

          Logger.debug('Filtered choirs count: ${choirs.length}');

          if (choirs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No choirs found',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Create your first choir to get started'
                        : 'Try different search terms',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchController.text.isEmpty &&
                      authController.isAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateChoirDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Choir'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadChoirs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: choirs.length,
              itemBuilder: (context, index) {
                final choir = choirs[index];
                return _buildChoirCard(context, choir, authController);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AuthController>(
        builder: (context, authController, child) {
          if (!authController.isAdmin) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () => _showCreateChoirDialog(context),
            tooltip: 'Create New Choir',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildChoirCard(
    BuildContext context,
    ChoirModel choir,
    AuthController authController,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToChoirDetail(choir),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: choir.imageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              choir.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choir.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (choir.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            choir.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${choir.memberCount} members',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  if (choir.isActive)
                    _buildInfoChip(
                      icon: Icons.check_circle,
                      label: 'Active',
                      color: Colors.green,
                    )
                  else
                    _buildInfoChip(
                      icon: Icons.pause_circle,
                      label: 'Inactive',
                      color: Colors.orange,
                    ),
                  const Spacer(),
                  if (authController.isAdmin ||
                      choir.leaderId == authController.currentUser?.id)
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleChoirAction(context, choir, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (authController.isAdmin)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateChoirDialog(BuildContext context) {
    Get.to(() => const CreateChoirScreen())?.then((_) => _loadChoirs());
  }

  void _navigateToChoirDetail(ChoirModel choir) {
    Get.to(() => ChoirDetailScreen(choir: choir));
  }

  void _handleChoirAction(
    BuildContext context,
    ChoirModel choir,
    String action,
  ) {
    switch (action) {
      case 'edit':
        Get.to(() => EditChoirScreen(choir: choir))?.then((result) {
          if (result == true) {
            _loadChoirs();
          }
        });
        break;
      case 'delete':
        _showDeleteConfirmation(context, choir);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, ChoirModel choir) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Choir'),
        content: Text(
          'Are you sure you want to delete "${choir.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteChoir(choir);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteChoir(ChoirModel choir) async {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final success = await choirController.deleteChoir(choir.id);

    if (success) {
      Get.snackbar(
        'Success',
        'Choir deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        choirController.errorMessage ?? 'Failed to delete choir',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
