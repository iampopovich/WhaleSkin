import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _boxName = 'settings';

  late Box _settingsBox;
  bool _isDarkMode = true; // По умолчанию темная тема

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme =>
      _isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;

  Future<void> init() async {
    _settingsBox = await Hive.openBox(_boxName);
    _isDarkMode = _settingsBox.get(_themeKey, defaultValue: true);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _settingsBox.put(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _settingsBox.put(_themeKey, _isDarkMode);
      notifyListeners();
    }
  }
}

class AppThemes {
  static const Color primaryColor = Color(0xFF4F9CF9);
  static const Color primaryVariant = Color(0xFF3A7BD5);

  // Темная тема (текущая)
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E2E),
      primary: primaryColor,
      secondary: primaryVariant,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1E1E2E),
    cardColor: const Color(0xFF2A2A3A),
    dividerColor: const Color(0xFF3A3A4A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A2A3A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF2A2A3A),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return const Color(0xFF64748B);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.5);
        }
        return const Color(0xFF3A3A4A);
      }),
    ),
  );

  // Светлая тема
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
      primary: primaryColor,
      secondary: primaryVariant,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: Color(0xFF475569), fontSize: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return const Color(0xFF94A3B8);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.3);
        }
        return const Color(0xFFE2E8F0);
      }),
    ),
  );
}

// Расширение для получения цветов в зависимости от темы
extension ThemeColors on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(this).cardColor;
  Color get textColor => Theme.of(this).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF1E293B);
  Color get subtitleColor => Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF475569);
  Color get borderColor => Theme.of(this).dividerColor;
  Color get hintColor => Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFF64748B)
      : const Color(0xFF94A3B8);
}
