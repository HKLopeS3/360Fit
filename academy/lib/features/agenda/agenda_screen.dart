import 'package:flutter/material.dart';

import '../../core/mock_data.dart' as mock;
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

// ── Constantes ────────────────────────────────────────────────────────────────
const _horaInicio = 5;  // 05:00
const _horaFim    = 22; // 22:00
const _alturaHora = 64.0;
const _larguraHora = 56.0;
const _larguraColuna = 130.0;

const _diasNomes = {
  DateTime.monday:    'Seg',
  DateTime.tuesday:   'Ter',
  DateTime.wednesday: 'Qua',
  DateTime.thursday:  'Qui',
  DateTime.friday:    'Sex',
  DateTime.saturday:  'Sáb',
  DateTime.sunday:    'Dom',
};

// ── Visualização ──────────────────────────────────────────────────────────────
enum _Visualizacao { semana, dia }

// ── Tela principal ────────────────────────────────────────────────────────────
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  _Visualizacao _vis = _Visualizacao.semana;
  DateTime _semanaBase = _inicioSemana(DateTime.now());
  bool _filtroAberto = false;

  // Filtros
  String? _filtroInstrutor;
  String? _filtroSala;
  final _scrollH = ScrollController();
  final _scrollV = ScrollController();

  static DateTime _inicioSemana(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  List<DateTime> get _diasSemana =>
      List.generate(7, (i) => _semanaBase.add(Duration(days: i)));

  List<Turma> _turmasDoDia(DateTime dia) => mock.turmas
      .where((t) => t.diasSemana.contains(dia.weekday))
      .where((t) => _filtroInstrutor == null || t.professor == _filtroInstrutor)
      .where((t) => _filtroSala == null || t.sala == _filtroSala)
      .toList();

  String get _mesAno {
    const meses = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[_semanaBase.month]}, ${_semanaBase.year}';
  }

  @override
  Widget build(BuildContext context) {
    return TelaAcademia(
      titulo: 'Agenda',
      actions: [
        // Seletor de visualização
        _SeletorVis(
          vis: _vis,
          onChange: (v) => setState(() => _vis = v),
        ),
        const SizedBox(width: 10),
        // Filtros
        OutlinedButton.icon(
          onPressed: () => setState(() => _filtroAberto = !_filtroAberto),
          icon: Icon(
            Icons.filter_list,
            size: 16,
            color: (_filtroInstrutor != null || _filtroSala != null)
                ? kPrimaria
                : kTxt2,
          ),
          label: Text(
            'Filtros',
            style: TextStyle(
              color: (_filtroInstrutor != null || _filtroSala != null)
                  ? kPrimaria
                  : kTxt2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () => _abrirNovoHorario(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Nova turma'),
        ),
        const SizedBox(width: 16),
      ],
      fab: null,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Barra de navegação ──────────────────────────────────
              _BarraNavegacao(
                mesAno: _mesAno,
                onAnterior: () => setState(() =>
                    _semanaBase = _semanaBase.subtract(const Duration(days: 7))),
                onProximo: () => setState(() =>
                    _semanaBase = _semanaBase.add(const Duration(days: 7))),
                onHoje: () => setState(
                    () => _semanaBase = _inicioSemana(DateTime.now())),
              ),
              const Divider(height: 1),
              // ── Calendário ──────────────────────────────────────────
              Expanded(
                child: _vis == _Visualizacao.semana
                    ? _CalendarioSemana(
                        dias: _diasSemana,
                        turmasDoDia: _turmasDoDia,
                        scrollH: _scrollH,
                        scrollV: _scrollV,
                      )
                    : _CalendarioDia(
                        dia: _semanaBase,
                        turmas: _turmasDoDia(_semanaBase),
                        scrollV: _scrollV,
                      ),
              ),
            ],
          ),
          // ── Painel de filtros (drawer lateral) ─────────────────────
          if (_filtroAberto)
            _PainelFiltros(
              filtroInstrutor: _filtroInstrutor,
              filtroSala: _filtroSala,
              onAplicar: (inst, sala) => setState(() {
                _filtroInstrutor = inst;
                _filtroSala = sala;
                _filtroAberto = false;
              }),
              onFechar: () => setState(() => _filtroAberto = false),
            ),
        ],
      ),
    );
  }

  void _abrirNovoHorario(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _DialogNovoHorario(),
    );
  }
}

// ── Barra de navegação ────────────────────────────────────────────────────────
class _BarraNavegacao extends StatelessWidget {
  const _BarraNavegacao({
    required this.mesAno,
    required this.onAnterior,
    required this.onProximo,
    required this.onHoje,
  });
  final String mesAno;
  final VoidCallback onAnterior;
  final VoidCallback onProximo;
  final VoidCallback onHoje;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: onAnterior,
            tooltip: 'Semana anterior',
          ),
          TextButton(
            onPressed: onHoje,
            child: const Text('HOJE',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kPrimaria)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: onProximo,
            tooltip: 'Próxima semana',
          ),
          const SizedBox(width: 8),
          Text(
            mesAno,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kTxt1),
          ),
        ],
      ),
    );
  }
}

// ── Seletor visualização ──────────────────────────────────────────────────────
class _SeletorVis extends StatelessWidget {
  const _SeletorVis({required this.vis, required this.onChange});
  final _Visualizacao vis;
  final void Function(_Visualizacao) onChange;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Visualizacao>(
      initialValue: vis,
      onSelected: onChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              vis == _Visualizacao.semana ? 'Semana' : 'Dia',
              style: const TextStyle(fontSize: 13, color: kTxt1),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: kTxt2),
          ],
        ),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: _Visualizacao.semana, child: Text('Semana')),
        PopupMenuItem(value: _Visualizacao.dia, child: Text('Dia')),
      ],
    );
  }
}

// ── Calendário semanal ────────────────────────────────────────────────────────
class _CalendarioSemana extends StatelessWidget {
  const _CalendarioSemana({
    required this.dias,
    required this.turmasDoDia,
    required this.scrollH,
    required this.scrollV,
  });
  final List<DateTime> dias;
  final List<Turma> Function(DateTime) turmasDoDia;
  final ScrollController scrollH;
  final ScrollController scrollV;

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();

    return Column(
      children: [
        // Cabeçalho com dias
        Container(
          color: Colors.white,
          child: Row(
            children: [
              SizedBox(width: _larguraHora), // espaço horas
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollH,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      for (final dia in dias)
                        _CabecalhoDiaReal(
                          dia: dia,
                          hoje: dia.day == hoje.day &&
                              dia.month == hoje.month &&
                              dia.year == hoje.year,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Grade com horas
        Expanded(
          child: Scrollbar(
            controller: scrollV,
            child: SingleChildScrollView(
              controller: scrollV,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coluna de horas
                  SizedBox(
                    width: _larguraHora,
                    child: Column(
                      children: [
                        for (int h = _horaInicio; h <= _horaFim; h++)
                          SizedBox(
                            height: _alturaHora,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8, top: 4),
                                child: Text(
                                  '${h.toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(
                                      fontSize: 10, color: kTxt2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Colunas de cada dia
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollH,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final dia in dias)
                            _ColunaDia(
                              dia: dia,
                              turmas: turmasDoDia(dia),
                              hoje: dia.day == hoje.day &&
                                  dia.month == hoje.month &&
                                  dia.year == hoje.year,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CabecalhoDiaReal extends StatelessWidget {
  const _CabecalhoDiaReal({required this.dia, required this.hoje});
  final DateTime dia;
  final bool hoje;

  @override
  Widget build(BuildContext context) {
    final nome = _diasNomes[dia.weekday]!;
    return Container(
      width: _larguraColuna,
      color: hoje ? kPrimaria : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          '${nome.toUpperCase()}. ${dia.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: hoje ? Colors.white : kTxt2,
          ),
        ),
      ),
    );
  }
}

class _ColunaDia extends StatelessWidget {
  const _ColunaDia({
    required this.dia,
    required this.turmas,
    required this.hoje,
  });
  final DateTime dia;
  final List<Turma> turmas;
  final bool hoje;

  @override
  Widget build(BuildContext context) {
    final totalHoras = _horaFim - _horaInicio + 1;
    return Container(
      width: _larguraColuna,
      height: totalHoras * _alturaHora,
      decoration: BoxDecoration(
        color: hoje
            ? kPrimaria.withValues(alpha: 0.03)
            : Colors.transparent,
        border: Border(
          right: BorderSide(color: kBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Stack(
        children: [
          // Linhas horizontais de hora
          for (int h = 0; h <= totalHoras; h++)
            Positioned(
              top: h * _alturaHora,
              left: 0,
              right: 0,
              child: Divider(
                height: 1,
                color: kBorder.withValues(alpha: 0.4),
              ),
            ),
          // Blocos de turma
          for (final t in turmas) _BlocoTurma(turma: t),
        ],
      ),
    );
  }
}

class _BlocoTurma extends StatelessWidget {
  const _BlocoTurma({required this.turma});
  final Turma turma;

  @override
  Widget build(BuildContext context) {
    final top =
        (turma.horario.hour - _horaInicio + turma.horario.minute / 60) *
            _alturaHora;
    // Duração padrão: 1h
    const altura = _alturaHora * 1.0 - 4;

    return Positioned(
      top: top + 2,
      left: 2,
      right: 2,
      height: altura,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: kPrimaria.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kPrimaria.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                turma.nome,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPrimaria),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                turma.horaStr,
                style: const TextStyle(fontSize: 10, color: kTxt2),
              ),
              Text(
                '${turma.inscritos}/${turma.vagas}',
                style: TextStyle(
                    fontSize: 10,
                    color: turma.lotada ? kErro : kSucesso),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Calendário de dia único ───────────────────────────────────────────────────
class _CalendarioDia extends StatelessWidget {
  const _CalendarioDia(
      {required this.dia, required this.turmas, required this.scrollV});
  final DateTime dia;
  final List<Turma> turmas;
  final ScrollController scrollV;

  @override
  Widget build(BuildContext context) {
    final nome = _diasNomes[dia.weekday]!;
    final totalHoras = _horaFim - _horaInicio + 1;

    return Column(
      children: [
        Container(
          color: kPrimaria,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              '${nome.toUpperCase()}. ${dia.day}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Scrollbar(
            controller: scrollV,
            child: SingleChildScrollView(
              controller: scrollV,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _larguraHora,
                    child: Column(
                      children: [
                        for (int h = _horaInicio; h <= _horaFim; h++)
                          SizedBox(
                            height: _alturaHora,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8, top: 4),
                                child: Text(
                                  '${h.toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(
                                      fontSize: 10, color: kTxt2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: totalHoras * _alturaHora,
                      child: Stack(
                        children: [
                          for (int h = 0; h <= totalHoras; h++)
                            Positioned(
                              top: h * _alturaHora,
                              left: 0,
                              right: 0,
                              child: Divider(
                                  height: 1,
                                  color: kBorder.withValues(alpha: 0.4)),
                            ),
                          for (final t in turmas)
                            _BlocoTurma(turma: t),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Painel de filtros ─────────────────────────────────────────────────────────
class _PainelFiltros extends StatefulWidget {
  const _PainelFiltros({
    required this.filtroInstrutor,
    required this.filtroSala,
    required this.onAplicar,
    required this.onFechar,
  });
  final String? filtroInstrutor;
  final String? filtroSala;
  final void Function(String? instrutor, String? sala) onAplicar;
  final VoidCallback onFechar;

  @override
  State<_PainelFiltros> createState() => _PainelFiltrosState();
}

class _PainelFiltrosState extends State<_PainelFiltros> {
  String? _instrutor;
  String? _sala;

  @override
  void initState() {
    super.initState();
    _instrutor = widget.filtroInstrutor;
    _sala = widget.filtroSala;
  }

  @override
  Widget build(BuildContext context) {
    final instrutores =
        mock.turmas.map((t) => t.professor).toSet().toList()..sort();
    final salas = mock.turmas.map((t) => t.sala).toSet().toList()..sort();

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 320,
      child: Material(
        elevation: 8,
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: kBorder))),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20, color: kTxt2),
                    const SizedBox(width: 8),
                    const Text('Filtros',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTxt1)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: widget.onFechar,
                    ),
                  ],
                ),
              ),
              // Conteúdo
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Instrutor
                    const Text('Instrutor',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTxt1)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final inst in instrutores)
                          GestureDetector(
                            onTap: () => setState(() =>
                                _instrutor =
                                    _instrutor == inst ? null : inst),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: _instrutor == inst
                                      ? kPrimaria
                                      : kBgPage,
                                  child: Text(
                                    inst
                                        .replaceAll('Prof. ', '')
                                        .split(' ')
                                        .map((p) => p[0])
                                        .take(2)
                                        .join(),
                                    style: TextStyle(
                                        color: _instrutor == inst
                                            ? Colors.white
                                            : kTxt2,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    inst.replaceAll('Prof. ', ''),
                                    style: const TextStyle(
                                        fontSize: 10, color: kTxt2),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Local/Sala
                    const Text('Local',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTxt1)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sala in salas)
                          ChoiceChip(
                            label: Text(sala),
                            selected: _sala == sala,
                            onSelected: (_) => setState(() =>
                                _sala = _sala == sala ? null : sala),
                            selectedColor:
                                kPrimaria.withValues(alpha: 0.12),
                            labelStyle: TextStyle(
                                color: _sala == sala ? kPrimaria : kTxt2,
                                fontWeight: _sala == sala
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Rodapé
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: kBorder))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _instrutor = null;
                            _sala = null;
                          });
                        },
                        icon: const Icon(Icons.filter_list_off, size: 16),
                        label: const Text('LIMPAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            widget.onAplicar(_instrutor, _sala),
                        child: const Text('APLICAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dialog novo horário ───────────────────────────────────────────────────────
enum _TipoHorario { contrato, servico, locacao }

class _DialogNovoHorario extends StatefulWidget {
  const _DialogNovoHorario();

  @override
  State<_DialogNovoHorario> createState() => _DialogNovoHorarioState();
}

class _DialogNovoHorarioState extends State<_DialogNovoHorario> {
  _TipoHorario? _tipo;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaria.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_outlined,
                        color: kPrimaria, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Novo horário de serviço',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kTxt1)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text('Selecione o tipo do horário',
                  style: TextStyle(fontSize: 13, color: kTxt2)),
            ),
            // Opções de tipo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _OpcaoTipo(
                    tipo: _TipoHorario.contrato,
                    selecionado: _tipo == _TipoHorario.contrato,
                    icon: Icons.description_outlined,
                    titulo: 'Contrato',
                    descricao:
                        'Vinculado a uma modalidade adicionada nos contratos, '
                        'ideal para uso com matrículas e controle de check-ins semanais.',
                    onTap: () =>
                        setState(() => _tipo = _TipoHorario.contrato),
                  ),
                  const SizedBox(height: 10),
                  _OpcaoTipo(
                    tipo: _TipoHorario.servico,
                    selecionado: _tipo == _TipoHorario.servico,
                    icon: Icons.handshake_outlined,
                    titulo: 'Serviço',
                    descricao:
                        'Vinculado a um serviço e não permite uso com matrículas. '
                        'Indicado para horários avulsos, como avaliação física ou outros '
                        'serviços pontuais.',
                    onTap: () =>
                        setState(() => _tipo = _TipoHorario.servico),
                  ),
                  const SizedBox(height: 10),
                  _OpcaoTipo(
                    tipo: _TipoHorario.locacao,
                    selecionado: _tipo == _TipoHorario.locacao,
                    icon: Icons.access_time_outlined,
                    titulo: 'Locação',
                    descricao:
                        'Vinculada a um local, ideal para registrar e organizar '
                        'reservas de quadras e espaços de forma prática na agenda.',
                    onTap: () =>
                        setState(() => _tipo = _TipoHorario.locacao),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Rodapé
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCELAR',
                        style: TextStyle(
                            color: kTxt2, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _tipo == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Criando horário do tipo ${_tipo!.name}...')),
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaria,
                      disabledBackgroundColor:
                          kPrimaria.withValues(alpha: 0.3),
                    ),
                    child: const Text('AVANÇAR',
                        style: TextStyle(fontWeight: FontWeight.w700)),
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

class _OpcaoTipo extends StatelessWidget {
  const _OpcaoTipo({
    required this.tipo,
    required this.selecionado,
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });
  final _TipoHorario tipo;
  final bool selecionado;
  final IconData icon;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado
              ? kPrimaria.withValues(alpha: 0.05)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? kPrimaria : kBorder,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selecionado
                    ? kPrimaria.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: selecionado ? kPrimaria : kTxt2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selecionado ? kPrimaria : kTxt1)),
                  const SizedBox(height: 4),
                  Text(descricao,
                      style: const TextStyle(
                          fontSize: 12, color: kTxt2, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionado ? kPrimaria : kBorder,
                  width: selecionado ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
