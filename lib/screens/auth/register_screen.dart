import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/profile_image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _choirSearchController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _logoScale;

  final ChoirController _choirController = Get.put(ChoirController());
  String? _selectedChoirId;
  List<ChoirModel> _filteredChoirs = [];
  bool _showChoirResults = false;
  dynamic _selectedImage; // Can be File (mobile) or Uint8List (web)
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
    _initializeChoirs();
    _isInitialized = true;
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.elasticOut),
    );
  }

  Future<void> _startAnimationSequence() async {
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _animationController.forward();
  }

  void _initializeChoirs() async {
    await _choirController.loadChoirs(adminView: true);
    setState(() {
      _filteredChoirs = _choirController.choirs;
    });
  }

  void _filterChoirs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChoirs = [];
        _showChoirResults = false;
      } else {
        _filteredChoirs = _choirController.choirs
            .where(
              (choir) => choir.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        _showChoirResults = _filteredChoirs.isNotEmpty;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_isInitialized) _backgroundController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _choirSearchController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        Get.snackbar(
          context.tr('error'),
          context.tr('passwordsDoNotMatch'),
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
        return;
      }

      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      final selectedChoir = _choirController.choirs.firstWhereOrNull(
        (c) => c.id == _selectedChoirId,
      );

      final success = await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: UserRole.choirMember,
        suggestedChoir: selectedChoir?.name ?? '',
        profileImage: _selectedImage,
      );

      if (success) {
        Get.offAllNamed('/dashboard');
      } else {
        if (mounted) {
          Get.snackbar(
            context.tr('registrationFailed'),
            authController.errorMessage ?? context.tr('tryAgain'),
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            icon: const Icon(Icons.error_outline, color: Colors.white),
          );
        }
      }
    }
  }

  Widget _buildChoirSearchField() {
    return Column(
      children: [
        CustomTextField(
          controller: _choirSearchController,
          label: context.tr('choirOptional'),
          hint: context.tr('searchChoirs'),
          prefixIcon: const Icon(
            Icons.music_note_rounded,
            color: AppColors.gray500,
          ),
          onChanged: _filterChoirs,
        ),
        if (_showChoirResults)
          Container(
            margin: const EdgeInsets.only(top: 12),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray300),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: _filteredChoirs.length,
              itemBuilder: (context, index) {
                final choir = _filteredChoirs[index];
                final isSelected = _selectedChoirId == choir.id;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _selectedChoirId = choir.id;
                        _choirSearchController.text = choir.name;
                        _showChoirResults = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.gray500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  choir.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.gray800,
                                  ),
                                ),
                                if (choir.description.isNotEmpty)
                                  Text(
                                    choir.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.7,
                                            )
                                          : AppColors.gray500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_selectedChoirId != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.1),
                  AppColors.success.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('choirSelected'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _choirController.choirs
                                .firstWhereOrNull(
                                  (c) => c.id == _selectedChoirId,
                                )
                                ?.name ??
                            'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChoirId = null;
                      _choirSearchController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _isInitialized
                ? _backgroundController
                : _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.1),
                      AppColors.primary.withValues(alpha: 0.05),
                      AppColors.backgroundGradient.colors[1],
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating Elements
          ...List.generate(
            ResponsiveUtils.getFloatingElementCount(context),
            (index) => _buildFloatingElement(index),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: ResponsiveUtils.responsiveContainer(
                context: context,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          children: [
                            SizedBox(
                              height: ResponsiveUtils.getSpacing(
                                context,
                                mobile: 20,
                                tablet: 40,
                                desktop: 60,
                              ),
                            ),

                            // Back Button
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Get.back(),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.glassBorder,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.shadowLight,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.gray300
                                          : AppColors.gray700,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Animated Logo
                            AnimatedBuilder(
                              animation: _isInitialized
                                  ? _backgroundController
                                  : _animationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScale.value,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.secondaryGradient,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.secondary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_add_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // Welcome Text
                            Text(
                              context.tr('joinUs'),
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(
                                  context,
                                  mobile: 28,
                                  tablet: 32,
                                  desktop: 36,
                                ),
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray800,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              context.tr('createAccountSubtitle'),
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                                color: AppColors.gray500,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 48),

                            // Register Form
                            GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Profile Image Picker
                                    ProfileImagePicker(
                                      onImageSelected: (dynamic image) {
                                        setState(() {
                                          _selectedImage = image;
                                        });
                                      },
                                      label: context.tr('profilePhoto'),
                                      size: ResponsiveUtils.getSpacing(
                                        context,
                                        mobile: 100,
                                        tablet: 120,
                                        desktop: 140,
                                      ),
                                    ),

                                    SizedBox(
                                      height: ResponsiveUtils.getSpacing(
                                        context,
                                        mobile: 24,
                                        tablet: 28,
                                        desktop: 32,
                                      ),
                                    ),

                                    CustomTextField(
                                      controller: _fullNameController,
                                      label: context.tr('fullName'),
                                      hint: context.tr('enterFullName'),
                                      prefixIcon: const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.gray500,
                                      ),
                                      validator: (value) => Validators.required(
                                        value,
                                        context.tr('fullName'),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    CustomTextField(
                                      controller: _emailController,
                                      label: context.tr('emailAddress'),
                                      hint: context.tr('enterEmail'),
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: const Icon(
                                        Icons.email_rounded,
                                        color: AppColors.gray500,
                                      ),
                                      validator: Validators.email,
                                    ),

                                    const SizedBox(height: 20),

                                    CustomTextField(
                                      controller: _phoneController,
                                      label: context.tr('phoneNumber'),
                                      hint: context.tr('enterPhoneNumber'),
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: const Icon(
                                        Icons.phone_rounded,
                                        color: AppColors.gray500,
                                      ),
                                      validator: (value) => Validators.required(
                                        value,
                                        context.tr('phoneNumber'),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    _buildChoirSearchField(),

                                    const SizedBox(height: 20),

                                    CustomTextField(
                                      controller: _passwordController,
                                      label: context.tr('password'),
                                      hint: context.tr('enterPassword'),
                                      obscureText: true,
                                      prefixIcon: const Icon(
                                        Icons.lock_rounded,
                                        color: AppColors.gray500,
                                      ),
                                      validator: (value) =>
                                          Validators.password(value),
                                    ),

                                    const SizedBox(height: 20),

                                    CustomTextField(
                                      controller: _confirmPasswordController,
                                      label: context.tr('confirmPassword'),
                                      hint: context.tr('confirmPassword'),
                                      obscureText: true,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: AppColors.gray500,
                                      ),
                                      validator: (value) => Validators.required(
                                        value,
                                        context.tr('confirmPassword'),
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    Consumer<AuthController>(
                                      builder:
                                          (context, authController, child) {
                                            return GradientButton(
                                              text: context.tr('createAccount'),
                                              onPressed:
                                                  authController.isLoading
                                                  ? null
                                                  : _register,
                                              isLoading:
                                                  authController.isLoading,
                                              width: double.infinity,
                                              height: 56,
                                              gradient:
                                                  AppColors.secondaryGradient,
                                            );
                                          },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Sign In Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('alreadyHaveAccount'),
                                  style: const TextStyle(
                                    color: AppColors.gray600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Get.back(),
                                  child: Text(
                                    context.tr('signIn'),
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElement(int index) {
    final random = index * 52.34;
    final size = 25.0 + (random % 35);
    final left = (random * 14) % MediaQuery.of(context).size.width;
    final top = (random * 18) % MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _isInitialized ? _backgroundController : _animationController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity:
                ResponsiveUtils.getFloatingElementOpacity(context) *
                _fadeIn.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: index % 3 == 0
                    ? AppColors.secondaryGradient
                    : index % 3 == 1
                    ? AppColors.primaryGradient
                    : const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
