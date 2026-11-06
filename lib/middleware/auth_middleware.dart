import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../utils/security_helper.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    
    Logger.debug('AuthMiddleware: Checking route $route');
    Logger.debug('AuthMiddleware: Session exists: ${session != null}');
    
    // Public routes that don't require authentication
    final publicRoutes = ['/login', '/register', '/'];
    
    if (publicRoutes.contains(route)) {
      // If user is already authenticated and trying to access login/register
      if (session != null && (route == '/login' || route == '/register')) {
        Logger.navigation('AuthMiddleware', '/dashboard');
        return const RouteSettings(name: '/dashboard');
      }
      return null;
    }
    
    // Protected routes require authentication
    if (session == null) {
      Logger.navigation('AuthMiddleware', '/login');
      return const RouteSettings(name: '/login');
    }
    
    // Check if session is still valid
    if (session.expiresAt != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (session.expiresAt! < now) {
        Logger.warning('Session expired for user ${session.user.id}');
        supabase.auth.signOut();
        return const RouteSettings(name: '/login');
      }
    }
    
    // Check session timeout based on app config
    try {
      final sessionCreatedAt = DateTime.parse(session.user.createdAt);
      final sessionTimeout = Duration(hours: AppConfig.sessionTimeout);
      
      if (DateTime.now().difference(sessionCreatedAt) > sessionTimeout) {
        Logger.warning('Session timeout exceeded for user ${session.user.id}');
        supabase.auth.signOut();
        return const RouteSettings(name: '/login');
      }
    } catch (e) {
      Logger.error('Error parsing session creation time', e);
    }
    
    return null;
  }
}

class RoleMiddleware extends GetMiddleware {
  
  RoleMiddleware({
    required this.requiredRole,
    this.requiredPermission,
  });
  final String requiredRole;
  final String? requiredPermission;

  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      return const RouteSettings(name: '/login');
    }
    
    // Role for gating comes from the DB-verified cache populated by
    // AuthService.getCurrentUserProfile(), never from Supabase auth
    // user_metadata - that field is editable by the signed-in user
    // themselves via updateUser() and cannot be trusted for authorization.
    // If the cache hasn't been populated yet, fail closed to the lowest
    // privilege rather than defaulting to a role that grants access.
    final userRole = _roleToString(AuthService().cachedRole);

    Logger.debug('RoleMiddleware: User role: $userRole, Required: $requiredRole');
    
    // Check if user has required role
    if (!_hasRequiredRole(userRole, requiredRole)) {
      Logger.warning('User ${user.id} lacks required role: $requiredRole');
      Get.snackbar(
        'Access Denied',
        'You do not have permission to access this page',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return const RouteSettings(name: '/dashboard');
    }
    
    // Check specific permission if provided
    if (requiredPermission != null) {
      if (!SecurityHelper.hasPermission(userRole, requiredPermission!)) {
        Logger.warning('User ${user.id} lacks permission: $requiredPermission');
        Get.snackbar(
          'Access Denied',
          'You do not have permission to perform this action',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return const RouteSettings(name: '/dashboard');
      }
    }
    
    return null;
  }
  
  bool _hasRequiredRole(String userRole, String requiredRole) {
    // Role hierarchy: super_admin > admin > leader > member > guest
    const roleHierarchy = {
      'super_admin': 5,
      'admin': 4,
      'leader': 3,
      'member': 2,
      'guest': 1,
    };
    
    final userLevel = roleHierarchy[userRole] ?? 0;
    final requiredLevel = roleHierarchy[requiredRole] ?? 0;

    return userLevel >= requiredLevel;
  }
}

String _roleToString(UserRole? role) {
  switch (role) {
    case UserRole.superAdmin:
      return 'super_admin';
    case UserRole.admin:
      return 'admin';
    case UserRole.choirLeader:
      return 'leader';
    case UserRole.choirMember:
      return 'member';
    case null:
      return 'guest';
  }
}

class SecurityMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    // Rate limiting check (simplified)
    if (user != null) {
      final userId = user.id;
      if (SecurityHelper.isRateLimited(userId, 100, const Duration(minutes: 1))) {
        Logger.warning('Rate limit exceeded for user $userId');
        Get.snackbar(
          'Rate Limit Exceeded',
          'Too many requests. Please wait and try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return null; // Block the request
      }
    }
    
    // Security headers check (for web)
    if (GetPlatform.isWeb && AppConfig.isProduction) {
      // Additional web security checks could go here
    }
    
    return null;
  }
}

// Middleware for admin-only routes
class AdminMiddleware extends RoleMiddleware {
  AdminMiddleware() : super(requiredRole: 'admin');
}

// Middleware for leader and admin routes
class LeaderMiddleware extends RoleMiddleware {
  LeaderMiddleware() : super(requiredRole: 'leader');
}

// Middleware for authenticated users only
class MemberMiddleware extends RoleMiddleware {
  MemberMiddleware() : super(requiredRole: 'member');
}

// Custom middleware for payment management
class PaymentMiddleware extends RoleMiddleware {
  PaymentMiddleware() : super(
    requiredRole: 'leader',
    requiredPermission: 'manage_payments',
  );
}

// Custom middleware for user management
class UserManagementMiddleware extends RoleMiddleware {
  UserManagementMiddleware() : super(
    requiredRole: 'admin',
    requiredPermission: 'manage_users',
  );
}

// Custom middleware for reports access
class ReportsMiddleware extends RoleMiddleware {
  ReportsMiddleware() : super(
    requiredRole: 'leader',
    requiredPermission: 'view_reports',
  );
}