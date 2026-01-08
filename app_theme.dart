import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const primaryColor = Color(0xFF1976D2);
  static const secondaryColor = Color(0xFF00BCD4);
  static const accentColor = Color(0xFFFF5722);
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFFC107);
  static const errorColor = Color(0xFFF44336);
  
  static const backgroundColor = Color(0xFFFAFAFA);
  static const surfaceColor = Color(0xFFFFFFFF);
  
  static const dividerColor = Color(0xFFE0E0E0);
  static const borderColor = Color(0xFFBDBDBD);
  
  static const darkTextColor = Color(0xFF212121);
  static const lightTextColor = Color(0xFF757575);
  static const hintTextColor = Color(0xFFBDBDBD);

  // Light Theme
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    
    // Text Themes
    textTheme: TextTheme(
      displayLarge: _buildTextStyle(
        size: 32,
        weight: FontWeight.bold,
        height: 1.2,
      ),
      displayMedium: _buildTextStyle(
        size: 28,
        weight: FontWeight.bold,
        height: 1.2,
      ),
      displaySmall: _buildTextStyle(
        size: 24,
        weight: FontWeight.bold,
        height: 1.2,
      ),
      headlineLarge: _buildTextStyle(
        size: 22,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      headlineMedium: _buildTextStyle(
        size: 20,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: _buildTextStyle(
        size: 18,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: _buildTextStyle(
        size: 16,
        weight: FontWeight.w600,
        height: 1.5,
      ),
      titleMedium: _buildTextStyle(
        size: 14,
        weight: FontWeight.w600,
        height: 1.5,
      ),
      titleSmall: _buildTextStyle(
        size: 12,
        weight: FontWeight.w600,
        height: 1.5,
      ),
      bodyLarge: _buildTextStyle(
        size: 16,
        weight: FontWeight.normal,
        height: 1.5,
      ),
      bodyMedium: _buildTextStyle(
        size: 14,
        weight: FontWeight.normal,
        height: 1.5,
      ),
      bodySmall: _buildTextStyle(
        size: 12,
        weight: FontWeight.normal,
        height: 1.5,
      ),
      labelLarge: _buildTextStyle(
        size: 14,
        weight: FontWeight.w500,
        height: 1.5,
      ),
      labelMedium: _buildTextStyle(
        size: 12,
        weight: FontWeight.w500,
        height: 1.5,
      ),
      labelSmall: _buildTextStyle(
        size: 10,
        weight: FontWeight.w500,
        height: 1.5,
      ),
    ),
    
    // App Bar
    appBarTheme: AppBarTheme(
      elevation: 1,
      backgroundColor: surfaceColor,
      foregroundColor: darkTextColor,
      centerTitle: true,
      titleTextStyle: _buildTextStyle(
        size: 20,
        weight: FontWeight.w600,
        color: darkTextColor,
      ),
      iconTheme: const IconThemeData(
        color: darkTextColor,
        size: 24,
      ),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _buildTextStyle(
          size: 16,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: _buildTextStyle(
        size: 14,
        weight: FontWeight.normal,
        color: lightTextColor,
      ),
      hintStyle: _buildTextStyle(
        size: 14,
        weight: FontWeight.normal,
        color: hintTextColor,
      ),
      prefixIconColor: lightTextColor,
      suffixIconColor: lightTextColor,
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: dividerColor),
      ),
      color: surfaceColor,
      margin: EdgeInsets.zero,
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
    
    // Dialog Theme
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: surfaceColor,
      elevation: 4,
      titleTextStyle: _buildTextStyle(
        size: 20,
        weight: FontWeight.w600,
        color: darkTextColor,
      ),
      contentTextStyle: _buildTextStyle(
        size: 14,
        weight: FontWeight.normal,
        color: darkTextColor,
      ),
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
  );

  // Dark Theme
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
    ),
  );

  // Helper method to build text style
  static TextStyle _buildTextStyle({
    required double size,
    required FontWeight weight,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.tajawal(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }
}

// Custom Colors
class AppColors {
  static const primary = Color(0xFF1976D2);
  static const secondary = Color(0xFF00BCD4);
  static const accent = Color(0xFFFF5722);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);
  
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);
}
