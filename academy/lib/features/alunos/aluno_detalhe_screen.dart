import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/mock_data.dart' as mock;
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

// ── Tela de detalhe do aluno ──────────────────────────────────────────────────
class AlunoDetalheScreen extends StatefulWidget {
  const AlunoDetalheScreen({super.key, required this.alunoId});
  final String alunoId;

  @override
  State<AlunoDetalheScreen> createState() => _AlunoDetalheScreenState();
}

class _AlunoDetalheScreenState extends State<AlunoDetalheScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aluno = mock.alunos.firstWhere((a) => a.id == widget.alunoId);
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: kBgPage,
      body: Column(
        children: [
          // ── Header estilo Next Fit ─────────────────────────────────────
          _HeaderAluno(aluno: aluno, desktop: desktop),
          // ── Abas ──────────────────────────────────────────────────────
          _AbasNav(tabs: _tabs),
          const Divider(height: 1),
          // ── Conteúdo das abas ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _AbaResumo(aluno: aluno),
                _AbaCadastro(aluno: aluno),
                _AbaFinanceiro(alunoId: aluno.id),
                _AbaContratos(aluno: aluno),
                _AbaTreinos(),
                _AbaAvaliacoes(),
                _AbaServicos(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HeaderAluno extends StatelessWidget {
  const _HeaderAluno({required this.aluno, required this.desktop});
  final AlunoAcademia aluno;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final sit = aluno.situacao;
    final idadeStr = aluno.idade != null ? '${aluno.idade} anos' : '';
    final sexoStr = aluno.sexo?.label ?? '';
    final subInfo = [idadeStr, sexoStr].where((s) => s.isNotEmpty).join(', ');

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(desktop ? 32 : 16, 16, desktop ? 32 : 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botão voltar
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 22, color: kTxt2),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Voltar',
              ),
              const SizedBox(width: 4),
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kPrimaria.withValues(alpha: 0.1),
                    child: Text(
                      aluno.iniciais,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kPrimaria),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: kTxt2,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Nome + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            aluno.nome.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kTxt1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.verified,
                            size: 18, color: kSucesso),
                        const SizedBox(width: 8),
                        _BadgeStatus(
                            label: aluno.ativo ? 'Ativo' : 'Inativo',
                            ativo: aluno.ativo),
                      ],
                    ),
                    if (subInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subInfo,
                            style: const TextStyle(
                                fontSize: 13, color: kTxt2)),
                      ),
                    const SizedBox(height: 10),
                    // Botões de ação
                    if (desktop)
                      Row(
                        children: [
                          _BotaoAcao(
                            icon: Icons.edit_outlined,
                            label: 'CADASTRO',
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _BotaoAcao(
                            icon: Icons.chat_outlined,
                            label: 'WHATSAPP',
                            cor: const Color(0xFF25D366),
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _BotaoAcao(
                            icon: Icons.more_horiz,
                            label: 'MAIS AÇÕES',
                            onTap: () {},
                          ),
                          const SizedBox(width: 12),
                          // Badge situação financeira
                          BadgeSituacao(
                              label: sit.label, cor: sit.cor),
                        ],
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _BotaoAcao(
                                icon: Icons.edit_outlined,
                                label: 'CADASTRO',
                                onTap: () {}),
                            const SizedBox(width: 8),
                            _BotaoAcao(
                                icon: Icons.chat_outlined,
                                label: 'WHATSAPP',
                                cor: const Color(0xFF25D366),
                                onTap: () {}),
                            const SizedBox(width: 8),
                            _BotaoAcao(
                                icon: Icons.more_horiz,
                                label: 'MAIS AÇÕES',
                                onTap: () {}),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _BadgeStatus extends StatelessWidget {
  const _BadgeStatus({required this.label, required this.ativo});
  final String label;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (ativo ? kSucesso : kTxt2).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (ativo ? kSucesso : kTxt2).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close, size: 12, color: ativo ? kSucesso : kTxt2),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ativo ? kSucesso : kTxt2)),
        ],
      ),
    );
  }
}

class _BotaoAcao extends StatelessWidget {
  const _BotaoAcao(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.cor});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? kPrimaria;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: c),
      label: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

// ── Abas de navegação ─────────────────────────────────────────────────────────
class _AbasNav extends StatelessWidget {
  const _AbasNav({required this.tabs});
  final TabController tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: kPrimaria,
        unselectedLabelColor: kTxt2,
        labelStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        indicatorColor: kPrimaria,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'RESUMO'),
          Tab(text: 'CADASTRO'),
          Tab(text: 'FINANCEIRO'),
          Tab(text: 'CONTRATOS'),
          Tab(text: 'TREINOS'),
          Tab(text: 'AVALIAÇÕES'),
          Tab(text: 'SERVIÇOS'),
        ],
      ),
    );
  }
}

// ── Aba: Resumo ───────────────────────────────────────────────────────────────
class _AbaResumo extends StatelessWidget {
  const _AbaResumo({required this.aluno});
  final AlunoAcademia aluno;

  @override
  Widget build(BuildContext context) {
    final fmtData = DateFormat('dd/MM/yyyy');
    final mensalidade = mock.mensalidades
        .where((m) => m.alunoId == aluno.id)
        .toList()
      ..sort((a, b) => b.vencimento.compareTo(a.vencimento));
    final ultima = mensalidade.isNotEmpty ? mensalidade.first : null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Cards de métricas
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _CardInfo(
              icone: Icons.fitness_center,
              label: 'Plano',
              valor: aluno.plano.label,
              cor: kPrimaria,
            ),
            _CardInfo(
              icone: Icons.calendar_today,
              label: 'Vencimento',
              valor: fmtData.format(aluno.vencimento),
              cor: aluno.situacao.cor,
            ),
            _CardInfo(
              icone: Icons.login_outlined,
              label: 'Último check-in',
              valor: aluno.ultimoCheckin != null
                  ? fmtData.format(aluno.ultimoCheckin!)
                  : 'Nenhum',
              cor: kSucesso,
            ),
            if (aluno.professor != null)
              _CardInfo(
                icone: Icons.person_outline,
                label: 'Professor',
                valor: aluno.professor!,
                cor: kTxt2,
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Última mensalidade
        const Text('Situação financeira',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: kTxt1)),
        const SizedBox(height: 10),
        if (ultima != null)
          _CardMensalidadeResumo(ultima)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: kBorder),
            ),
            child: const Text('Nenhuma mensalidade registrada.',
                style: TextStyle(color: kTxt2)),
          ),
        const SizedBox(height: 24),
        // Check-ins recentes
        const Text('Check-ins recentes',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: kTxt1)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < 3; i++)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaria.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.login_outlined,
                        size: 18, color: kPrimaria),
                  ),
                  title: const Text('Check-in registrado',
                      style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    fmtData.format(
                        DateTime.now().subtract(Duration(days: i * 2))),
                    style: const TextStyle(fontSize: 11, color: kTxt2),
                  ),
                  trailing: const Icon(Icons.check_circle_outline,
                      color: kSucesso, size: 18),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({
    required this.icone,
    required this.label,
    required this.valor,
    required this.cor,
  });
  final IconData icone;
  final String label;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
        boxShadow: kShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, size: 18, color: cor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: kTxt2)),
                Text(valor,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTxt1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMensalidadeResumo extends StatelessWidget {
  const _CardMensalidadeResumo(this.m);
  final MensalidadeAcademia m;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtM = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final cor = m.paga ? kSucesso : kErro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
        boxShadow: kShadow,
      ),
      child: Row(
        children: [
          Icon(
            m.paga ? Icons.check_circle : Icons.warning_amber,
            color: cor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.paga ? 'Mensalidade paga' : 'Mensalidade pendente',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cor)),
                Text(
                    m.paga
                        ? 'Pago em ${fmt.format(m.pagoEm!)}'
                        : 'Vence em ${fmt.format(m.vencimento)}',
                    style: const TextStyle(fontSize: 12, color: kTxt2)),
              ],
            ),
          ),
          Text(fmtM.format(m.valor),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTxt1)),
        ],
      ),
    );
  }
}

// ── Aba: Cadastro ─────────────────────────────────────────────────────────────
class _AbaCadastro extends StatelessWidget {
  const _AbaCadastro({required this.aluno});
  final AlunoAcademia aluno;

  @override
  Widget build(BuildContext context) {
    final fmtData = DateFormat('dd/MM/yyyy');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SecaoCadastro(
          titulo: 'Dados principais',
          campos: [
            _RowCampos(children: [
              _Campo(label: 'Nome', valor: aluno.nome),
              _Campo(label: 'CPF', valor: aluno.cpf ?? '-'),
              _Campo(label: 'Celular', valor: aluno.telefone),
            ]),
            _RowCampos(children: [
              _Campo(
                  label: 'Data de nascimento',
                  valor: aluno.dataNascimento != null
                      ? fmtData.format(aluno.dataNascimento!)
                      : '-'),
              _Campo(label: 'E-mail', valor: aluno.email),
            ]),
            _RowCampos(children: [
              _Campo(label: 'Objetivo', valor: aluno.objetivo ?? '-'),
              _Campo(label: 'Sexo', valor: aluno.sexo?.label ?? '-'),
            ]),
          ],
        ),
        const SizedBox(height: 20),
        _SecaoCadastro(
          titulo: 'Professor',
          campos: [
            _RowCampos(children: [
              _Campo(label: 'Professor responsável', valor: aluno.professor ?? '-'),
            ]),
          ],
        ),
        const SizedBox(height: 20),
        _SecaoCadastro(
          titulo: 'Endereço',
          campos: [
            _RowCampos(children: [
              _Campo(label: 'CEP', valor: aluno.cep ?? '-'),
              Expanded(flex: 3, child: _Campo(label: 'Logradouro', valor: aluno.logradouro ?? '-')),
              _Campo(label: 'Número', valor: aluno.numero ?? '-'),
            ]),
            _RowCampos(children: [
              _Campo(label: 'Bairro', valor: aluno.bairro ?? '-'),
              _Campo(label: 'Cidade', valor: aluno.cidade ?? '-'),
            ]),
          ],
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('SALVAR'),
          ),
        ),
      ],
    );
  }
}

class _SecaoCadastro extends StatelessWidget {
  const _SecaoCadastro({required this.titulo, required this.campos});
  final String titulo;
  final List<Widget> campos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: kTxt1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kBorder),
            boxShadow: kShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < campos.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                campos[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RowCampos extends StatelessWidget {
  const _RowCampos({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          children[i] is Expanded ? children[i] : Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({required this.label, required this.valor});
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: kTxt2)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => Clipboard.setData(ClipboardData(text: valor)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Text(valor,
                style: const TextStyle(fontSize: 14, color: kTxt1)),
          ),
        ),
      ],
    );
  }
}

// ── Aba: Financeiro ───────────────────────────────────────────────────────────
class _AbaFinanceiro extends StatelessWidget {
  const _AbaFinanceiro({required this.alunoId});
  final String alunoId;

  @override
  Widget build(BuildContext context) {
    final fmtData = DateFormat('dd/MM/yyyy');
    final fmtM = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final lista = mock.mensalidades
        .where((m) => m.alunoId == alunoId)
        .toList()
      ..sort((a, b) => b.vencimento.compareTo(a.vencimento));

    return Column(
      children: [
        // Barra de ações
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              const Text('Mensalidades',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kTxt1)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nova mensalidade'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Tabela
        Expanded(
          child: lista.isEmpty
              ? const Center(
                  child: Text('Nenhuma mensalidade.',
                      style: TextStyle(color: kTxt2)),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(kRadius),
                        border: Border.all(color: kBorder),
                        boxShadow: kShadow,
                      ),
                      child: Column(
                        children: [
                          // Cabeçalho da tabela
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: kBgPage,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(kRadius)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Descrição', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                                Expanded(flex: 2, child: Text('Vencimento', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                                Expanded(flex: 2, child: Text('Valor', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                                Expanded(flex: 2, child: Text('Situação', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                                SizedBox(width: 40),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          for (int i = 0; i < lista.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Mensalidade ${DateFormat('MMMM/yyyy', 'pt_BR').format(lista[i].vencimento)}',
                                      style: const TextStyle(
                                          fontSize: 13, color: kTxt1),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      fmtData.format(lista[i].vencimento),
                                      style: const TextStyle(
                                          fontSize: 13, color: kTxt2),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      fmtM.format(lista[i].valor),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: kTxt1),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: BadgeSituacao(
                                      label: lista[i].paga ? 'Pago' : 'Pendente',
                                      cor: lista[i].paga ? kSucesso : kErro,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: PopupMenuButton(
                                      icon: const Icon(Icons.more_vert,
                                          size: 18, color: kTxt2),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'pagar', child: Text('Marcar como pago')),
                                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Aba: Contratos ────────────────────────────────────────────────────────────
class _AbaContratos extends StatelessWidget {
  const _AbaContratos({required this.aluno});
  final AlunoAcademia aluno;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              const Text('Pesquisar por',
                  style: TextStyle(fontSize: 13, color: kTxt2)),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                child: const Text(
                    'Ativo, Encerrado, Suspenso, Bloqueado, Agendado, Erro',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kBorder),
                  boxShadow: kShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      color: kBgPage,
                      child: const Row(
                        children: [
                          Expanded(flex: 4, child: Text('Descrição', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text('Duração', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text('Situação', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Plano ${aluno.plano.label} - Academia',
                              style: const TextStyle(
                                  fontSize: 13, color: kTxt1),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${aluno.plano.meses} ${aluno.plano.meses == 1 ? 'Mês' : 'Meses'}',
                              style: const TextStyle(
                                  fontSize: 13, color: kTxt2),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: BadgeSituacao(
                              label: aluno.ativo ? 'Ativo' : 'Encerrado',
                              cor: aluno.ativo ? kSucesso : kTxt2,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: PopupMenuButton(
                              icon: const Icon(Icons.more_vert,
                                  size: 18, color: kTxt2),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'ver', child: Text('Ver detalhes')),
                                PopupMenuItem(value: 'renovar', child: Text('Renovar')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Abas vazias ───────────────────────────────────────────────────────────────
class _AbaTreinos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AbaVazia(
      icone: Icons.fitness_center,
      titulo: 'Nenhum treino cadastrado',
      subtitulo: 'Os treinos do aluno aparecerão aqui.',
      botao: 'NOVO TREINO',
      onTap: () {},
    );
  }
}

class _AbaAvaliacoes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              const Text('Avaliações',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kTxt1)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ AVALIAÇÃO'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kBorder),
                  boxShadow: kShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      color: kBgPage,
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Avaliador', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text('Data da avaliação', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text('Próxima avaliação', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                          Expanded(flex: 3, child: Text('Tipo', style: TextStyle(fontSize: 12, color: kTxt2, fontWeight: FontWeight.w700))),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          const Expanded(
                              flex: 3, child: Text('Prof. Responsável', style: TextStyle(fontSize: 13, color: kTxt1))),
                          const Expanded(
                              flex: 2, child: Text('19/01/2026', style: TextStyle(fontSize: 13, color: kTxt2))),
                          const Expanded(
                              flex: 2, child: Text('19/04/2026', style: TextStyle(fontSize: 13, color: kTxt2))),
                          Expanded(
                            flex: 3,
                            child: Wrap(
                              spacing: 4,
                              children: [
                                'Anamnese', 'PAR-Q', 'Composição',
                              ]
                                  .map((t) => Chip(
                                        label: Text(t, style: const TextStyle(fontSize: 10)),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: PopupMenuButton(
                              icon: const Icon(Icons.more_vert,
                                  size: 18, color: kTxt2),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'ver', child: Text('Ver avaliação')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AbaServicos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AbaVazia(
      icone: Icons.handshake_outlined,
      titulo: 'Nenhum serviço vinculado',
      subtitulo: 'Os serviços adquiridos pelo aluno aparecerão aqui.',
      botao: 'NOVO SERVIÇO',
      onTap: () {},
    );
  }
}

class _AbaVazia extends StatelessWidget {
  const _AbaVazia({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.botao,
    required this.onTap,
  });
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String botao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 48, color: kTxt2.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: kTxt2)),
          const SizedBox(height: 4),
          Text(subtitulo,
              style: const TextStyle(fontSize: 13, color: kTxt2)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, size: 16),
            label: Text(botao),
          ),
        ],
      ),
    );
  }
}
