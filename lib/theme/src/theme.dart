import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/theme/theme.dart';

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  // indicatorColor: AppColors.primary,
  primaryColor: AppColors.materialColor(AppColors.primary),
  useMaterial3: true,
  fontFamily: 'GoogleSans',
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: AppColors.primary,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 20,
      fontFamily: 'GoogleSans',
    ),
    iconTheme: IconThemeData(color: AppColors.white),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: AppColors.inputFill,
    border: OutlineInputBorder(borderSide: BorderSide.none),
  ),
  scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
  dividerColor: AppColors.grey300,
  extensions: const [
    AppThemeColors(
      bgColor: Color(0xFFF4F7FE),
      cardColor: Colors.white,
      textPrimary: Color(0xFF2E5EAA),
      textSecondary: Color(0xFFA3AED0),
      divider: Color(0xFFE2E8F0),
      sidebarBackground: Color(0xFF1E293B),
    ),
  ],
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary, // same seed
    brightness: Brightness.dark,
  ),

  primaryColor: AppColors.materialColor(AppColors.primary),
  fontFamily: 'GoogleSans',

  scaffoldBackgroundColor: const Color(0xFF0F172A), // deep dark blue-grey

  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Color(0xFF020617), // darker than scaffold
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    titleTextStyle: TextStyle(
      color: AppColors.white,
      fontSize: 20,
      fontFamily: 'GoogleSans',
    ),
    iconTheme: IconThemeData(color: AppColors.white),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1E293B), // dark input background
    border: OutlineInputBorder(borderSide: BorderSide.none),
    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
    labelStyle: TextStyle(color: Color(0xFFE5E7EB)),
  ),

  dividerColor: const Color(0xFF334155),

  cardTheme: const CardThemeData(
    color: Color(0xFF020617),
    elevation: 2,
    margin: EdgeInsets.all(8),
  ),

  iconTheme: const IconThemeData(color: Color(0xFFE5E7EB)),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
    bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
    bodySmall: TextStyle(color: Color(0xFF94A3B8)),
    titleLarge: TextStyle(color: AppColors.white),
    titleMedium: TextStyle(color: AppColors.white),
  ),

  extensions: const [
    AppThemeColors(
      bgColor: Color(0xFF212121),
      cardColor: Color(0xff303030),
      textPrimary: Colors.white,
      textSecondary: Color(0xFF94A3B8),
      divider: Color(0xFF334155),
      sidebarBackground: Color(0xff181818),
    ),
  ],
);
