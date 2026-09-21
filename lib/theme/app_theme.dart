import 'package:flutter/material.dart';

/// Next-Gen Modern Fintech Theme
/// High-contrast, sophisticated glassmorphism, vibrant functional gradients
class AppTheme {
  // Brand Palette
  static const Color primaryColor = Color(0xFF6366F1); // Indigo Primary
  static const Color primaryLightColor = Color(0xFF818CF8);
  static const Color primaryDarkColor = Color(0xFF4F46E5);

  static const Color secondaryColor = Color(0xFF10B981); // Emerald Emerald
  static const Color accentColor = Color(0xFFF59E0B); // Amber Accent
  static const Color accentSecondary = Color(0xFFEC4899); // Pink Accent

  // Semantic Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  static const Color spentColor = Color(0xFFF43F5E);
  static const Color budgetColor = Color(0xFF6366F1);

  // Surface & Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF090D16);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF131B2E);
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
  static const List<Color> successGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> dangerGradient = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const List<Color> goldGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const List<Color> glassDarkGradient = [Color(0xFF1E293B), Color(0xFF0F172A)];
  static const List<Color> cyanGradient = [Color(0xFF06B6D4), Color(0xFF3B82F6)];

  // Spacing & Radius
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double radiusL = 28.0;

  // Animations
  static const Duration animationFast = Duration(milliseconds: 250);
  static const Duration animationMedium = Duration(milliseconds: 350);

  // Shadow Styles
  static List<BoxShadow> shadowSmall = [
    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  
  static List<BoxShadow> shadowLarge = [
    BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 28, offset: const Offset(0, 10)),
  ];

  // Typography
  static const TextStyle displayLarge = TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1.5);
  static const TextStyle heading1 = TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0);
  static const TextStyle heading2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static const TextStyle heading3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static const TextStyle heading4 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B));
  static const TextStyle buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);

  // Card Decoration Helper
  static BoxDecoration cardDecoration(BuildContext context, {Color? customColor, double? radius, List<BoxShadow>? shadow}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: customColor ?? (isDark ? cardDark : cardLight),
      borderRadius: BorderRadius.circular(radius ?? radiusL),
      border: Border.all(
        color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8),
      ),
      boxShadow: shadow ?? shadowSmall,
    );
  }

  static ThemeData getTheme(bool isDark) {
    final ColorScheme colorScheme = isDark 
      ? const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: cardDark,
          error: errorColor,
          onPrimary: Colors.white,
          onSurface: textPrimaryDark,
        )
      : const ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: cardLight,
          error: errorColor,
          onPrimary: Colors.white,
          onSurface: textPrimaryLight,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      fontFamily: 'Inter',
      
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusL)),
        color: isDark ? cardDark : cardLight,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: (isDark ? heading3.copyWith(color: textPrimaryDark) : heading3.copyWith(color: textPrimaryLight)),
        iconTheme: IconThemeData(color: isDark ? textPrimaryDark : textPrimaryLight),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceDark : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: buttonText,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? cardDark : cardLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => getTheme(false);
  static ThemeData get darkTheme => getTheme(true);
}
