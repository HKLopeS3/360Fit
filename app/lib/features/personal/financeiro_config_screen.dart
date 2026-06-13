import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Tela "Financeiro" do profissional: valor/validade da mensalidade
/// cobrada dos alunos e referência da assinatura do sistema.
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

    InputDecoration dec(String rotulo, {String? sufixo}) => InputDecoration(
          labelText: rotulo,
          suffixText: sufixo,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: PaginaCentralizada(
        maxWidth: 560,
        child: AsyncView(
          value: configAsync,
          builder: (config) {
            if (!_carregado) {
              _valor.text =
                  config.mensalidadeValor.toStringAsFixed(2).replaceAll('.', ',');
              _validade.text = config.mensalidadeValidadeDias.toString();
              _carregado = true;
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
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
                const SizedBox(height: 12),
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
        ),
      ),
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
