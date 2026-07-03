import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/env_config.dart';
import 'controllers/attendance_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/choir_controller.dart';
import 'controllers/communication_controller.dart';
import 'controllers/fee_controller.dart';
import 'controllers/language_controller.dart';
import 'controllers/member_controller.dart';
import 'controllers/music_controller.dart';
import 'controllers/payment_controller.dart';
import 'controllers/report_controller.dart';
import 'l10n/l10n.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'services/database_setup_service.dart';
import 'services/music_sync_service.dart';
import 'utils/logger.dart';
import 'widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize global error handling
  GlobalErrorHandler.initialize();
  
  // Initialize configuration
  await AppConfig.initialize();
  await EnvConfig.instance.initialize();
  
  // Initialize logging
  Logger.info('App starting in ${AppConfig.environmentName} mode');
  
  if (!AppConfig.isConfigValid) {
    Logger.fatal(
      'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Build with '
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
      '(or --dart-define-from-file).',
    );
    runApp(const _ConfigErrorApp());
    return;
  }

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: EnvConfig.instance.getString('SUPABASE_URL'),
      anonKey: EnvConfig.instance.getString('SUPABASE_ANON_KEY'),
    );
    Logger.info('Supabase initialized successfully');
    
    // Initialize database tables
    await DatabaseSetupService.initializeDatabase();
    Logger.info('Database initialized');
    
    // Initialize music sync service
    await MusicSyncService.initialize();
    Logger.info('Music sync service initialized');
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Log configuration in development
    if (AppConfig.isDevelopment) {
      AppConfig.logConfig();
    }
    
    runApp(const ChoirManagementApp());
    Logger.info('App launched successfully');
    
  } catch (error, stackTrace) {
    Logger.fatal('Failed to initialize app', error, stackTrace);
  }
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'App is not configured: SUPABASE_URL and SUPABASE_ANON_KEY '
              'must be provided via --dart-define at build time.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class ChoirManagementApp extends StatelessWidget {
  const ChoirManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthController()),
          ChangeNotifierProvider(create: (_) => ChoirController()),
          ChangeNotifierProvider(create: (_) => MemberController()),
          ChangeNotifierProvider(create: (_) => AttendanceController()),
          ChangeNotifierProvider(create: (_) => FeeController()),
          ChangeNotifierProvider(create: (_) => PaymentController()),
          ChangeNotifierProvider(create: (_) => ReportController()),
          ChangeNotifierProvider(create: (_) => CommunicationController()),
          ChangeNotifierProvider(create: (_) => MusicController()),
          ChangeNotifierProvider(create: (_) => LanguageController()),
        ],
      child: Consumer<LanguageController>(
        builder: (context, languageController, child) {
          return GetMaterialApp(
            title: 'Choir Management System',
            debugShowCheckedModeBanner: false,
            locale: languageController.locale,
            supportedLocales: L10n.all,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFF475569)),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFF0F172A),
        ),
        home: const SplashScreen(),
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/register', page: () => const RegisterScreen()),
          GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        ],
          );
        },
      ),
      ),
    );
  }
}
