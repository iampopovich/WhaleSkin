import 'package:flutter/material.dart';
import 'theme_manager.dart';

class ThemeProvider extends InheritedWidget {
  final ThemeManager themeManager;

  const ThemeProvider({
    super.key,
    required this.themeManager,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  static ThemeManager themeManagerOf(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'ThemeProvider not found in context');
    return provider!.themeManager;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return true; // Всегда уведомляем об изменениях для темы
  }
}
