import 'package:flutter/material.dart';

// ── Cores principais ──────────────────────────────────────────────────────────
const kPrimaria   = Color(0xFF6C3FC5); // roxo-violeta
const kPrimariaL  = Color(0xFF8B5CF6);
const kAcento     = Color(0xFFF59E0B); // âmbar
const kSucesso    = Color(0xFF22C55E);
const kAlerta     = Color(0xFFF59E0B);
const kErro       = Color(0xFFEF4444);

// ── Neutros ───────────────────────────────────────────────────────────────────
const kBgPage   = Color(0xFFF4F3FF); // roxo bem claro
const kBgCard   = Colors.white;
const kBorder   = Color(0xFFE5E7EB);
const kTxt1     = Color(0xFF1A1A2E);
const kTxt2     = Color(0xFF6B7280);

const kRadius   = 14.0;
const kRadiusSm = 10.0;

const kShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
];

// ── Tema ──────────────────────────────────────────────────────────────────────
ThemeData academyTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaria,
        primary: kPrimaria,
        secondary: kAcento,
        surface: kBgCard,
      ),
      scaffoldBackgroundColor: kBgPage,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: kTxt1,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: kBgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: const BorderSide(color: kBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kPrimaria,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusSm)),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: kBorder),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFEDE9FE),
        selectedIconTheme: IconThemeData(color: kPrimaria),
        selectedLabelTextStyle: TextStyle(
            color: kPrimaria, fontWeight: FontWeight.w700, fontSize: 13),
        unselectedIconTheme: IconThemeData(color: kTxt2),
        unselectedLabelTextStyle:
            TextStyle(color: kTxt2, fontSize: 13),
      ),
    );
