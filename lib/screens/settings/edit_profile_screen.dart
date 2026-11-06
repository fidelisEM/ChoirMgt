import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_translations.dart';
import '../../utils/helpers.dart';
import '../../utils/logger.dart';
import '../../widgets/custom_widgets.dart';
// Platform-specific image picker
import 'profile_image_web.dart' if (dart.library.io) 'profile_image_io.dart' as image_picker;

class EditProfileScreen extends StatefulWidget {

  const EditProfileScreen({super.key, required this.user});
  final dynamic user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.user?.fullName ?? '';
    _emailController.text = widget.user?.email ?? '';
    _phoneController.text = widget.user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final currentUser = authController.currentUser ?? widget.user;
        
        return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profileEditTitle')),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _viewProfileImage(),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _selectedImageBytes != null 
                          ? MemoryImage(_selectedImageBytes!)
                          : (currentUser?.profileImageUrl != null && currentUser!.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(currentUser!.profileImageUrl!)
                              : null,
                      child: (_selectedImageBytes == null && (currentUser?.profileImageUrl?.isEmpty ?? true))
                          ? Text(
                              currentUser?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              context.tr('profileTapPhotoHint'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Form Fields
            CustomTextField(
              controller: _fullNameController,
              label: context.tr('fullName'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('profileFullNameRequired');
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _emailController,
              label: context.tr('emailAddress'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('profileEmailRequired');
                }
                if (!GetUtils.isEmail(value)) {
                  return context.tr('profileEnterValidEmail');
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _phoneController,
              label: context.tr('phoneNumber'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty && !GetUtils.isPhoneNumber(value)) {
                  return context.tr('profileEnterValidPhone');
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Save Profile Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
                label: Text(
                  _isLoading ? context.tr('profileSaving') : context.tr('profileSaveProfile'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Delete Account Section
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('profileDangerZone'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('profileDeleteAccountWarning'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.tr('profileDeleteAccount')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  void _viewProfileImage() {
    Logger.debug('_viewProfileImage called');
    final authController = Provider.of<AuthController>(context, listen: false);
    final currentUser = authController.currentUser ?? widget.user;
    String? imageUrl;
    
    if (_selectedImageBytes != null) {
      // Show selected image preview
      Get.dialog(
        Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  context.tr('profileSelectedImage'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400, maxWidth: 400),
                child: Image.memory(
                  _selectedImageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(context.tr('close')),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _changeProfilePicture();
                      },
                      child: Text(context.tr('profileChangeImage')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (currentUser?.profileImageUrl != null && currentUser!.profileImageUrl!.isNotEmpty) {
      // Show current profile image
      imageUrl = currentUser!.profileImageUrl!;
      Get.dialog(
        Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  context.tr('profileImageTitle'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400, maxWidth: 400),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(context.tr('profileImageLoadFailed')),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(context.tr('close')),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _changeProfilePicture();
                      },
                      child: Text(context.tr('profileChangeImage')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // No profile image, prompt to add one
      Get.dialog(
        AlertDialog(
          title: Text(context.tr('profileNoImage')),
          content: Text(context.tr('profileNoImagePrompt')),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _changeProfilePicture();
              },
              child: Text(context.tr('profileAddImage')),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      final imageBytes = await image_picker.ProfileImagePicker.pickImage();
      if (!mounted) return;

      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _selectedImageName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
        Helpers.showSuccessSnackbar(context.tr('profilePictureSelected'));
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackbar('${context.tr('profileImageSelectError')}: $e');
    }
  }

  void _saveProfile() async {
    Logger.debug('_saveProfile called');
    if (!_formKey.currentState!.validate()) return;
    
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      Logger.debug('Already loading, ignoring duplicate call');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      
      String? profileImageUrl;
      
      Logger.debug('_selectedImageBytes is ${_selectedImageBytes != null ? "NOT NULL" : "NULL"}');
      Logger.debug('_selectedImageName is ${_selectedImageName != null ? "NOT NULL" : "NULL"}');
      
      // Upload profile image if one was selected
      if (_selectedImageBytes != null && _selectedImageName != null) {
        Logger.debug('Uploading profile image...');
        profileImageUrl = await authController.uploadProfileImage(
          _selectedImageBytes!,
          _selectedImageName!,
        );
        Logger.debug('Upload result: $profileImageUrl');
        if (!mounted) return;

        if (profileImageUrl == null) {
          Helpers.showErrorSnackbar(context.tr('profileUploadFailed'));
          return;
        }
      } else {
        Logger.debug('No image selected for upload');
      }
      
      Logger.debug('About to call updateProfile with profileImageUrl: $profileImageUrl');
      
      // Update profile with all information
      final success = await authController.updateProfile(
        displayName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: profileImageUrl,
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        // Clear selected image bytes since it's now saved
        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
        });
        
        Helpers.showSuccessSnackbar(context.tr('profileUpdatedSuccess'));
        // Delay navigation to avoid navigation stack issues during rebuild
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Get.back(result: true); // Return true to indicate profile was updated
          }
        });
      } else {
        throw Exception('Failed to update profile');
      }

    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackbar('${context.tr('profileUpdateFailed')}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteAccount() {
    Get.dialog(
      AlertDialog(
        title: Text(
          context.tr('profileDeleteAccount'),
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          context.tr('profileDeleteAccountConfirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final confirmController = TextEditingController();
    Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.tr('settingsFinalConfirmation')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.tr('profileTypeDeleteToConfirm')} "DELETE" ${context.tr('profileToConfirmAccountDeletionSuffix')}'),
              const SizedBox(height: 16),
              CustomTextField(
                label: context.tr('profileTypeDeleteLabel'),
                controller: confirmController,
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: confirmController.text.trim() == 'DELETE'
                  ? () {
                      Get.back();
                      _performAccountDeletion();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('profileDeleteAccount')),
            ),
          ],
        ),
      ),
    ).whenComplete(confirmController.dispose);
  }

  Future<void> _performAccountDeletion() async {
    // Resolved before any await: the account is gone either way, so the
    // navigation below must not depend on this screen still being mounted.
    final deletedMsg = context.tr('profileAccountDeletedSuccess');
    final deleteRetryMsg = context.tr('profileAccountDeleteFailedRetry');
    final deleteFailedMsg = context.tr('profileAccountDeleteFailed');

    try {
      final authController = Provider.of<AuthController>(context, listen: false);

      // Show simple loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final success = await authController.deleteAccount();

      // Hide loading
      Get.back();

      if (success) {
        Helpers.showSuccessSnackbar(deletedMsg);
        // Navigate to login screen
        Get.offAllNamed('/login');
      } else {
        Helpers.showErrorSnackbar(deleteRetryMsg);
      }

    } catch (e) {
      // Hide loading if still showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Helpers.showErrorSnackbar('$deleteFailedMsg: $e');
    }
  }
}