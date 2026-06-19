// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../shared/widgets.dart';

/// Tela do aluno para visualizar uma avaliação física completa
/// e fazer download em PDF via impressão do browser.
class MinhaAvaliacaoScreen extends StatelessWidget {
  const MinhaAvaliacaoScreen({
    super.key,
    required this.avaliacao,
    required this.nomeAluno,
    required this.nomePersonal,
  });

  final AvaliacaoFisica avaliacao;
  final String nomeAluno;
  final String nomePersonal;

  void _imprimirPdf(BuildContext context) {
    final blob = html.Blob([_gerarHtml()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final janela = html.window.open(url, '_blank') as html.Window?;
    Future.delayed(const Duration(seconds: 1), () {
      janela?.print();
    });
  }

  String _gerarHtml() {
    final fmt = DateFormat("dd/MM/yyyy");
    final data = fmt.format(avaliacao.data);
    final medidasHtml = avaliacao.medidas.entries
        .map((e) =>
            '<tr><td>${e.key}</td><td><b>${e.value.toStringAsFixed(1)} cm</b></td></tr>')
        .join('\n');

    final dobrasHtml = avaliacao.pro.dobras.isNotEmpty
        ? avaliacao.pro.dobras.entries
            .map((e) =>
                '<tr><td>${_rotuloSitio[e.key] ?? e.key}</td><td><b>${e.value.toStringAsFixed(1)} mm</b></td></tr>')
            .join('\n')
        : '';

    final testesHtml = avaliacao.pro.testes.isNotEmpty
        ? avaliacao.pro.testes.entries
            .map((e) => '<tr><td>${e.key}</td><td><b>${e.value.toStringAsFixed(1)}</b></td></tr>')
            .join('\n')
        : '';

    final obsHtml = avaliacao.observacoes.isNotEmpty
        ? '<div class="section"><h3>Observações</h3><p>${avaliacao.observacoes}</p></div>'
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <title>Avaliação Física — $nomeAluno</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Arial, sans-serif; font-size: 13px; color: #1a1a1a; padding: 32px; }
    .header { border-bottom: 3px solid #1B8A6B; padding-bottom: 16px; margin-bottom: 24px; display: flex; justify-content: space-between; align-items: flex-end; }
    .header h1 { font-size: 20px; color: #1B8A6B; }
    .header .meta { font-size: 11px; color: #666; text-align: right; }
    .section { margin-bottom: 20px; }
    .section h3 { font-size: 13px; font-weight: bold; color: #1B8A6B; border-left: 3px solid #1B8A6B; padding-left: 8px; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 0.5px; }
    .metricas { display: flex; gap: 16px; margin-bottom: 16px; }
    .metrica { flex: 1; background: #f0faf6; border-radius: 8px; padding: 12px; text-align: center; }
    .metrica .valor { font-size: 22px; font-weight: bold; color: #1B8A6B; }
    .metrica .rotulo { font-size: 11px; color: #666; margin-top: 2px; }
    table { width: 100%; border-collapse: collapse; font-size: 12px; }
    table td { padding: 5px 8px; border-bottom: 1px solid #eee; }
    table td:first-child { color: #555; width: 55%; }
    .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .footer { margin-top: 32px; border-top: 1px solid #eee; padding-top: 12px; font-size: 10px; color: #999; display: flex; justify-content: space-between; }
    @media print { body { padding: 16px; } }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <h1>Avaliação Física</h1>
      <div style="color:#555; margin-top:4px;">$nomeAluno</div>
    </div>
    <div class="meta">
      Data: <b>$data</b><br/>
      Profissional: <b>$nomePersonal</b><br/>
      360Fit
    </div>
  </div>

  <div class="section">
    <h3>Composição Corporal</h3>
    <div class="metricas">
      <div class="metrica">
        <div class="valor">${avaliacao.pesoKg.toStringAsFixed(1)} kg</div>
        <div class="rotulo">Peso</div>
      </div>
      <div class="metrica">
        <div class="valor">${avaliacao.gorduraPct.toStringAsFixed(1)}%</div>
        <div class="rotulo">Gordura</div>
      </div>
      <div class="metrica">
        <div class="valor">${avaliacao.massaMagraKg.toStringAsFixed(1)} kg</div>
        <div class="rotulo">Massa magra</div>
      </div>
    </div>
  </div>

  ${avaliacao.medidas.isNotEmpty ? '''
  <div class="section">
    <h3>Medidas (cm)</h3>
    <div class="cols">
      <table>
        ${avaliacao.medidas.entries.take((avaliacao.medidas.length / 2).ceil()).map((e) => '<tr><td>${e.key}</td><td><b>${e.value.toStringAsFixed(1)} cm</b></td></tr>').join('\n')}
      </table>
      <table>
        ${avaliacao.medidas.entries.skip((avaliacao.medidas.length / 2).ceil()).map((e) => '<tr><td>${e.key}</td><td><b>${e.value.toStringAsFixed(1)} cm</b></td></tr>').join('\n')}
      </table>
    </div>
  </div>
  ''' : ''}

  ${dobrasHtml.isNotEmpty ? '''
  <div class="section">
    <h3>Dobras Cutâneas (mm)</h3>
    <table>$dobrasHtml</table>
  </div>
  ''' : ''}

  ${testesHtml.isNotEmpty ? '''
  <div class="section">
    <h3>Testes</h3>
    <table>$testesHtml</table>
  </div>
  ''' : ''}

  $obsHtml

  <div class="footer">
    <span>360Fit — Sistema de Gestão Fitness</span>
    <span>Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</span>
  </div>
</body>
</html>
''';
  }

  static const _rotuloSitio = {
    'tricipital': 'Tricipital',
    'subescapular': 'Subescapular',
    'peitoral': 'Peitoral',
    'axilar_media': 'Axilar média',
    'suprailiaca': 'Suprailíaca',
    'abdominal': 'Abdominal',
    'coxa': 'Coxa',
    'panturrilha': 'Panturrilha',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final fmt = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR');

    Widget secao(String titulo) => SectionTitle(titulo, topPadding: 20);

    Widget linhaInfo(String rotulo, String valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text(rotulo,
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 13))),
              Expanded(
                  flex: 3,
                  child: Text(valor,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                          fontSize: 13))),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Avaliação ${fmtDiaMes.format(avaliacao.data)}/${avaliacao.data.year}'),
        actions: [
          FilledButton.icon(
            onPressed: () => _imprimirPdf(context),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: brand.primaria,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: PaginaCentralizada(
        maxWidth: 600,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── cabeçalho data ──
            Text(
              capitalizar(fmt.format(avaliacao.data)),
              style: theme.textTheme.bodySmall?.copyWith(color: kTextSecondary),
            ),
            const SizedBox(height: 16),

            // ── composição corporal ──
            Row(
              children: [
                _MetricaDestaque(
                  valor: '${avaliacao.pesoKg.toStringAsFixed(1)} kg',
                  rotulo: 'Peso',
                  cor: brand.primaria,
                ),
                const SizedBox(width: 10),
                _MetricaDestaque(
                  valor: '${avaliacao.gorduraPct.toStringAsFixed(1)}%',
                  rotulo: 'Gordura',
                  cor: _corGordura(avaliacao.gorduraPct),
                ),
                const SizedBox(width: 10),
                _MetricaDestaque(
                  valor: '${avaliacao.massaMagraKg.toStringAsFixed(1)} kg',
                  rotulo: 'Massa magra',
                  cor: const Color(0xFF06B6D4),
                ),
              ],
            ),

            // ── medidas ──
            if (avaliacao.medidas.isNotEmpty) ...[
              secao('Medidas (cm)'),
              AppCard(
                child: Column(
                  children: [
                    for (final e in avaliacao.medidas.entries)
                      linhaInfo(e.key, '${e.value.toStringAsFixed(1)} cm'),
                  ],
                ),
              ),
            ],

            // ── dobras ──
            if (avaliacao.pro.dobras.isNotEmpty) ...[
              secao('Dobras cutâneas (mm)'),
              AppCard(
                child: Column(
                  children: [
                    for (final e in avaliacao.pro.dobras.entries)
                      linhaInfo(
                          _rotuloSitio[e.key] ?? e.key,
                          '${e.value.toStringAsFixed(1)} mm'),
                  ],
                ),
              ),
            ],

            // ── bioimpedância ──
            if (avaliacao.pro.bioimpedancia.isNotEmpty) ...[
              secao('Bioimpedância'),
              AppCard(
                child: Column(
                  children: [
                    if (avaliacao.pro.bioimpedancia['agua_pct'] != null)
                      linhaInfo('Água corporal',
                          '${avaliacao.pro.bioimpedancia['agua_pct']!.toStringAsFixed(1)}%'),
                    if (avaliacao.pro.bioimpedancia['gordura_visceral'] != null)
                      linhaInfo('Gordura visceral (nível)',
                          avaliacao.pro.bioimpedancia['gordura_visceral']!.toStringAsFixed(0)),
                  ],
                ),
              ),
            ],

            // ── testes ──
            if (avaliacao.pro.testes.isNotEmpty) ...[
              secao('Testes físicos'),
              AppCard(
                child: Column(
                  children: [
                    if (avaliacao.pro.testes['um_rm_kg'] != null)
                      linhaInfo('1RM estimado (Epley)',
                          '${avaliacao.pro.testes['um_rm_kg']!.toStringAsFixed(1)} kg'),
                    if (avaliacao.pro.testes['cooper_m'] != null)
                      linhaInfo('Cooper 12 min',
                          '${avaliacao.pro.testes['cooper_m']!.toStringAsFixed(0)} m'),
                    if (avaliacao.pro.testes['vo2'] != null)
                      linhaInfo('VO₂ máx estimado',
                          '${avaliacao.pro.testes['vo2']!.toStringAsFixed(1)} ml/kg/min'),
                    if (avaliacao.pro.testes['wells_cm'] != null)
                      linhaInfo('Banco de Wells (flexibilidade)',
                          '${avaliacao.pro.testes['wells_cm']!.toStringAsFixed(1)} cm'),
                  ],
                ),
              ),
            ],

            // ── observações ──
            if (avaliacao.observacoes.isNotEmpty) ...[
              secao('Observações'),
              AppCard(
                child: Text(avaliacao.observacoes,
                    style: const TextStyle(
                        color: kTextPrimary, fontSize: 13, height: 1.5)),
              ),
            ],

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _imprimirPdf(context),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Baixar / imprimir PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _corGordura(double pct) {
    if (pct < 10) return const Color(0xFF3B82F6);
    if (pct < 20) return const Color(0xFF22C55E);
    if (pct < 28) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _MetricaDestaque extends StatelessWidget {
  const _MetricaDestaque({
    required this.valor,
    required this.rotulo,
    required this.cor,
  });

  final String valor;
  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              style: const TextStyle(fontSize: 11, color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
