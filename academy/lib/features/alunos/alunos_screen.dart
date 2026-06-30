import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/mock_data.dart' as mock;
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  String _busca = '';
  SituacaoFinanceira? _filtroSit;
  PlanoTipo? _filtroPlano;

  List<AlunoAcademia> get _filtrados {
    var lista = mock.alunos.toList();
    if (_busca.isNotEmpty) {
      final q = _busca.toLowerCase();
      lista = lista.where((a) => a.nome.toLowerCase().contains(q)).toList();
    }
    if (_filtroSit != null) {
      lista = lista.where((a) => a.situacao == _filtroSit).toList();
    }
    if (_filtroPlano != null) {
      lista = lista.where((a) => a.plano == _filtroPlano).toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return TelaAcademia(
      titulo: 'Alunos',
      fab: FloatingActionButton.extended(
        onPressed: () => _mostrarFormAluno(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Novo aluno'),
      ),
      body: Column(
        children: [
          // Barra de filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar aluno...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _busca = v),
                  ),
                ),
                const SizedBox(width: 8),
                _FiltroChip<SituacaoFinanceira>(
                  rotulo: 'Situação',
                  valor: _filtroSit,
                  opcoes: SituacaoFinanceira.values,
                  labelFn: (s) => s.label,
                  onChange: (v) => setState(() => _filtroSit = v),
                ),
                const SizedBox(width: 8),
                _FiltroChip<PlanoTipo>(
                  rotulo: 'Plano',
                  valor: _filtroPlano,
                  opcoes: PlanoTipo.values,
                  labelFn: (p) => p.label,
                  onChange: (v) => setState(() => _filtroPlano = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista
          Expanded(
            child: _filtrados.isEmpty
                ? const Center(
                    child: Text('Nenhum aluno encontrado.',
                        style: TextStyle(color: kTxt2)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _CardAluno(_filtrados[i], onTap: () => _abrirDetalhe(context, _filtrados[i])),
                  ),
          ),
        ],
      ),
    );
  }

  void _abrirDetalhe(BuildContext context, AlunoAcademia aluno) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DetalheAluno(aluno),
    );
  }

  void _mostrarFormAluno(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro de aluno em breve!')),
    );
  }
}

// ── Card do aluno na lista ────────────────────────────────────────────────────
class _CardAluno extends StatelessWidget {
  const _CardAluno(this.aluno, {required this.onTap});
  final AlunoAcademia aluno;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sit = aluno.situacao;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kBorder),
          boxShadow: kShadow,
        ),
        child: Row(
          children: [
            AvatarIniciais(aluno.iniciais, radius: 22, cor: sit.cor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aluno.nome,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kTxt1)),
                  const SizedBox(height: 2),
                  Text('${aluno.plano.label} · ${aluno.telefone}',
                      style: const TextStyle(fontSize: 12, color: kTxt2)),
                ],
              ),
            ),
            BadgeSituacao(label: sit.label, cor: sit.cor),
          ],
        ),
      ),
    );
  }
}

// ── Detalhe do aluno (bottom sheet) ──────────────────────────────────────────
class _DetalheAluno extends StatelessWidget {
  const _DetalheAluno(this.aluno);
  final AlunoAcademia aluno;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final sit = aluno.situacao;
    final mens = mock.mensalidades.where((m) => m.alunoId == aluno.id).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              AvatarIniciais(aluno.iniciais, radius: 30, cor: sit.cor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(aluno.nome,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kTxt1)),
                    BadgeSituacao(label: sit.label, cor: sit.cor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(Icons.email_outlined, aluno.email),
          _InfoRow(Icons.phone_outlined, aluno.telefone),
          _InfoRow(Icons.card_membership_outlined,
              'Plano ${aluno.plano.label}'),
          _InfoRow(Icons.calendar_today_outlined,
              'Vence em ${fmt.format(aluno.vencimento)}'),
          if (aluno.ultimoCheckin != null)
            _InfoRow(Icons.login_outlined,
                'Último acesso: ${fmt.format(aluno.ultimoCheckin!)}'),
          const TituloSecao('Histórico de mensalidades'),
          for (final m in mens) _LinhaMensalidade(m),
          if (mens.isEmpty)
            const Text('Nenhuma mensalidade registrada.',
                style: TextStyle(color: kTxt2, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Fechar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Mensalidade gerada!')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Gerar mensalidade'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.texto);
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kTxt2),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontSize: 13, color: kTxt1)),
        ],
      ),
    );
  }
}

class _LinhaMensalidade extends StatelessWidget {
  const _LinhaMensalidade(this.m);
  final MensalidadeAcademia m;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    final cor = m.paga ? kSucesso : kErro;
    final fmtM = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(m.paga ? Icons.check_circle_outline : Icons.schedule,
              size: 16, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.paga
                  ? 'Pago em ${fmt.format(m.pagoEm!)}'
                  : 'Vence ${fmt.format(m.vencimento)}',
              style: TextStyle(fontSize: 12, color: cor),
            ),
          ),
          Text(fmtM.format(m.valor),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: cor)),
        ],
      ),
    );
  }
}

// ── Chip de filtro genérico ───────────────────────────────────────────────────
class _FiltroChip<T> extends StatelessWidget {
  const _FiltroChip({
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.labelFn,
    required this.onChange,
  });
  final String rotulo;
  final T? valor;
  final List<T> opcoes;
  final String Function(T) labelFn;
  final void Function(T?) onChange;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T?>(
      initialValue: valor,
      onSelected: onChange,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(
          value: null,
          child: Text('Todos ($rotulo)'),
        ),
        for (final o in opcoes)
          PopupMenuItem<T?>(value: o, child: Text(labelFn(o))),
      ],
      child: Chip(
        label: Text(
          valor != null ? labelFn(valor as T) : rotulo,
          style: TextStyle(
              fontSize: 12,
              color: valor != null ? kPrimaria : kTxt2),
        ),
        avatar: Icon(
          Icons.filter_list,
          size: 14,
          color: valor != null ? kPrimaria : kTxt2,
        ),
        backgroundColor: valor != null
            ? kPrimaria.withValues(alpha: 0.08)
            : null,
      ),
    );
  }
}
