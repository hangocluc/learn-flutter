import 'package:learn_flutter/common/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const String NotoSansJP = "NotoSansJP";
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  // static final TextTheme _textTheme = TextTheme(
  //   titleSmall: TextStyle(fontSize: 12.0.sp, fontFamily: NotoSansJP),
  //   titleMedium: TextStyle(fontSize: 13.0.sp, fontFamily: NotoSansJP),
  //   titleLarge: TextStyle(fontSize: 14.0.sp, fontFamily: NotoSansJP),
  //   labelSmall: TextStyle(fontSize: 14.0.sp, fontFamily: NotoSansJP),
  //   labelMedium: TextStyle(fontSize: 15.0.sp, fontFamily: NotoSansJP),
  //   labelLarge: TextStyle(fontSize: 16.0.sp, fontFamily: NotoSansJP),
  // );

  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue.blue500,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.blue.blue500,
    secondary: AppColors.tealGreen.tealGreen500,
    tertiary: AppColors.pink.pink50,
    error: AppColors.red.red500,
    surface: AppColors.white.white,
    surfaceContainerHighest: AppColors.white.white25,
  );

  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue.blue500,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.blue.blue400,
    secondary: AppColors.tealGreen.tealGreen400,
    tertiary: AppColors.pink.pink50,
    error: AppColors.red.red400,
    surface: AppColors.other.Color0E0E0F,
    surfaceContainerHighest: AppColors.theBlack.theBlack900,
  );

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    scaffoldBackgroundColor: AppColors.white.white25,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.theBlack.theBlack900,
      titleTextStyle: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.theBlack.theBlack900,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: AppColors.white.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.theBlack.theBlack100,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.theBlack.theBlack900,
      contentTextStyle: TextStyle(
        color: AppColors.white.white,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.theBlack.theBlack200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.theBlack.theBlack200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightScheme.primary,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: TextStyle(
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: AppColors.white.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: _lightScheme.primary.withOpacity(0.14),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.sp,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? _lightScheme.primary : AppColors.theBlack.theBlack500,
          );
        },
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.white.white,
      selectedItemColor: _lightScheme.primary,
      unselectedItemColor: AppColors.theBlack.theBlack500,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      dragHandleSize: Size(50.w, 5.w),
      dragHandleColor: AppColors.theBlack.theBlack200,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      backgroundColor: AppColors.white.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _lightScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: AppColors.other.Color0E0E0F,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.white.white,
      titleTextStyle: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.white.white,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: AppColors.theBlack.theBlack900,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.theBlack.theBlack800,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.theBlack.theBlack800,
      contentTextStyle: TextStyle(
        color: AppColors.white.white,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.theBlack.theBlack900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.theBlack.theBlack700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.theBlack.theBlack700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _darkScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkScheme.primary,
        foregroundColor: AppColors.theBlack.theBlack950,
        textStyle: TextStyle(
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: AppColors.theBlack.theBlack950,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: _darkScheme.primary.withOpacity(0.18),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.sp,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? _darkScheme.primary : AppColors.theBlack.theBlack400,
          );
        },
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.theBlack.theBlack950,
      selectedItemColor: _darkScheme.primary,
      unselectedItemColor: AppColors.theBlack.theBlack400,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      dragHandleSize: Size(50.w, 5.w),
      dragHandleColor: AppColors.theBlack.theBlack600,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      backgroundColor: AppColors.theBlack.theBlack950,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _darkScheme.primary,
      foregroundColor: AppColors.theBlack.theBlack950,
      elevation: 0,
    ),
  );
}
