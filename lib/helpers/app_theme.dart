import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Light Theme
  static ThemeData getLightTheme() {
    const lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2196F3),
      onPrimary: Colors.white,
      secondary: Color(0xFF00BCD4),
      onSecondary: Colors.white,
      tertiary: Color(0xFF9C27B0),
      onTertiary: Colors.white,
      error: Color(0xFFD32F2F),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),
      surfaceContainerHighest: Color(0xFFF5F7FA),
      onSurfaceVariant: Color(0xFF5F6368),
      outline: Color(0xFFDADCE0),
      outlineVariant: Color(0xFFE8EAED),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2D2D2D),
      onInverseSurface: Color(0xFFF5F5F5),
      inversePrimary: Color(0xFF90CAF9),
      primaryContainer: Color(0xFFE3F2FD),
      onPrimaryContainer: Color(0xFF0D47A1),
      secondaryContainer: Color(0xFFB2EBF2),
      onSecondaryContainer: Color(0xFF006064),
      tertiaryContainer: Color(0xFFF3E5F5),
      onTertiaryContainer: Color(0xFF4A148C),
      errorContainer: Color(0xFFFFCDD2),
      onErrorContainer: Color(0xFFB71C1C),
      surfaceTint: Color(0xFF2196F3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: lightColorScheme.onSurface,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: lightColorScheme.onSurface,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: lightColorScheme.onSurface,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: lightColorScheme.onSurface,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: lightColorScheme.onSurface,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: lightColorScheme.onSurface,
          height: 1.35,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: lightColorScheme.onSurface,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: lightColorScheme.onSurface,
          height: 1.5,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: lightColorScheme.onSurface,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurface,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: lightColorScheme.onSurface,
          height: 1.6,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: lightColorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: lightColorScheme.onSurface,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurface,
          height: 1.3,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: lightColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: lightColorScheme.primary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightColorScheme.onSurface,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: lightColorScheme.onSurface, size: 24),
        actionsIconTheme: IconThemeData(
          color: lightColorScheme.primary,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: lightColorScheme.primary,
        unselectedLabelColor: lightColorScheme.onSurfaceVariant,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: lightColorScheme.primary, width: 3),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: lightColorScheme.outlineVariant,
        dividerHeight: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: lightColorScheme.primaryContainer,
        elevation: 8,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: lightColorScheme.primary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: lightColorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: lightColorScheme.primary, size: 26);
          }
          return IconThemeData(
            color: lightColorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        sizeConstraints: const BoxConstraints.tightFor(width: 64, height: 64),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: lightColorScheme.primary.withOpacity(0.3),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(120, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(120, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          side: BorderSide(color: lightColorScheme.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(120, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: lightColorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: lightColorScheme.primaryContainer,
        textColor: lightColorScheme.onSurface,
        selectedColor: lightColorScheme.primary,
        iconColor: lightColorScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightColorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: lightColorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          color: lightColorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: GoogleFonts.poppins(
          color: lightColorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lightColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightColorScheme.surfaceContainerHighest,
        selectedColor: lightColorScheme.primaryContainer,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1A1A1A),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightColorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightColorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      splashFactory: InkRipple.splashFactory,
    );
  }

  // Modern Dark Theme
  static ThemeData getDarkTheme() {
    const darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF64B5F6),
      onPrimary: Color(0xFF002D49),
      secondary: Color(0xFF26C6DA),
      onSecondary: Color(0xFF003640),
      tertiary: Color(0xFFCE93D8),
      onTertiary: Color(0xFF3E1046),
      error: Color(0xFFEF5350),
      onError: Color(0xFF601410),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE6E6E6),
      surfaceContainerHighest: Color(0xFF2A2A2A),
      onSurfaceVariant: Color(0xFFB3B3B3),
      outline: Color(0xFF606060),
      outlineVariant: Color(0xFF3D3D3D),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E6E6),
      onInverseSurface: Color(0xFF1E1E1E),
      inversePrimary: Color(0xFF1976D2),
      primaryContainer: Color(0xFF003D5C),
      onPrimaryContainer: Color(0xFFD4E4FF),
      secondaryContainer: Color(0xFF004D59),
      onSecondaryContainer: Color(0xFFB2EBF2),
      tertiaryContainer: Color(0xFF5D1E68),
      onTertiaryContainer: Color(0xFFF3E5F5),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFFFDAD6),
      surfaceTint: Color(0xFF64B5F6),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.poppins(
              fontSize: 57,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: darkColorScheme.onSurface,
              height: 1.1,
            ),
            displayMedium: GoogleFonts.poppins(
              fontSize: 45,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: darkColorScheme.onSurface,
              height: 1.15,
            ),
            displaySmall: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: darkColorScheme.onSurface,
              height: 1.2,
            ),
            headlineLarge: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: darkColorScheme.onSurface,
              height: 1.25,
            ),
            headlineMedium: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: darkColorScheme.onSurface,
              height: 1.3,
            ),
            headlineSmall: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: darkColorScheme.onSurface,
              height: 1.35,
            ),
            titleLarge: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: darkColorScheme.onSurface,
              height: 1.4,
            ),
            titleMedium: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: darkColorScheme.onSurface,
              height: 1.5,
            ),
            titleSmall: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: darkColorScheme.onSurface,
              height: 1.4,
            ),
            bodyLarge: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
              color: darkColorScheme.onSurface,
              height: 1.6,
            ),
            bodyMedium: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.25,
              color: darkColorScheme.onSurface,
              height: 1.6,
            ),
            bodySmall: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
              color: darkColorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            labelLarge: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: darkColorScheme.onSurface,
              height: 1.4,
            ),
            labelMedium: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: darkColorScheme.onSurface,
              height: 1.3,
            ),
            labelSmall: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: darkColorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: darkColorScheme.primary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkColorScheme.onSurface,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: darkColorScheme.onSurface, size: 24),
        actionsIconTheme: IconThemeData(
          color: darkColorScheme.primary,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: darkColorScheme.primary,
        unselectedLabelColor: darkColorScheme.onSurfaceVariant,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: darkColorScheme.primary, width: 3),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: darkColorScheme.outlineVariant,
        dividerHeight: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkColorScheme.surface,
        indicatorColor: darkColorScheme.primaryContainer,
        elevation: 8,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkColorScheme.primary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkColorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: darkColorScheme.primary, size: 26);
          }
          return IconThemeData(
            color: darkColorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        sizeConstraints: const BoxConstraints.tightFor(width: 64, height: 64),
      ),
      cardTheme: CardThemeData(
        color: darkColorScheme.surface,
        shadowColor: Colors.black.withOpacity(0.4),
        surfaceTintColor: darkColorScheme.surfaceTint,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 2,
          shadowColor: darkColorScheme.primary.withOpacity(0.3),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(120, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(120, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColorScheme.primary,
          side: BorderSide(color: darkColorScheme.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(120, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkColorScheme.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: darkColorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: darkColorScheme.surface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: darkColorScheme.primaryContainer,
        textColor: darkColorScheme.onSurface,
        selectedColor: darkColorScheme.primary,
        iconColor: darkColorScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkColorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkColorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.error, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: darkColorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          color: darkColorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: GoogleFonts.poppins(
          color: darkColorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkColorScheme.surfaceContainerHighest,
        selectedColor: darkColorScheme.primaryContainer,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkColorScheme.onSurface,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkColorScheme.onSurface,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkColorScheme.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkColorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkColorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      splashFactory: InkRipple.splashFactory,
    );
  }
}


