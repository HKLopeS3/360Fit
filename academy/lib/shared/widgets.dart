import 'package:flutter/material.dart';
import '../core/theme.dart';

// ── Shell responsiva ──────────────────────────────────────────────────────────

/// Substitui Scaffold+AppBar: barra branca 64px no desktop, AppBar no mobile.
class TelaAcademia extends StatelessWidget {
  const TelaAcademia({
    super.key,
    required this.titulo,
    required this.body,
    this.actions = const [],
    this.fab,
  });
  final String titulo;
  final Widget body;
  final List<Widget> actions;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    if (desktop) {
      return Scaffold(
        backgroundColor: kBgPage,
        floatingActionButton: fab,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kTxt1)),
                const Spacer(),
                ...actions,
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: kBgPage,
      floatingActionButton: fab,
      appBar: AppBar(title: Text(titulo), actions: actions),
      body: body,
    );
  }
}

// ── Card de métrica ───────────────────────────────────────────────────────────
class CardMetrica extends StatelessWidget {
  const CardMetrica({
    super.key,
    required this.label,
    required this.valor,
    required this.icone,
    required this.cor,
    this.sub,
  });
  final String label;
  final String valor;
  final IconData icone;
  final Color cor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
        boxShadow: kShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: kTxt2)),
                const SizedBox(height: 2),
                Text(valor,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kTxt1)),
                if (sub != null)
                  Text(sub!,
                      style: const TextStyle(fontSize: 11, color: kTxt2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar com iniciais ───────────────────────────────────────────────────────
class AvatarIniciais extends StatelessWidget {
  const AvatarIniciais(this.iniciais, {super.key, this.radius = 20, this.cor});
  final String iniciais;
  final double radius;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: (cor ?? kPrimaria).withValues(alpha: 0.12),
      child: Text(
        iniciais,
        style: TextStyle(
          color: cor ?? kPrimaria,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

// ── Badge de situação ─────────────────────────────────────────────────────────
class BadgeSituacao extends StatelessWidget {
  const BadgeSituacao({super.key, required this.label, required this.cor});
  final String label;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: cor)),
    );
  }
}

// ── Título de seção ───────────────────────────────────────────────────────────
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.trailing});
  final String texto;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Text(texto,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTxt1)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Barra de logo 360Fit Academy ─────────────────────────────────────────────
class LogoAcademy extends StatelessWidget {
  const LogoAcademy({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaria, kPrimariaL],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Center(
            child: Text('360',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('360Fit',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kTxt1,
                    height: 1)),
            Text('Academy',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kPrimaria,
                    letterSpacing: 0.5,
                    height: 1.2)),
          ],
        ),
      ],
    );
  }
}
