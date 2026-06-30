import 'package:flutter/material.dart';

// ── Perfil de acesso ──────────────────────────────────────────────────────────
enum PerfilAcademia { gestor, recepcionista }

class UsuarioAcademia {
  const UsuarioAcademia({
    required this.id,
    required this.nome,
    required this.perfil,
    required this.academiaId,
    required this.academiaNome,
  });
  final String id;
  final String nome;
  final PerfilAcademia perfil;
  final String academiaId;
  final String academiaNome;
}

// ── Plano do aluno ────────────────────────────────────────────────────────────
enum PlanoTipo { mensal, trimestral, semestral, anual }

extension PlanoTipoX on PlanoTipo {
  String get label => switch (this) {
        PlanoTipo.mensal      => 'Mensal',
        PlanoTipo.trimestral  => 'Trimestral',
        PlanoTipo.semestral   => 'Semestral',
        PlanoTipo.anual       => 'Anual',
      };
  int get meses => switch (this) {
        PlanoTipo.mensal      => 1,
        PlanoTipo.trimestral  => 3,
        PlanoTipo.semestral   => 6,
        PlanoTipo.anual       => 12,
      };
}

// ── Situação financeira ───────────────────────────────────────────────────────
enum SituacaoFinanceira { emDia, vencendo, inadimplente }

extension SituacaoX on SituacaoFinanceira {
  String get label => switch (this) {
        SituacaoFinanceira.emDia        => 'Em dia',
        SituacaoFinanceira.vencendo     => 'Vencendo',
        SituacaoFinanceira.inadimplente => 'Inadimplente',
      };
  Color get cor => switch (this) {
        SituacaoFinanceira.emDia        => const Color(0xFF22C55E),
        SituacaoFinanceira.vencendo     => const Color(0xFFF59E0B),
        SituacaoFinanceira.inadimplente => const Color(0xFFEF4444),
      };
}

// ── Aluno da academia ─────────────────────────────────────────────────────────
class AlunoAcademia {
  const AlunoAcademia({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.plano,
    required this.vencimento,
    required this.ativo,
    this.fotoUrl,
    this.ultimoCheckin,
  });

  final String id;
  final String nome;
  final String email;
  final String telefone;
  final PlanoTipo plano;
  final DateTime vencimento;
  final bool ativo;
  final String? fotoUrl;
  final DateTime? ultimoCheckin;

  String get iniciais {
    final partes = nome.trim().split(' ');
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes.last[0]}'.toUpperCase();
  }

  SituacaoFinanceira get situacao {
    final hoje = DateTime.now();
    final diff = vencimento.difference(hoje).inDays;
    if (diff < 0) return SituacaoFinanceira.inadimplente;
    if (diff <= 5) return SituacaoFinanceira.vencendo;
    return SituacaoFinanceira.emDia;
  }
}

// ── Mensalidade ───────────────────────────────────────────────────────────────
class MensalidadeAcademia {
  const MensalidadeAcademia({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.valor,
    required this.vencimento,
    this.pagoEm,
  });
  final String id;
  final String alunoId;
  final String alunoNome;
  final double valor;
  final DateTime vencimento;
  final DateTime? pagoEm;
  bool get paga => pagoEm != null;
}

// ── Turma / Aula ──────────────────────────────────────────────────────────────
class Turma {
  const Turma({
    required this.id,
    required this.nome,
    required this.professor,
    required this.horario,
    required this.diasSemana,
    required this.vagas,
    required this.inscritos,
    required this.sala,
  });
  final String id;
  final String nome;
  final String professor;
  final TimeOfDay horario;
  final List<int> diasSemana; // DateTime.monday … DateTime.sunday
  final int vagas;
  final int inscritos;
  final String sala;

  bool get lotada => inscritos >= vagas;
  String get horaStr {
    final h = horario.hour.toString().padLeft(2, '0');
    final m = horario.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── CheckIn ───────────────────────────────────────────────────────────────────
class CheckIn {
  const CheckIn({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.alunoIniciais,
    required this.quando,
  });
  final String id;
  final String alunoId;
  final String alunoNome;
  final String alunoIniciais;
  final DateTime quando;
}
