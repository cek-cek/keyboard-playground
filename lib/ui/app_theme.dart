/// Kid-friendly theme for Keyboard Playground.
///
/// Provides high-contrast colors, large fonts, and accessible styling that's
/// appropriate for children using the application.
library;

import 'package:flutter/material.dart';

/// Application theme configuration.
///
/// Defines a dark theme optimized for kids with:
/// - High contrast colors for better visibility
/// - Large fonts (minimum 18px) for readability
/// - Smooth animations and transitions
/// - Bright, friendly color palette
///
/// Example usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.kidFriendlyTheme,
///   home: MyHomePage(),
/// )
/// ```
class AppTheme {
  /// Private constructor to prevent instantiation.
  AppTheme._();

  /// Kid-friendly dark theme with high contrast and large fonts.
  static ThemeData get kidFriendlyTheme {
    // Define color palette
    const primaryColor = Color(0xFF2196F3); // Bright blue
    const secondaryColor = Color(0xFF4CAF50); // Bright green
    const surfaceColor = Color(0xFF1E1E1E); // Slightly lighter surface

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: Color(0xFFFF5252), // Bright red for errors
        // ignore: avoid_redundant_argument_values
        onPrimary: Colors.white,
        // ignore: avoid_redundant_argument_values
        onSecondary: Colors.white,
        // ignore: avoid_redundant_argument_values
        onSurface: Colors.white,
        // ignore: avoid_redundant_argument_values
        onError: Colors.white,
      ),

      // Text theme with large, readable fonts
      textTheme: const TextTheme(
        // Display styles (largest)
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),

        // Headline styles
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),

        // Title styles
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),

        // Body styles (main content)
        bodyLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),

        // Label styles (buttons, etc.)
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          minimumSize: const Size(100, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(80, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(90, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(width: 2),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white70,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        size: 32,
        color: Colors.white,
      ),

      // App bar theme (if used)
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          size: 28,
          color: Colors.white,
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        thickness: 2,
        space: 16,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Animation duration
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Bright blue color for primary UI elements.
  static const brightBlue = Color(0xFF2196F3);

  /// Bright green color for success and positive actions.
  static const brightGreen = Color(0xFF4CAF50);

  /// Bright red color for errors and warnings.
  static const brightRed = Color(0xFFFF5252);

  /// Bright yellow color for highlights.
  static const brightYellow = Color(0xFFFFC107);

  /// Bright orange color for warm accents.
  static const brightOrange = Color(0xFFFF9800);

  /// Bright purple color for creative elements.
  static const brightPurple = Color(0xFF9C27B0);

  /// Bright pink color for playful elements.
  static const brightPink = Color(0xFFE91E63);

  /// Bright cyan color for cool accents.
  static const brightCyan = Color(0xFF00BCD4);

  /// Blue to green gradient for calming backgrounds.
  static const blueGreenGradient = LinearGradient(
    colors: [brightBlue, brightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Orange to pink gradient for warm, sunset-like backgrounds.
  static const sunsetGradient = LinearGradient(
    colors: [brightOrange, brightPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Blue to cyan gradient for ocean-themed backgrounds.
  static const oceanGradient = LinearGradient(
    colors: [brightBlue, brightCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Green to cyan gradient for forest-themed backgrounds.
  static const forestGradient = LinearGradient(
    colors: [brightGreen, brightCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
