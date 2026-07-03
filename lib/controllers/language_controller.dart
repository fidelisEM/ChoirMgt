import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class LanguageController extends ChangeNotifier {

  LanguageController() {
    _loadLanguage();
  }
  Locale _locale = const Locale('en');
  bool _isLoading = false;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  static const String _languageKey = 'selected_language';

  Future<void> _loadLanguage() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      
      _locale = Locale(languageCode);
      Logger.info('Language loaded: $languageCode');
      
    } catch (error) {
      Logger.error('Failed to load language', error);
      _locale = const Locale('en'); // Default to English
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changeLanguage(String languageCode) async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      _locale = Locale(languageCode);
      
      Logger.info('Language changed to: $languageCode');
      
      return true;
    } catch (error) {
      Logger.error('Failed to change language', error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetToDefault() async {
    await changeLanguage('en');
  }

  String get currentLanguageCode => _locale.languageCode;
  
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isSwahili => _locale.languageCode == 'sw';
}