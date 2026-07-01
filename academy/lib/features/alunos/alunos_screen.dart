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

enum _OrdemColuna { nome, situacao, plano, vencimento }

class _AlunosScreenState extends State<AlunosScreen> {
  String _busca = '';
  SituacaoFinanceira? _filtroSit;
  PlanoTipo? _filtroPlano;
  _OrdemColuna _ordem = _OrdemColuna.nome;
  bool _ordemAsc = true;
  int _pagina = 0;
  int _porPagina = 20;

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
    lista.sort((a, b) {
      int cmp = switch (_ordem) {
        _OrdemColuna.nome       => a.nome.compareTo(b.nome),
        _OrdemColuna.situacao   => a.situacao.index.compareTo(b.situacao.index),
        _OrdemColuna.plano      => a.plano.index.compareTo(b.plano.index),
        _OrdemColuna.vencimento => a.vencimento.compareTo(b.vencimento),
      };
      return _ordemAsc ? cmp : -cmp;
    });
    return lista;
  }

  List<AlunoAcademia> get _pagina_ {
    final todos = _filtrados;
    final ini = _pagina * _porPagina;
    if (ini >= todos.length) return [];
    return todos.sublist(ini, (ini + _porPagina).clamp(0, todos.length));
  }

  int get _totalPaginas => (_filtrados.length / _porPagina).ceil().clamp(1, 999);

  void _ordenarPor(_OrdemColuna col) {
    setState(() {
      if (_ordem == col) {
        _ordemAsc = !_ordemAsc;
      } else {
        _ordem = col;
        _ordemAsc = true;
      }
      _pagina = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    return TelaAcademia(
      titulo: 'Alunos',
      actions: [
        if (desktop) ...[
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Convite em breve!')),
            ),
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Convidar aluno'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => _mostrarFormAluno(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Novo aluno'),
          ),
          const SizedBox(width: 16),
        ],
      ],
      fab: desktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarFormAluno(context),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Novo aluno'),
            ),
      body: Column(
        children: [
          // ── Barra de busca + filtros ─────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar aluno...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() {
                      _busca = v;
                      _pagina = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                _FiltroChip<SituacaoFinanceira>(
                  rotulo: 'Situação',
                  valor: _filtroSit,
                  opcoes: SituacaoFinanceira.values,
                  labelFn: (s) => s.label,
                  onChange: (v) => setState(() {
                    _filtroSit = v;
                    _pagina = 0;
                  }),
                ),
                const SizedBox(width: 8),
                _FiltroChip<PlanoTipo>(
                  rotulo: 'Plano',
                  valor: _filtroPlano,
                  opcoes: PlanoTipo.values,
                  labelFn: (p) => p.label,
                  onChange: (v) => setState(() {
                    _filtroPlano = v;
                    _pagina = 0;
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Tabela ────────────────────────────────────────────────────
          Expanded(
            child: desktop
                ? _TabelaDesktop(
                    alunos: _pagina_,
                    ordem: _ordem,
                    ordemAsc: _ordemAsc,
                    onOrdenar: _ordenarPor,
                    onDetalhe: (a) => _abrirDetalhe(context, a),
                  )
                : _ListaMobile(
                    alunos: _pagina_,
                    onDetalhe: (a) => _abrirDetalhe(context, a),
                  ),
          ),

          // ── Paginação ─────────────────────────────────────────────────
          _Paginacao(
            pagina: _pagina,
            totalPaginas: _totalPaginas,
            totalItens: _filtrados.length,
            porPagina: _porPagina,
            onAnterior: _pagina > 0 ? () => setState(() => _pagina--) : null,
            onProximo: _pagina < _totalPaginas - 1
                ? () => setState(() => _pagina++)
                : null,
            onPorPagina: (v) => setState(() {
              _porPagina = v;
              _pagina = 0;
            }),
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

// ── Tabela desktop ────────────────────────────────────────────────────────────
class _TabelaDesktop extends StatelessWidget {
  const _TabelaDesktop({
    required this.alunos,
    required this.ordem,
    required this.ordemAsc,
    required this.onOrdenar,
    required this.onDetalhe,
  });
  final List<AlunoAcademia> alunos;
  final _OrdemColuna ordem;
  final bool ordemAsc;
  final void Function(_OrdemColuna) onOrdenar;
  final void Function(AlunoAcademia) onDetalhe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabeçalho da tabela
        Container(
          color: const Color(0xFFF9F9FB),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 44), // avatar
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: _CabecalhoCol(
                  'Nome',
                  col: _OrdemColuna.nome,
                  atual: ordem,
                  asc: ordemAsc,
                  onTap: () => onOrdenar(_OrdemColuna.nome),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _CabecalhoCol(
                  'Situação',
                  col: _OrdemColuna.situacao,
                  atual: ordem,
                  asc: ordemAsc,
                  onTap: () => onOrdenar(_OrdemColuna.situacao),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: _CabecalhoCol(
                  'Plano',
                  col: _OrdemColuna.plano,
                  atual: ordem,
                  asc: ordemAsc,
                  onTap: () => onOrdenar(_OrdemColuna.plano),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: _CabecalhoCol(
                  'Vencimento',
                  col: _OrdemColuna.vencimento,
                  atual: ordem,
                  asc: ordemAsc,
                  onTap: () => onOrdenar(_OrdemColuna.vencimento),
                ),
              ),
              const SizedBox(width: 60), // ações
            ],
          ),
        ),
        const Divider(height: 1),
        // Linhas
        Expanded(
          child: alunos.isEmpty
              ? const Center(
                  child: Text('Nenhum aluno encontrado.',
                      style: TextStyle(color: kTxt2)))
              : ListView.separated(
                  itemCount: alunos.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  itemBuilder: (_, i) => _LinhaDesktop(
                    alunos[i],
                    onDetalhe: () => onDetalhe(alunos[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CabecalhoCol extends StatelessWidget {
  const _CabecalhoCol(
    this.label, {
    required this.col,
    required this.atual,
    required this.asc,
    required this.onTap,
  });
  final String label;
  final _OrdemColuna col;
  final _OrdemColuna atual;
  final bool asc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ativo = atual == col;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ativo ? kPrimaria : kTxt2,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            ativo
                ? (asc ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 14,
            color: ativo ? kPrimaria : kTxt2,
          ),
        ],
      ),
    );
  }
}

class _LinhaDesktop extends StatelessWidget {
  const _LinhaDesktop(this.aluno, {required this.onDetalhe});
  final AlunoAcademia aluno;
  final VoidCallback onDetalhe;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final sit = aluno.situacao;

    return InkWell(
      onTap: onDetalhe,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            AvatarIniciais(aluno.iniciais, radius: 22, cor: sit.cor),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(
                aluno.nome,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTxt1),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: BadgeSituacao(label: sit.label, cor: sit.cor),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: Text(
                aluno.plano.label,
                style: const TextStyle(fontSize: 13, color: kTxt1),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: Text(
                fmt.format(aluno.vencimento),
                style: TextStyle(
                  fontSize: 13,
                  color: sit == SituacaoFinanceira.inadimplente
                      ? kErro
                      : kTxt1,
                ),
              ),
            ),
            // Ações
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Abrir perfil',
                    icon: const Icon(Icons.open_in_new,
                        size: 18, color: kTxt2),
                    onPressed: onDetalhe,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: kTxt2),
                    onSelected: (v) => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(v))),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'Editar aluno',
                          child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'Mensalidade gerada!',
                          child: Text('Gerar mensalidade')),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: aluno.ativo
                            ? 'Acesso bloqueado'
                            : 'Acesso liberado',
                        child: Text(
                          aluno.ativo ? 'Bloquear acesso' : 'Liberar acesso',
                          style: TextStyle(
                              color: aluno.ativo ? kErro : kSucesso),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lista mobile ──────────────────────────────────────────────────────────────
class _ListaMobile extends StatelessWidget {
  const _ListaMobile({required this.alunos, required this.onDetalhe});
  final List<AlunoAcademia> alunos;
  final void Function(AlunoAcademia) onDetalhe;

  @override
  Widget build(BuildContext context) {
    if (alunos.isEmpty) {
      return const Center(
          child: Text('Nenhum aluno encontrado.',
              style: TextStyle(color: kTxt2)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: alunos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = alunos[i];
        final sit = a.situacao;
        return InkWell(
          onTap: () => onDetalhe(a),
          borderRadius: BorderRadius.circular(kRadius),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                AvatarIniciais(a.iniciais, radius: 22, cor: sit.cor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.nome,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kTxt1)),
                      Text('${a.plano.label} · ${a.telefone}',
                          style: const TextStyle(
                              fontSize: 12, color: kTxt2)),
                    ],
                  ),
                ),
                BadgeSituacao(label: sit.label, cor: sit.cor),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Paginação ─────────────────────────────────────────────────────────────────
class _Paginacao extends StatelessWidget {
  const _Paginacao({
    required this.pagina,
    required this.totalPaginas,
    required this.totalItens,
    required this.porPagina,
    required this.onAnterior,
    required this.onProximo,
    required this.onPorPagina,
  });
  final int pagina;
  final int totalPaginas;
  final int totalItens;
  final int porPagina;
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;
  final void Function(int) onPorPagina;

  @override
  Widget build(BuildContext context) {
    final ini = pagina * porPagina + 1;
    final fim = ((pagina + 1) * porPagina).clamp(0, totalItens);

    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('$ini–$fim de $totalItens',
              style: const TextStyle(fontSize: 13, color: kTxt2)),
          const Spacer(),
          const Text('Exibir ',
              style: TextStyle(fontSize: 13, color: kTxt2)),
          PopupMenuButton<int>(
            initialValue: porPagina,
            onSelected: onPorPagina,
            child: Row(
              children: [
                Text('$porPagina',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTxt1)),
                const Icon(Icons.arrow_drop_down, size: 18, color: kTxt2),
              ],
            ),
            itemBuilder: (_) => [10, 20, 50]
                .map((v) => PopupMenuItem(value: v, child: Text('$v')))
                .toList(),
          ),
          const SizedBox(width: 16),
          Text('Página ${pagina + 1} de $totalPaginas',
              style: const TextStyle(fontSize: 13, color: kTxt2)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onAnterior,
            color: onAnterior != null ? kTxt1 : kBorder,
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onProximo,
            color: onProximo != null ? kTxt1 : kBorder,
            iconSize: 20,
          ),
        ],
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
    final mens =
        mock.mensalidades.where((m) => m.alunoId == aluno.id).toList();

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
              width: 40,
              height: 4,
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
                    const SizedBox(height: 4),
                    BadgeSituacao(label: sit.label, cor: sit.cor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(Icons.email_outlined, aluno.email),
          _InfoRow(Icons.phone_outlined, aluno.telefone),
          _InfoRow(Icons.card_membership_outlined, 'Plano ${aluno.plano.label}'),
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
                      const SnackBar(content: Text('Mensalidade gerada!')),
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
    final ativo = valor != null;
    return PopupMenuButton<T?>(
      initialValue: valor,
      onSelected: onChange,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(value: null, child: Text('Todos ($rotulo)')),
        for (final o in opcoes)
          PopupMenuItem<T?>(value: o, child: Text(labelFn(o))),
      ],
      child: Chip(
        label: Text(
          ativo ? labelFn(valor as T) : rotulo,
          style: TextStyle(
              fontSize: 12, color: ativo ? kPrimaria : kTxt2),
        ),
        avatar: Icon(Icons.filter_list,
            size: 14, color: ativo ? kPrimaria : kTxt2),
        backgroundColor:
            ativo ? kPrimaria.withValues(alpha: 0.08) : null,
        side: BorderSide(
            color: ativo ? kPrimaria.withValues(alpha: 0.3) : kBorder),
      ),
    );
  }
}
