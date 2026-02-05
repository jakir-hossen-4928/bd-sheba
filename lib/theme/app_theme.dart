import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Use FlexColorScheme for a premium Material 3 look
  static ThemeData light(Locale locale) {
    return FlexThemeData.light(
      scheme: FlexScheme.blueM3,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        appBarCenterTitle: true,
        bottomNavigationBarElevation: 0,
        bottomNavigationBarShowUnselectedLabels: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: locale.languageCode == 'bn'
          ? 'Kalpurush'
          : GoogleFonts.inter().fontFamily,
    );
  }

  static ThemeData dark(Locale locale) {
    return FlexThemeData.dark(
      scheme: FlexScheme.blueM3,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        appBarCenterTitle: true,
        bottomNavigationBarElevation: 0,
        bottomNavigationBarShowUnselectedLabels: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: locale.languageCode == 'bn'
          ? 'Kalpurush'
          : GoogleFonts.inter().fontFamily,
    );
  }
}
