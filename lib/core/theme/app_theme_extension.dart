import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color glowColor;
  final double borderWidth;
  final Color borderColor;
  final double borderRadius;
  final TextStyle headingStyle;

  const AppThemeExtension({
    required this.glowColor,
    required this.borderWidth,
    required this.borderColor,
    required this.borderRadius,
    required this.headingStyle,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? glowColor,
    double? borderWidth,
    Color? borderColor,
    double? borderRadius,
    TextStyle? headingStyle,
  }) {
    return AppThemeExtension(
      glowColor: glowColor ?? this.glowColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      headingStyle: headingStyle ?? this.headingStyle,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
      covariant ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      glowColor: Color.lerp(glowColor, other.glowColor, t) ?? glowColor,
      borderWidth: ui.lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      borderRadius: ui.lerpDouble(borderRadius, other.borderRadius, t) ?? borderRadius,
      headingStyle: TextStyle.lerp(headingStyle, other.headingStyle, t) ?? headingStyle,
    );
  }
}
