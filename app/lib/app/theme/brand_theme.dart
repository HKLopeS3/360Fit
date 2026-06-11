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

ThemeData buildTheme({BrandTheme brand = BrandTheme.fit360}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brand.gradientePrimario.first,
    brightness: Brightness.light,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    extensions: [brand],
    scaffoldBackgroundColor: const Color(0xFFF6F8F8),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF6F8F8),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: scheme.primaryContainer,
    ),
  );
}
