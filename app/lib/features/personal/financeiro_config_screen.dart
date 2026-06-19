import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Tela "Financeiro" do profissional.
/// Configura mensalidades e exibe status de pagamento de cada aluno.
class FinanceiroConfigScreen extends ConsumerStatefulWidget {
  const FinanceiroConfigScreen({super.key});

  @override
  ConsumerState<FinanceiroConfigScreen> createState() =>
      _FinanceiroConfigScreenState();
}

class _FinanceiroConfigScreenState
    extends ConsumerState<FinanceiroConfigScreen> {
  final _valor = TextEditingController();
  final _validade = TextEditingController();
  bool _salvando = false;
  bool _carregado = false;

  @override
  void dispose() {
    _valor.dispose();
    _validade.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final valor =
        double.tryParse(_valor.text.trim().replaceAll(',', '.')) ?? 0;
    final validade = int.tryParse(_validade.text.trim()) ?? 30;
    setState(() => _salvando = true);
    await ref.read(financeiroRepositoryProvider).atualizarConfiguracaoEmpresa(
          mensalidadeValor: valor,
          mensalidadeValidadeDias: validade,
        );
    ref.invalidate(configuracaoEmpresaProvider);
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuração financeira atualizada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configuracaoEmpresaProvider);
    final alunosAsync = ref.watch(alunosProvider);

    InputDecoration dec(String rotulo, {String? sufixo}) => InputDecoration(
          labelText: rotulo,
          suffixText: sufixo,
          filled: true,
        );

    final corpo = AsyncView(
      value: configAsync,
      builder: (config) {
        if (!_carregado) {
          _valor.text = config.mensalidadeValor
              .toStringAsFixed(2)
              .replaceAll('.', ',');
          _validade.text = config.mensalidadeValidadeDias.toString();
          _carregado = true;
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Config mensalidade ────────────────────────────────────────
            const SectionTitle('Mensalidade dos alunos'),
            const Text(
              'Valor cobrado de cada aluno pelo acompanhamento '
              'profissional e quantos dias a mensalidade fica válida.',
            ),
            const SizedBox(height: 12),
            ParDeMetricas(
              primeiro: TextFormField(
                controller: _valor,
                keyboardType: TextInputType.number,
                decoration: dec('Valor', sufixo: 'R\$'),
              ),
              segundo: TextFormField(
                controller: _validade,
                keyboardType: TextInputType.number,
                decoration: dec('Validade', sufixo: 'dias'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Salvar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            // ── Status de mensalidades ────────────────────────────────────
            const SectionTitle('Mensalidades dos alunos'),
            AsyncView(
              value: alunosAsync,
              builder: (alunos) {
                if (alunos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Nenhum aluno cadastrado.',
                      style: TextStyle(color: kTextSecondary),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final aluno in alunos)
                      _CardMensalidadeAluno(
                        aluno: aluno,
                        valorPadrao: config.mensalidadeValor,
                        validadeDias: config.mensalidadeValidadeDias,
                      ),
                  ],
                );
              },
            ),

            // ── Assinatura do sistema ─────────────────────────────────────
            const SectionTitle('Assinatura do sistema'),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plano atual: ${_nomePlano(config.plano)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.assinaturaValidade != null
                          ? 'Válido até '
                              '${fmtDataCurta.format(config.assinaturaValidade!)}'
                          : 'Sem validade definida',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Básico',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Até 5 alunos — R\$ 20,00/mês'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Pro',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Alunos ilimitados — R\$ 35,00/mês'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    return TelaResponsiva(
      titulo: 'Financeiro',
      body: PaginaCentralizada(maxWidth: 640, child: corpo),
    );
  }

  String _nomePlano(String plano) {
    switch (plano) {
      case 'pro':
        return 'Pro';
      case 'premium':
        return 'Premium';
      default:
        return 'Básico';
    }
  }
}

// ─────────────────────────────────────────────── Card por aluno

class _CardMensalidadeAluno extends ConsumerWidget {
  const _CardMensalidadeAluno({
    required this.aluno,
    required this.valorPadrao,
    required this.validadeDias,
  });

  final Aluno aluno;
  final double valorPadrao;
  final int validadeDias;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mensalidadesAsync = ref.watch(mensalidadesProvider(aluno.id));
    final brand = context.brand;

    return mensalidadesAsync.when(
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox.shrink(),
      data: (mensalidades) {
        final hoje = DateTime.now();
        final ultima = mensalidades.isEmpty ? null : mensalidades.first;
        final status = _calcularStatus(ultima, hoje);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: status.cor.withValues(alpha: 0.3)),
            boxShadow: kShadowCard,
          ),
          child: Row(
            children: [
              IniciaisAvatar(aluno.iniciais),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno.nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.descricao,
                      style: TextStyle(
                          fontSize: 12, color: status.cor),
                    ),
                  ],
                ),
              ),
              // Badge de status
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.rotulo,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: status.cor),
                ),
              ),
              const SizedBox(width: 8),
              // Botão gerar mensalidade
              if (status == _Status.sem || status == _Status.vencida)
                IconButton(
                  tooltip: 'Gerar mensalidade',
                  icon: Icon(Icons.add_circle_outline,
                      color: brand.primaria, size: 22),
                  onPressed: () async {
                    final competencia = DateTime(hoje.year, hoje.month, 1);
                    await ref
                        .read(financeiroRepositoryProvider)
                        .gerar(aluno.id, competencia, valorPadrao,
                            vencimento: hoje.add(Duration(days: validadeDias)));
                    ref.invalidate(mensalidadesProvider(aluno.id));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  _Status _calcularStatus(Mensalidade? ultima, DateTime hoje) {
    if (ultima == null) return _Status.sem;
    if (ultima.pagoEm != null) return _Status.paga;
    if (ultima.vencimento.isBefore(hoje)) return _Status.vencida;
    return _Status.pendente;
  }
}

enum _Status { paga, pendente, vencida, sem }

extension _StatusX on _Status {
  Color get cor => switch (this) {
        _Status.paga => const Color(0xFF22C55E),
        _Status.pendente => const Color(0xFFF59E0B),
        _Status.vencida => const Color(0xFFEF4444),
        _Status.sem => const Color(0xFF9CA3AF),
      };

  String get rotulo => switch (this) {
        _Status.paga => 'Pago',
        _Status.pendente => 'Pendente',
        _Status.vencida => 'Vencida',
        _Status.sem => 'Sem mensalidade',
      };

  String get descricao => switch (this) {
        _Status.paga => 'Mensalidade em dia',
        _Status.pendente => 'Aguardando pagamento',
        _Status.vencida => 'Mensalidade vencida',
        _Status.sem => 'Nenhuma mensalidade gerada',
      };
}
