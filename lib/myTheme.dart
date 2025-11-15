import 'package:flutter/material.dart';

class MyTheme {
  static ThemeData themeData(
      {required bool isDarkTheme, required BuildContext context}) {
    return isDarkTheme ? _buildDarkTheme() : _buildLightTheme();
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.indigo,
      primaryColor: Colors.indigo.shade700,
      primaryColorDark: Colors.indigo.shade900,
      primaryColorLight: Colors.indigo.shade200,
      scaffoldBackgroundColor: Colors.grey.shade100,
      canvasColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
      disabledColor: Colors.grey.shade400,
      hintColor: Colors.grey.shade600,
      shadowColor: Colors.grey.withOpacity(0.4),
      appBarTheme: AppBarTheme(
        color: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        titleTextStyle: TextStyle(
          color: Colors.grey.shade900,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo.shade700,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.indigo.shade700,
          side: BorderSide(color: Colors.indigo.shade700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade200,
        disabledColor: Colors.grey.shade300,
        selectedColor: Colors.indigo.shade700,
        secondarySelectedColor: Colors.indigo.shade700,
        labelStyle: const TextStyle(color: Colors.black),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.grey.shade800,
        textColor: Colors.grey.shade900,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.indigo.shade700,
        unselectedLabelColor: Colors.grey.shade600,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2,
            color: Colors.indigo.shade700,
          ),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.indigo.shade700,
        secondary: Colors.indigo.shade500,
        surface: Colors.white,
        background: Colors.grey.shade100,
        error: Colors.red.shade700,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.grey.shade900,
        onBackground: Colors.grey.shade900,
        onError: Colors.white,
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      primaryColor: Colors.indigo.shade500,
      primaryColorDark: Colors.indigo.shade800,
      primaryColorLight: Colors.indigo.shade200,
      scaffoldBackgroundColor: const Color(0xFF121212),
      canvasColor: const Color(0xFF1E1E1E),
      cardColor: const Color(0xFF242424),
      dividerColor: Colors.grey.shade800,
      disabledColor: Colors.grey.shade600,
      hintColor: Colors.grey.shade500,
      shadowColor: Colors.black.withOpacity(0.6),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF1E1E1E),
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo.shade300,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.indigo.shade300,
          side: BorderSide(color: Colors.indigo.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        disabledColor: const Color(0xFF3D3D3D),
        selectedColor: Colors.indigo.shade500,
        secondarySelectedColor: Colors.indigo.shade500,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.dark,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white,
        textColor: Colors.white,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.indigo.shade300,
        unselectedLabelColor: Colors.grey.shade500,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2,
            color: Colors.indigo.shade300,
          ),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.indigo,
        secondary: Colors.indigoAccent,
        surface: Color(0xFF242424),
        background: Color(0xFF121212),
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
    );
  }
}
