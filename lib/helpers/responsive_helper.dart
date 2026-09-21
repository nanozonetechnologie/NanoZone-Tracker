import 'package:flutter/material.dart';

/// Responsive Helper for different screen sizes
/// Works with Samsung S25 FE (6.7" display), small phones, tablets, etc.
class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textScaleFactor;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late bool isSmallScreen;
  static late bool isMediumScreen;
  static late bool isLargeScreen;
  static late bool isTablet;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // Base block sizes (1% of screen)
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    // Text scale factor from system settings
    final textScaler = _mediaQueryData.textScaler;
    textScaleFactor = textScaler.scale(1.0).clamp(0.8, 1.3);

    // Safe area calculations
    safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;

    // Screen size categories
    isSmallScreen = screenWidth < 360;
    isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    isLargeScreen = screenWidth >= 400;
    isTablet = screenWidth >= 600;
  }

  /// Get responsive width (percentage of screen width)
  static double width(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  /// Get responsive height (percentage of screen height)
  static double height(double percentage) {
    return blockSizeVertical * percentage;
  }

  /// Get responsive font size
  static double fontSize(double size) {
    // Base design is 375px width (iPhone SE size)
    final scaleFactor = screenWidth / 375;
    final responsiveSize = size * scaleFactor.clamp(0.85, 1.25);
    return responsiveSize * textScaleFactor;
  }

  /// Get responsive spacing/padding
  static double space(double size) {
    final scaleFactor = screenWidth / 375;
    return size * scaleFactor.clamp(0.8, 1.3);
  }

  /// Get responsive icon size
  static double iconSize(double size) {
    final scaleFactor = screenWidth / 375;
    return size * scaleFactor.clamp(0.85, 1.2);
  }

  /// Get responsive radius
  static double radius(double size) {
    final scaleFactor = screenWidth / 375;
    return size * scaleFactor.clamp(0.9, 1.15);
  }

  /// Get grid crossAxisCount based on screen width
  static int gridColumns({int small = 2, int medium = 2, int large = 3, int tablet = 4}) {
    if (isTablet) return tablet;
    if (isLargeScreen) return large;
    if (isMediumScreen) return medium;
    return small;
  }

  /// Get grid aspect ratio based on screen size
  static double gridAspectRatio({double small = 0.9, double medium = 0.95, double large = 1.0}) {
    if (isTablet) return 1.1;
    if (isLargeScreen) return large;
    if (isMediumScreen) return medium;
    return small;
  }

  /// Responsive EdgeInsets
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(space(all));
    }
    return EdgeInsets.only(
      left: space(left ?? horizontal ?? 0),
      right: space(right ?? horizontal ?? 0),
      top: space(top ?? vertical ?? 0),
      bottom: space(bottom ?? vertical ?? 0),
    );
  }

  /// Responsive symmetric EdgeInsets
  static EdgeInsets paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: space(horizontal),
      vertical: space(vertical),
    );
  }

  /// Responsive SizedBox for horizontal spacing
  static SizedBox horizontalSpace(double width) {
    return SizedBox(width: space(width));
  }

  /// Responsive SizedBox for vertical spacing
  static SizedBox verticalSpace(double height) {
    return SizedBox(height: space(height));
  }
}

/// Extension for responsive values
extension ResponsiveExtension on num {
  /// Responsive width
  double get w => Responsive.width(toDouble());

  /// Responsive height
  double get h => Responsive.height(toDouble());

  /// Responsive font size
  double get sp => Responsive.fontSize(toDouble());

  /// Responsive spacing
  double get r => Responsive.space(toDouble());

  /// Responsive icon size
  double get icon => Responsive.iconSize(toDouble());

  /// Responsive radius
  double get rad => Responsive.radius(toDouble());
}

/// Responsive Text Style helper
class ResponsiveTextStyle {
  static TextStyle displayLarge(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(40),
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1.2,
  );

  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(32),
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.3,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(24),
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static TextStyle heading3(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(20),
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.4,
  );

  static TextStyle heading4(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(18),
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(16),
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(14),
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(13),
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(12),
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static TextStyle labelLarge(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(14),
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle buttonText(BuildContext context) => TextStyle(
    fontSize: Responsive.fontSize(15),
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

/// Widget that initializes Responsive helper
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return builder(context, Responsive());
  }
}

