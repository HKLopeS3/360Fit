import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/mock_data.dart' as mock;
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final fmtMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final agora = DateTime.now();
    final saudacao = agora.hour < 12
        ? 'Bom dia'
        : agora.hour < 18
            ? 'Boa tarde'
            : 'Boa noite';

    return TelaAcademia(
      titulo: 'Dashboard',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Saudação
          Text(
            '$saudacao, ${mock.usuarioDemo.nome.split(' ').first}!',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: kTxt1),
          ),
          const SizedBox(height: 2),
          Text(
            mock.usuarioDemo.academiaNome,
            style: const TextStyle(fontSize: 14, color: kTxt2),
          ),
          const SizedBox(height: 20),

          // Métricas principais
          _GridMetricas(desktop: desktop, fmtMoeda: fmtMoeda),
          const SizedBox(height: 24),

          if (desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _CheckInsHoje()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _InadimplentesCard()),
              ],
            )
          else ...[
            _CheckInsHoje(),
            const SizedBox(height: 16),
            _InadimplentesCard(),
          ],

          const SizedBox(height: 24),
          _TurmasHoje(),
        ],
      ),
    );
  }
}

// ── Grid de métricas ──────────────────────────────────────────────────────────
class _GridMetricas extends StatelessWidget {
  const _GridMetricas({required this.desktop, required this.fmtMoeda});
  final bool desktop;
  final NumberFormat fmtMoeda;

  @override
  Widget build(BuildContext context) {
    final items = [
      CardMetrica(
        label: 'Alunos ativos',
        valor: '${mock.totalAtivos}',
        icone: Icons.people_outline,
        cor: kPrimaria,
        sub: '${mock.alunos.length} total',
      ),
      CardMetrica(
        label: 'Check-ins hoje',
        valor: '${mock.checkInsHojeCount}',
        icone: Icons.login_outlined,
        cor: kSucesso,
        sub: 'acessos registrados',
      ),
      CardMetrica(
        label: 'Receita do mês',
        valor: fmtMoeda.format(mock.receitaMes),
        icone: Icons.attach_money,
        cor: const Color(0xFF6C3FC5),
        sub: '${fmtMoeda.format(mock.receitaPendente)} pendente',
      ),
      CardMetrica(
        label: 'Inadimplentes',
        valor: '${mock.totalInadimplentes}',
        icone: Icons.warning_amber_outlined,
        cor: kErro,
        sub: 'mensalidades vencidas',
      ),
    ];

    if (desktop) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: items[i]),
          ]
        ],
      );
    }
    return Column(
      children: [
        Row(children: [
          Expanded(child: items[0]),
          const SizedBox(width: 12),
          Expanded(child: items[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: items[2]),
          const SizedBox(width: 12),
          Expanded(child: items[3]),
        ]),
      ],
    );
  }
}

// ── Check-ins de hoje ─────────────────────────────────────────────────────────
class _CheckInsHoje extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
        boxShadow: kShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: const [
                Text('Check-ins de hoje',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTxt1)),
                Spacer(),
                Icon(Icons.login_outlined, size: 18, color: kTxt2),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final c in mock.checkInsHoje)
            ListTile(
              dense: true,
              leading: AvatarIniciais(c.alunoIniciais, radius: 18),
              title: Text(c.alunoNome,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              trailing: Text(fmt.format(c.quando),
                  style: const TextStyle(fontSize: 12, color: kTxt2)),
            ),
          if (mock.checkInsHoje.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum check-in hoje.',
                  style: TextStyle(color: kTxt2, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

// ── Inadimplentes ─────────────────────────────────────────────────────────────
class _InadimplentesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inadimplentes = mock.alunos
        .where((a) => a.situacao == SituacaoFinanceira.inadimplente)
        .toList();
    final vencendo = mock.alunos
        .where((a) => a.situacao == SituacaoFinanceira.vencendo)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
        boxShadow: kShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: const [
                Text('Atenção financeira',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTxt1)),
                Spacer(),
                Icon(Icons.warning_amber_outlined,
                    size: 18, color: kErro),
              ],
            ),
          ),
          const Divider(height: 1),
          if (inadimplentes.isEmpty && vencendo.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tudo em dia!',
                  style: TextStyle(color: kSucesso, fontSize: 13)),
            ),
          for (final a in inadimplentes)
            _LinhaAlerta(a, SituacaoFinanceira.inadimplente),
          for (final a in vencendo)
            _LinhaAlerta(a, SituacaoFinanceira.vencendo),
        ],
      ),
    );
  }
}

class _LinhaAlerta extends StatelessWidget {
  const _LinhaAlerta(this.aluno, this.situacao);
  final AlunoAcademia aluno;
  final SituacaoFinanceira situacao;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: AvatarIniciais(aluno.iniciais, radius: 18, cor: situacao.cor),
      title: Text(aluno.nome,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: BadgeSituacao(label: situacao.label, cor: situacao.cor),
    );
  }
}

// ── Turmas de hoje ────────────────────────────────────────────────────────────
class _TurmasHoje extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final diaSemana = DateTime.now().weekday;
    final hoje = mock.turmas.where((t) => t.diasSemana.contains(diaSemana)).toList()
      ..sort((a, b) =>
          (a.horario.hour * 60 + a.horario.minute)
              .compareTo(b.horario.hour * 60 + b.horario.minute));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSecao('Turmas de hoje'),
        Container(
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder),
            boxShadow: kShadow,
          ),
          child: Column(
            children: [
              for (int i = 0; i < hoje.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _TurmaLinha(hoje[i]),
              ],
              if (hoje.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma turma hoje.',
                      style: TextStyle(color: kTxt2)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TurmaLinha extends StatelessWidget {
  const _TurmaLinha(this.turma);
  final Turma turma;

  @override
  Widget build(BuildContext context) {
    final pct = turma.inscritos / turma.vagas;
    final cor = turma.lotada ? kErro : pct > 0.8 ? kAlerta : kSucesso;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPrimaria.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(turma.horaStr,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kPrimaria)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turma.nome,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: kTxt1)),
                Text('${turma.professor} · ${turma.sala}',
                    style: const TextStyle(fontSize: 12, color: kTxt2)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${turma.inscritos}/${turma.vagas}',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: cor)),
              Text(turma.lotada ? 'Lotada' : 'vagas',
                  style: TextStyle(fontSize: 11, color: cor)),
            ],
          ),
        ],
      ),
    );
  }
}
