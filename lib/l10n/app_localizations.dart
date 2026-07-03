import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Choir Management System'**
  String get appName;

  /// The subtitle of the application
  ///
  /// In en, this message translates to:
  /// **'Harmony in Organization'**
  String get appSubtitle;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Welcome back message
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Welcome back subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your musical journey'**
  String get welcomeBackSubtitle;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email address label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Email hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Don't have account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Already have account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Dashboard tab label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Choirs tab label
  ///
  /// In en, this message translates to:
  /// **'Choirs'**
  String get choirs;

  /// Members tab label
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// Attendance tab label
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// Payments tab label
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// Reports tab label
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Overview section title
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Recent activity section title
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Total members stat label
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// Active choirs stat label
  ///
  /// In en, this message translates to:
  /// **'Active Choirs'**
  String get activeChoirs;

  /// This week label
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Collections label
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// This month label
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// Add member action
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// Take attendance action
  ///
  /// In en, this message translates to:
  /// **'Take Attendance'**
  String get takeAttendance;

  /// Record payment action
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// View reports action
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// My profile action
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// My attendance action
  ///
  /// In en, this message translates to:
  /// **'My Attendance'**
  String get myAttendance;

  /// Payment history action
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// Notifications action
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No recent activity message
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// Activity will appear message
  ///
  /// In en, this message translates to:
  /// **'Activity will appear here as you use the system'**
  String get activityWillAppear;

  /// Access restricted title
  ///
  /// In en, this message translates to:
  /// **'Access Restricted'**
  String get accessRestricted;

  /// No permission message
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to access this section.'**
  String get noPermission;

  /// Restricted label
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get restricted;

  /// Profile label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Logout label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Account menu title
  ///
  /// In en, this message translates to:
  /// **'Account Menu'**
  String get accountMenu;

  /// Administrator role
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// Choir leader role
  ///
  /// In en, this message translates to:
  /// **'Choir Leader'**
  String get choirLeader;

  /// Choir member role
  ///
  /// In en, this message translates to:
  /// **'Choir Member'**
  String get choirMember;

  /// Google label
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// Apple label
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Google sign in coming soon message
  ///
  /// In en, this message translates to:
  /// **'Google Sign In will be available soon'**
  String get googleSignInSoon;

  /// Apple sign in coming soon message
  ///
  /// In en, this message translates to:
  /// **'Apple Sign In will be available soon'**
  String get appleSignInSoon;

  /// OR divider text
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Login failed title
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// Check credentials message
  ///
  /// In en, this message translates to:
  /// **'Please check your credentials and try again'**
  String get checkCredentials;

  /// Profile screen coming soon message
  ///
  /// In en, this message translates to:
  /// **'Profile screen coming soon!'**
  String get profileScreenSoon;

  /// Settings screen coming soon message
  ///
  /// In en, this message translates to:
  /// **'Settings screen coming soon!'**
  String get settingsScreenSoon;

  /// Quick action menu coming soon message
  ///
  /// In en, this message translates to:
  /// **'Quick action menu coming soon!'**
  String get quickActionMenuSoon;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Swahili language name
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get swahili;

  /// Language changed success message
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// Welcome back with name
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBackName;

  /// Attendance percentage label
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendancePercentage;

  /// Plus count this month
  ///
  /// In en, this message translates to:
  /// **'+{count} this month'**
  String plusThisMonth(int count);

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No members message
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembers;

  /// Managing label
  ///
  /// In en, this message translates to:
  /// **'Managing'**
  String get managing;

  /// No choirs message
  ///
  /// In en, this message translates to:
  /// **'No choirs'**
  String get noChoirs;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
