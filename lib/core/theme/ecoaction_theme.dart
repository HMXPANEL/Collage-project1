import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Design tokens for the EcoAction identity: nature greens on a deep
/// green-black canvas, warm amber/orange accents for streaks and challenges.
///
/// Widgets should pull colors from [ColorScheme] (primary/secondary/tertiary/
/// surface/outline) rather than hardcoding hex values.
abstract final class EcoActionTheme {
  /// Warm amber/orange used for streaks, challenges and warnings.
  static const Color ember = Color(0xFFFFB45C);

  static ThemeData light() => _build(_lightScheme());

  static ThemeData dark() => _build(_darkScheme());

  static ColorScheme _darkScheme() => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF8FE3B2),
        onPrimary: Color(0xFF0B2E18),
        primaryContainer: Color(0xFF1E5A34),
        onPrimaryContainer: Color(0xFFC3F5D2),
        secondary: Color(0xFF7BD48A),
        onSecondary: Color(0xFF0A3412),
        secondaryContainer: Color(0xFF1F4D27),
        onSecondaryContainer: Color(0xFFC9F4CD),
        tertiary: Color(0xFFFFB45C),
        onTertiary: Color(0xFF3B2700),
        tertiaryContainer: Color(0xFF5C3D00),
        onTertiaryContainer: Color(0xFFFFDDA6),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF0B130F),
        onSurface: Color(0xFFE7F2EA),
        surfaceContainerLowest: Color(0xFF060D09),
        surfaceContainerLow: Color(0xFF0F1B15),
        surfaceContainer: Color(0xFF13211A),
        surfaceContainerHigh: Color(0xFF18271F),
        surfaceContainerHighest: Color(0xFF1D2D24),
        onSurfaceVariant: Color(0xFF93A89B),
        outline: Color(0xFF547060),
        outlineVariant: Color(0xFF33483C),
        surfaceContainerHighest: Color(0xFF33483C),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFFE7F2EA),
        onInverseSurface: Color(0xFF1F2C24),
        inversePrimary: Color(0xFF36794E),
        surfaceTint: Color(0xFF8FE3B2),
      );

  /// Light mode is deliberately designed as a warm paper-and-leaf palette,
  /// not an inverted dark theme.
  static ColorScheme _lightScheme() => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF1E7A46),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFB8F2C9),
        onPrimaryContainer: Color(0xFF0B2E18),
        secondary: Color(0xFF388E3C),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFC9F4CD),
        onSecondaryContainer: Color(0xFF0A3412),
        tertiary: Color(0xFFC87500),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFFFDDA6),
        onTertiaryContainer: Color(0xFF3B2700),
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: Color(0xFFF6F9F4),
        onSurface: Color(0xFF1B2A21),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF0F5F1),
        surfaceContainer: Color(0xFFEAEFEB),
        surfaceContainerHigh: Color(0xFFE4E9E5),
        surfaceContainerHighest: Color(0xFFDEE4E0),
        onSurfaceVariant: Color(0xFF4C5F52),
        outline: Color(0xFF73867A),
        outlineVariant: Color(0xFFC2CFC6),
        surfaceContainerHighest: Color(0xFFDEE4E0),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFF2C3A31),
        onInverseSurface: Color(0xFFE7F2EA),
        inversePrimary: Color(0xFF9BD7AE),
        surfaceTint: Color(0xFF1E7A46),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;
    final textTheme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.35),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: scheme.outlineVariant, width: 0.7),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: cardShape,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: const StadiumBorder()),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimaryContainer;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(null),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.tertiaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color:
                selected ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color:
                selected ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
