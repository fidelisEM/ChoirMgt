import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
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

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authController = Provider.of<AuthController>(context, listen: false);
      
      final success = await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        Get.offAllNamed('/dashboard');
      } else {
        if (mounted) {
          Get.snackbar(
            context.tr('loginFailed'),
            authController.errorMessage ?? context.tr('checkCredentials'),
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            icon: const Icon(Icons.error_outline, color: Colors.white),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.secondary.withValues(alpha: 0.05),
                      AppColors.backgroundGradient.colors[1],
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Floating Elements
          ...List.generate(ResponsiveUtils.getFloatingElementCount(context), (index) => _buildFloatingElement(index)),
          
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
                            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 40, tablet: 60, desktop: 80)),
                            
                            // Animated Logo
                          AnimatedBuilder(
                            animation: _backgroundController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Welcome Text
                          Text(
                            context.tr('welcomeBack'),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context, mobile: 28, tablet: 32, desktop: 36),
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            context.tr('welcomeBackSubtitle'),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                              color: AppColors.gray500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Login Form
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  CustomTextField(
                                    controller: _emailController,
                                    label: context.tr('emailAddress'),
                                    hint: context.tr('enterEmail'),
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: const Icon(Icons.email_rounded, color: AppColors.gray500),
                                    validator: Validators.email,
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  CustomTextField(
                                    controller: _passwordController,
                                    label: context.tr('password'),
                                    hint: context.tr('enterPassword'),
                                    obscureText: true,
                                    prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.gray500),
                                    validator: (value) => Validators.required(value, context.tr('password')),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                      ),
                                      child: Text(
                                        context.tr('forgotPassword'),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  Consumer<AuthController>(
                                    builder: (context, authController, child) {
                                      return GradientButton(
                                        text: context.tr('signIn'),
                                        onPressed: authController.isLoading ? null : _login,
                                        isLoading: authController.isLoading,
                                        width: double.infinity,
                                        height: 56,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.gray300,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  context.tr('or'),
                                  style: const TextStyle(
                                    color: AppColors.gray500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.gray300,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Social Login Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Consumer<AuthController>(
                                  builder: (context, authController, child) {
                                    return GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      onTap: authController.isLoading ? null : () async {
                                        final success = await authController.signInWithGoogle();
                                        if (success && mounted) {
                                          Get.offAllNamed('/dashboard');
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.g_mobiledata,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            context.tr('google'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: authController.isLoading 
                                                  ? AppColors.gray400 
                                                  : AppColors.gray700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Consumer<AuthController>(
                                  builder: (context, authController, child) {
                                    return GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      onTap: authController.isLoading ? null : () async {
                                        final success = await authController.signInWithApple();
                                        if (success && mounted) {
                                          Get.offAllNamed('/dashboard');
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: AppColors.gray800,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.apple,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            context.tr('apple'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: authController.isLoading 
                                                  ? AppColors.gray400 
                                                  : AppColors.gray700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.tr('dontHaveAccount'),
                                style: const TextStyle(color: AppColors.gray600),
                              ),
                              GestureDetector(
                                onTap: () => Get.to(() => const RegisterScreen()),
                                child: Text(
                                  context.tr('signUp'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
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
    final random = index * 45.67;
    final size = 30.0 + (random % 40);
    final left = (random * 12) % MediaQuery.of(context).size.width;
    final top = (random * 15) % MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: ResponsiveUtils.getFloatingElementOpacity(context) * _fadeIn.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: index % 2 == 0 
                    ? AppColors.primaryGradient 
                    : AppColors.secondaryGradient,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}