import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual parametrizável.
///
/// No plano Premium (White Label) cada empresa terá sua própria instância
/// destes tokens; por enquanto usamos a marca padrão 360Fit.
@immutable
class BrandTheme extends ThemeExtension<BrandTheme> {
  const BrandTheme({
    required this.nomeMarca,
    required this.sucesso,
    required this.alerta,
    required this.gradientePrimario,
  });

  final String nomeMarca;
  final Color sucesso;
  final Color alerta;
  final List<Color> gradientePrimario;

  Color get primaria => gradientePrimario.first;

  static const fit360 = BrandTheme(
    nomeMarca: '360Fit',
    sucesso: Color(0xFF2E7D32),
    alerta: Color(0xFFE65100),
    gradientePrimario: [Color(0xFF00BFA5), Color(0xFF00897B)],
  );

  @override
  BrandTheme copyWith({
    String? nomeMarca,
    Color? sucesso,
    Color? alerta,
    List<Color>? gradientePrimario,
  }) {
    return BrandTheme(
      nomeMarca: nomeMarca ?? this.nomeMarca,
      sucesso: sucesso ?? this.sucesso,
      alerta: alerta ?? this.alerta,
      gradientePrimario: gradientePrimario ?? this.gradientePrimario,
    );
  }

  @override
  BrandTheme lerp(BrandTheme? other, double t) {
    if (other == null) return this;
    return BrandTheme(
      nomeMarca: t < 0.5 ? nomeMarca : other.nomeMarca,
      sucesso: Color.lerp(sucesso, other.sucesso, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      gradientePrimario: [
        for (var i = 0; i < gradientePrimario.length; i++)
          Color.lerp(
            gradientePrimario[i],
            other.gradientePrimario[i % other.gradientePrimario.length],
            t,
          )!,
      ],
    );
  }
}

extension BrandThemeX on BuildContext {
  BrandTheme get brand => Theme.of(this).extension<BrandTheme>()!;
}

// ── Tokens globais do design system ──────────────────────────────────────────
const kBgPage     = Color(0xFFF4F7F6);
const kBgCard     = Colors.white;
const kTextPrimary   = Color(0xFF1A1A2E);
const kTextSecondary = Color(0xFF888888);
const kBorderColor   = Color(0xFFEEEEEE);
const kRadius     = Radius.circular(16);
const kRadiusSm   = Radius.circular(12);
const kShadowCard = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x06000000), blurRadius: 2, offset: Offset(0, 1)),
];

ThemeData buildTheme({BrandTheme brand = BrandTheme.fit360}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brand.gradientePrimario.first,
    brightness: Brightness.light,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final tt = GoogleFonts.interTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: tt,
    extensions: [brand],
    scaffoldBackgroundColor: kBgPage,

    // ── Cards ──────────────────────────────────────────────────────────────
    cardTheme: const CardThemeData(
      color: kBgCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(kRadius),
      ),
    ),

    // ── AppBar ─────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: kBgCard,
      foregroundColor: kTextPrimary,
      elevation: 0,
      shadowColor: const Color(0x14000000),
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: tt.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
      ),
    ),

    // ── NavigationBar ──────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kBgCard,
      indicatorColor: scheme.primaryContainer,
      elevation: 4,
      shadowColor: const Color(0x14000000),
      labelTextStyle: WidgetStateProperty.all(
        tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    // ── InputDecoration ────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kRadiusSm),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kRadiusSm),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kRadiusSm),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kRadiusSm),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(kRadiusSm),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),

    // ── Buttons ────────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(kRadiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(kRadiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // ── Dialogs ────────────────────────────────────────────────────────────
    dialogTheme: const DialogThemeData(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
      ),
    ),

    // ── BottomSheet ────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // ── Divider ────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: kBorderColor,
      thickness: 1,
      space: 1,
    ),

    // ── Chip ───────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: const BorderSide(color: kBorderColor),
      backgroundColor: kBgCard,
      selectedColor: scheme.primaryContainer,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}
