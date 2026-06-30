import 'package:flutter/material.dart';

import '../../core/mock_data.dart' as mock;
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

const _diasNomes = {
  DateTime.monday:    'Seg',
  DateTime.tuesday:   'Ter',
  DateTime.wednesday: 'Qua',
  DateTime.thursday:  'Qui',
  DateTime.friday:    'Sex',
  DateTime.saturday:  'Sáb',
  DateTime.sunday:    'Dom',
};

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _diaSelecionado = DateTime.now().weekday;

  List<Turma> get _turmasHoje => mock.turmas
      .where((t) => t.diasSemana.contains(_diaSelecionado))
      .toList()
    ..sort((a, b) =>
        (a.horario.hour * 60 + a.horario.minute)
            .compareTo(b.horario.hour * 60 + b.horario.minute));

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    return TelaAcademia(
      titulo: 'Agenda',
      fab: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nova turma em breve!')),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nova turma'),
      ),
      body: desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna de dias (lateral no desktop)
                SizedBox(
                  width: 120,
                  child: _SeletorDias(
                    selecionado: _diaSelecionado,
                    onChange: (d) => setState(() => _diaSelecionado = d),
                    vertical: true,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _ListaTurmas(turmas: _turmasHoje),
                ),
              ],
            )
          : Column(
              children: [
                _SeletorDias(
                  selecionado: _diaSelecionado,
                  onChange: (d) => setState(() => _diaSelecionado = d),
                  vertical: false,
                ),
                const Divider(height: 1),
                Expanded(child: _ListaTurmas(turmas: _turmasHoje)),
              ],
            ),
    );
  }
}

// ── Seletor de dias ───────────────────────────────────────────────────────────
class _SeletorDias extends StatelessWidget {
  const _SeletorDias({
    required this.selecionado,
    required this.onChange,
    required this.vertical,
  });
  final int selecionado;
  final void Function(int) onChange;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final dias = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];

    if (vertical) {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 16),
            for (final d in dias)
              _DiaItem(
                dia: d,
                selecionado: selecionado == d,
                onTap: () => onChange(d),
                hoje: d == DateTime.now().weekday,
                vertical: true,
              ),
          ],
        ),
      );
    }

    return Container(
      height: 70,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          for (final d in dias)
            _DiaItem(
              dia: d,
              selecionado: selecionado == d,
              onTap: () => onChange(d),
              hoje: d == DateTime.now().weekday,
              vertical: false,
            ),
        ],
      ),
    );
  }
}

class _DiaItem extends StatelessWidget {
  const _DiaItem({
    required this.dia,
    required this.selecionado,
    required this.onTap,
    required this.hoje,
    required this.vertical,
  });
  final int dia;
  final bool selecionado;
  final VoidCallback onTap;
  final bool hoje;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final nome = _diasNomes[dia]!;
    final cor = selecionado ? kPrimaria : (hoje ? kPrimariaL : kTxt2);

    if (vertical) {
      return InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selecionado ? kPrimaria.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          child: Column(
            children: [
              Text(nome,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cor)),
              if (hoje)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                      color: cor, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: selecionado ? kPrimaria : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(
              color: selecionado ? kPrimaria : kBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(nome,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selecionado ? Colors.white : cor)),
            if (hoje)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                    color: selecionado ? Colors.white : kPrimaria,
                    shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Lista de turmas ───────────────────────────────────────────────────────────
class _ListaTurmas extends StatelessWidget {
  const _ListaTurmas({required this.turmas});
  final List<Turma> turmas;

  @override
  Widget build(BuildContext context) {
    if (turmas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 48, color: kBorder),
            SizedBox(height: 12),
            Text('Nenhuma turma neste dia.',
                style: TextStyle(color: kTxt2)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: turmas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _CardTurma(turmas[i]),
    );
  }
}

// ── Card de turma ─────────────────────────────────────────────────────────────
class _CardTurma extends StatelessWidget {
  const _CardTurma(this.turma);
  final Turma turma;

  @override
  Widget build(BuildContext context) {
    final pct = turma.inscritos / turma.vagas;
    final cor = turma.lotada ? kErro : pct > 0.8 ? kAlerta : kSucesso;
    final diasStr = turma.diasSemana.map((d) => _diasNomes[d]!).join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
        boxShadow: kShadow,
      ),
      child: Column(
        children: [
          // Cabeçalho colorido
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: kPrimaria.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kRadius)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(turma.nome,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kTxt1)),
                      const SizedBox(height: 2),
                      Text(turma.professor,
                          style:
                              const TextStyle(fontSize: 12, color: kTxt2)),
                    ],
                  ),
                ),
                // Horário
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaria,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(turma.horaStr,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          // Rodapé com detalhes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                _TurmaDetalhe(Icons.room_outlined, turma.sala),
                const SizedBox(width: 16),
                _TurmaDetalhe(Icons.calendar_today_outlined, diasStr),
                const Spacer(),
                // Ocupação
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${turma.inscritos}/${turma.vagas}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cor)),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: cor.withValues(alpha: 0.15),
                          color: cor,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    Text(
                      turma.lotada ? 'Lotada' : '${turma.vagas - turma.inscritos} vagas',
                      style: TextStyle(fontSize: 10, color: cor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurmaDetalhe extends StatelessWidget {
  const _TurmaDetalhe(this.icon, this.texto);
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: kTxt2),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11, color: kTxt2)),
      ],
    );
  }
}
