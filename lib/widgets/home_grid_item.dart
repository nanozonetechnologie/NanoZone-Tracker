import 'package:flutter/material.dart';
import 'package:exptrackerforhybridos/theme/app_theme.dart';
import 'package:exptrackerforhybridos/helpers/responsive_helper.dart';

class HomeGridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;
  final List<Color>? gradientColors;

  const HomeGridItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.accentColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? AppTheme.primaryColor;
    final gradient = gradientColors ?? [
      effectiveAccent.withAlpha(20),
      effectiveAccent.withAlpha(8),
    ];
    
    const radius = AppTheme.radiusL;

    return Container(
      margin: Responsive.padding(all: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(10)
              : effectiveAccent.withAlpha(20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveAccent.withAlpha(isDark ? 15 : 20),
            blurRadius: 20.r,
            offset: Offset(0, 8.r),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: effectiveAccent.withAlpha(30),
          highlightColor: effectiveAccent.withAlpha(15),
          child: Container(
            padding: Responsive.padding(all: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Icon Container with gradient background
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        effectiveAccent,
                        effectiveAccent.withAlpha(180),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18.rad),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveAccent.withAlpha(80),
                        blurRadius: 16.r,
                        offset: Offset(0, 6.r),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 30.icon,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12.r),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: ResponsiveTextStyle.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
