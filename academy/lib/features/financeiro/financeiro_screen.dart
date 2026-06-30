import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/mock_data.dart' as mock;
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

enum _Aba { todas, pagas, pendentes }

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  _Aba _aba = _Aba.todas;

  List<MensalidadeAcademia> get _lista {
    return switch (_aba) {
      _Aba.pagas    => mock.mensalidades.where((m) => m.paga).toList(),
      _Aba.pendentes=> mock.mensalidades.where((m) => !m.paga).toList(),
      _Aba.todas    => mock.mensalidades,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fmtM = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    return TelaAcademia(
      titulo: 'Financeiro',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Resumo
          _ResumoFinanceiro(fmtM: fmtM, desktop: desktop),
          const SizedBox(height: 24),

          // Abas
          Row(
            children: [
              for (final aba in _Aba.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_abaLabel(aba)),
                    selected: _aba == aba,
                    onSelected: (_) => setState(() => _aba = aba),
                    selectedColor: kPrimaria.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: _aba == aba ? kPrimaria : kTxt2,
                      fontWeight: _aba == aba
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Lista de mensalidades
          for (final m in _lista) _CardMensalidade(m, fmtM: fmtM),

          if (_lista.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Nenhum registro encontrado.',
                    style: TextStyle(color: kTxt2)),
              ),
            ),
        ],
      ),
    );
  }

  String _abaLabel(_Aba a) => switch (a) {
        _Aba.todas     => 'Todas',
        _Aba.pagas     => 'Pagas',
        _Aba.pendentes => 'Pendentes',
      };
}

// ── Resumo financeiro ─────────────────────────────────────────────────────────
class _ResumoFinanceiro extends StatelessWidget {
  const _ResumoFinanceiro({required this.fmtM, required this.desktop});
  final NumberFormat fmtM;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final pago    = mock.receitaMes;
    final pend    = mock.receitaPendente;
    final total   = pago + pend;
    final pct     = total > 0 ? pago / total : 0.0;

    final cards = [
      _MiniCard('Recebido', fmtM.format(pago), kSucesso,
          Icons.check_circle_outline),
      _MiniCard('Pendente', fmtM.format(pend), kErro,
          Icons.schedule_outlined),
      _MiniCard('Total esperado', fmtM.format(total), kPrimaria,
          Icons.account_balance_wallet_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [kPrimaria, kPrimariaL],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: kShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumo do mês',
              style: TextStyle(
                  color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(fmtM.format(pago),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${(pct * 100).toStringAsFixed(0)}% da meta recebido',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          if (desktop)
            Row(children: [
              for (final c in cards) ...[
                Expanded(child: c),
                if (c != cards.last) const SizedBox(width: 10),
              ]
            ])
          else
            Column(children: [
              for (final c in cards) ...[c, const SizedBox(height: 8)],
            ]),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard(this.label, this.valor, this.cor, this.icon);
  final String label;
  final String valor;
  final Color cor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 10)),
                Text(valor,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de mensalidade ───────────────────────────────────────────────────────
class _CardMensalidade extends StatelessWidget {
  const _CardMensalidade(this.m, {required this.fmtM});
  final MensalidadeAcademia m;
  final NumberFormat fmtM;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final cor = m.paga ? kSucesso : kErro;
    final aluno = mock.alunos.firstWhere((a) => a.id == m.alunoId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
        boxShadow: kShadow,
      ),
      child: Row(
        children: [
          AvatarIniciais(aluno.iniciais, radius: 22, cor: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.alunoNome,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTxt1)),
                const SizedBox(height: 2),
                Text(
                  m.paga
                      ? 'Pago em ${fmt.format(m.pagoEm!)}'
                      : 'Vence ${fmt.format(m.vencimento)}',
                  style: TextStyle(fontSize: 12, color: cor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtM.format(m.valor),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kTxt1)),
              BadgeSituacao(
                label: m.paga ? 'Pago' : 'Pendente',
                cor: cor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
