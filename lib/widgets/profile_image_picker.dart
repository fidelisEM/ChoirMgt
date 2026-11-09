import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import 'custom_widgets.dart';

class ProfileImagePicker extends StatefulWidget {
  const ProfileImagePicker({
    super.key,
    this.initialImage,
    this.initialImageUrl,
    required this.onImageSelected,
    this.size = 120,
    this.label,
    this.isRequired = false,
  });

  final File? initialImage;
  final String? initialImageUrl;
  final Function(dynamic)
  onImageSelected; // Changed to dynamic to support both File and Uint8List
  final double size;
  final String? label;
  final bool isRequired;

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  File? _selectedImage;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomBottomSheet(
          title: 'Select Photo',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only show camera option on mobile platforms
              if (!kIsWeb) ...[
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Camera',
                  subtitle: 'Take a new photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
              ],
              _buildImageSourceOption(
                icon: Icons.photo_library_rounded,
                title: kIsWeb ? 'Choose File' : 'Gallery',
                subtitle: kIsWeb
                    ? 'Select image from device'
                    : 'Choose from gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null ||
                  _webImageBytes != null ||
                  widget.initialImageUrl != null) ...[
                const SizedBox(height: 12),
                _buildImageSourceOption(
                  icon: Icons.delete_rounded,
                  title: 'Remove Photo',
                  subtitle: 'Remove current photo',
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                  isDestructive: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : AppColors.gray800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDestructive
                        ? AppColors.error.withValues(alpha: 0.7)
                        : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.gray400,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, work with bytes
          final Uint8List imageBytes = await image.readAsBytes();

          // Validate file size (max 5MB)
          const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB

          if (imageBytes.length > maxSizeInBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size must be less than 5MB'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          setState(() {
            _webImageBytes = imageBytes;
            _selectedImage = null; // Clear file reference for web
          });

          // Pass bytes for web
          widget.onImageSelected(imageBytes);
        } else {
          // For mobile, work with File
          final File imageFile = File(image.path);

          // Validate file size (max 5MB)
          final int fileSizeInBytes = await imageFile.length();
          const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB

          if (fileSizeInBytes > maxSizeInBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image size must be less than 5MB'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          setState(() {
            _selectedImage = imageFile;
            _webImageBytes = null; // Clear bytes for mobile
          });

          // Pass file for mobile
          widget.onImageSelected(imageFile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImageBytes = null;
    });
    widget.onImageSelected(null);
  }

  Widget _buildImageDisplay() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          image: _getImageProvider(),
        ),
        child: _getImageProvider() == null
            ? Icon(
                Icons.person_rounded,
                size: widget.size * 0.5,
                color: AppColors.gray400,
              )
            : null,
      ),
    );
  }

  DecorationImage? _getImageProvider() {
    if (kIsWeb && _webImageBytes != null) {
      return DecorationImage(
        image: MemoryImage(_webImageBytes!),
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _selectedImage != null) {
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(widget.initialImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              if (widget.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Stack(
            children: [
              _buildImageDisplay(),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedImage != null ||
                  _webImageBytes != null ||
                  widget.initialImageUrl != null
              ? 'Tap to change photo'
              : 'Tap to add photo',
          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
        ),
      ],
    );
  }
}
