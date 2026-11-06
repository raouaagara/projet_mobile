import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'brand.dart';

/// Workify's look: white rounded surfaces, green actions (see the onboarding design).
///
/// Buttons use a deeper green than [Brand.green] so white text on them stays readable
/// (4.5:1); the bright brand green is for the logo, illustrations and highlights.
abstract final class AppTheme {
  static ThemeData light() => _build(_lightColors);
  static ThemeData dark() => _build(_darkColors);

  static const _ink = Color(0xFF1D2A1B);
  static const _muted = Color(0xFF6E7A6B);

  static final _lightColors = ColorScheme.fromSeed(seedColor: Brand.green).copyWith(
    primary: const Color(0xFF34862A),
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE3F3DA),
    onPrimaryContainer: const Color(0xFF1D4A12),
    secondaryContainer: const Color(0xFFE3F3DA),
    onSecondaryContainer: const Color(0xFF1D4A12),
    surface: Colors.white,
    onSurface: _ink,
    onSurfaceVariant: _muted,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF7F9F5),
    surfaceContainer: const Color(0xFFF2F5EF),
    surfaceContainerHigh: const Color(0xFFECF0E8),
    surfaceContainerHighest: const Color(0xFFE6EBE2),
    outline: const Color(0xFF7A8577),
    outlineVariant: const Color(0xFFE3E9DF),
  );

  static final _darkColors = ColorScheme.fromSeed(seedColor: Brand.green, brightness: Brightness.dark).copyWith(
    primary: const Color(0xFF8FD46B),
    onPrimary: const Color(0xFF113A06),
    primaryContainer: const Color(0xFF28521C),
    onPrimaryContainer: const Color(0xFFD4F2BC),
  );

  static ThemeData _build(ColorScheme colors) {
    final light = colors.brightness == Brightness.light;
    final background = light ? const Color(0xFFF7F9F5) : colors.surface;
    const rounded = StadiumBorder();
    final base = ThemeData(colorScheme: colors, useMaterial3: true);
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text,
      dividerTheme: DividerThemeData(color: colors.outlineVariant, space: 1),
      // Sizes are set here: the text theme only gets them from Typography later.
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w700, color: colors.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: colors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? colors.primary : colors.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => text.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? colors.primary : colors.onSurfaceVariant,
            )),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: light ? colors.surface : colors.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: rounded,
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: rounded,
          side: BorderSide(color: light ? const Color(0xFFC9D3C5) : colors.outline),
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge?.copyWith(fontSize: 14)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: colors.outlineVariant),
        selectedColor: colors.primaryContainer,
        backgroundColor: colors.surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: light ? _ink : colors.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(iconColor: colors.onSurfaceVariant),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorColor: colors.primary,
        dividerColor: colors.outlineVariant,
        labelStyle: text.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Light or dark, only from the switch in the menu (never from the phone's setting), kept between launches.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light; // Workify is designed light first.
  }

  // Read while the splash screen plays, so the switch is invisible.
  Future<void> _restore() async {
    try {
      if (await _storage.read(key: _key) == ThemeMode.dark.name && ref.mounted) state = ThemeMode.dark;
    } on Object {
      // Unreadable: stay light.
    }
  }

  void toggle(Brightness current) {
    state = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    _storage.write(key: _key, value: state.name).ignore();
  }
}
