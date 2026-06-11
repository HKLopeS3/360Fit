import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../providers.dart' show alunoLogadoId;
import 'repositories.dart';

/// Implementações reais sobre o Supabase (Fase 2).
///
/// Só são usadas quando `AppConfig.usarSupabase` é verdadeiro (credenciais
/// passadas via --dart-define). O contrato é o mesmo dos mocks, então a UI
/// não muda. Mapeiam snake_case (Postgres) ↔ modelos Dart.

SupabaseClient get _db => Supabase.instance.client;

/// As telas do aluno usam o sentinela [alunoLogadoId]; aqui ele é resolvido
/// para o registro real em `alunos` vinculado ao usuário autenticado.
Future<String> _resolveAlunoId(String alunoId) async {
  if (alunoId != alunoLogadoId) return alunoId;
  final linha = await _db
      .from('alunos')
      .select('id')
      .eq('perfil_id', _db.auth.currentUser!.id)
      .single();
  return linha['id'] as String;
}

class SupabaseAuthRepository implements AuthRepository {
  /// Usuários do seed de demonstração (supabase/seed.sql).
  static const _emailsDemo = {
    PerfilUsuario.aluno: 'carlos.mendes@email.com',
    PerfilUsuario.personal: 'joao.silva@360fit.com.br',
  };

  @override
  Future<Usuario> login(PerfilUsuario perfil) async {
    final resposta = await _db.auth.signInWithPassword(
      email: _emailsDemo[perfil]!,
      password: AppConfig.demoSenha,
    );
    final user = resposta.user!;
    final dados =
        await _db.from('perfis').select().eq('id', user.id).single();
    return Usuario(
      id: user.id,
      nome: dados['nome'] as String,
      email: dados['email'] as String,
      perfil: perfil,
    );
  }
}

class SupabaseAlunoRepository implements AlunoRepository {
  Aluno _mapear(Map<String, dynamic> l) => Aluno(
        id: l['id'] as String,
        nome: l['nome'] as String,
        idade: (l['idade'] as num?)?.toInt() ?? 0,
        objetivo: l['objetivo'] as String,
        inicio: DateTime.parse(l['inicio'] as String),
        frequenciaSemanal: (l['frequencia_semanal'] as num).toInt(),
        pesoAtualKg: (l['peso_atual_kg'] as num?)?.toDouble() ?? 0,
        riscoEvasao: l['risco_evasao'] as bool,
      );

  @override
  Future<List<Aluno>> listar() async {
    final linhas = await _db.from('alunos').select().order('nome');
    return [for (final l in linhas) _mapear(l)];
  }

  @override
  Future<Aluno> buscar(String id) async {
    final l =
        await _db.from('alunos').select().eq('id', await _resolveAlunoId(id)).single();
    return _mapear(l);
  }
}

class SupabaseExercicioRepository implements ExercicioRepository {
  /// Cache da biblioteca para o lookup síncrono [porId] usado pela UI.
  final Map<String, Exercicio> _cache = {};

  @override
  Future<List<Exercicio>> biblioteca() async {
    final linhas = await _db.from('exercicios').select().order('nome');
    final lista = [
      for (final l in linhas)
        Exercicio(
          id: l['id'] as String,
          nome: l['nome'] as String,
          grupoMuscular: l['grupo_muscular'] as String,
          equipamento: l['equipamento'] as String,
        ),
    ];
    _cache..clear()..addEntries(lista.map((e) => MapEntry(e.id, e)));
    return lista;
  }

  @override
  Exercicio porId(String id) =>
      _cache[id] ??
      Exercicio(
          id: id, nome: 'Exercício', grupoMuscular: '—', equipamento: '—');
}

class SupabaseTreinoRepository implements TreinoRepository {
  Treino _mapear(Map<String, dynamic> l) => Treino(
        id: l['id'] as String,
        alunoId: l['aluno_id'] as String,
        nome: l['nome'] as String,
        foco: l['foco'] as String,
        diasSemana: [for (final d in l['dias_semana'] as List) (d as num).toInt()],
        itens: [
          for (final i in (l['treino_itens'] as List? ?? [])
            ..sort((a, b) => ((a['ordem'] ?? 0) as num)
                .compareTo((b['ordem'] ?? 0) as num)))
            ItemTreino(
              exercicioId: i['exercicio_id'] as String,
              series: (i['series'] as num).toInt(),
              repeticoes: i['repeticoes'] as String,
              cargaKg: (i['carga_kg'] as num).toDouble(),
              descansoSeg: (i['descanso_seg'] as num).toInt(),
            ),
        ],
      );

  @override
  Future<List<Treino>> doAluno(String alunoId) async {
    final linhas = await _db
        .from('treinos')
        .select('*, treino_itens(*)')
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .order('nome');
    return [for (final l in linhas) _mapear(l)];
  }

  @override
  Future<Treino?> treinoDoDia(String alunoId) async {
    final treinos = await doAluno(alunoId);
    final hoje = DateTime.now().weekday;
    for (final t in treinos) {
      if (t.diasSemana.contains(hoje)) return t;
    }
    return null;
  }

  @override
  Future<void> salvar(Treino treino) async {
    final empresa = await _empresaDoUsuario();
    final dados = {
      'empresa_id': empresa,
      'aluno_id': treino.alunoId,
      'nome': treino.nome,
      'foco': treino.foco,
      'dias_semana': treino.diasSemana,
    };
    String treinoId = treino.id;
    final ehNovo = treino.id.startsWith('t-novo-');
    if (ehNovo) {
      final criado =
          await _db.from('treinos').insert(dados).select('id').single();
      treinoId = criado['id'] as String;
    } else {
      await _db.from('treinos').update(dados).eq('id', treino.id);
      await _db.from('treino_itens').delete().eq('treino_id', treino.id);
    }
    if (treino.itens.isNotEmpty) {
      await _db.from('treino_itens').insert([
        for (final (i, item) in treino.itens.indexed)
          {
            'treino_id': treinoId,
            'exercicio_id': item.exercicioId,
            'ordem': i,
            'series': item.series,
            'repeticoes': item.repeticoes,
            'carga_kg': item.cargaKg,
            'descanso_seg': item.descansoSeg,
          },
      ]);
    }
  }

  Future<String> _empresaDoUsuario() async {
    final l = await _db
        .from('perfis')
        .select('empresa_id')
        .eq('id', _db.auth.currentUser!.id)
        .single();
    return l['empresa_id'] as String;
  }
}

class SupabaseAgendaRepository implements AgendaRepository {
  @override
  Future<List<Agendamento>> proximos({String? alunoId}) async {
    var query = _db
        .from('agendamentos')
        .select()
        .gte('data_hora',
            DateTime.now().subtract(const Duration(hours: 12)).toIso8601String());
    if (alunoId != null) {
      query = query.eq('aluno_id', await _resolveAlunoId(alunoId));
    }
    final linhas = await query.order('data_hora', ascending: true);
    return [
      for (final l in linhas)
        Agendamento(
          id: l['id'] as String,
          alunoId: l['aluno_id'] as String,
          titulo: l['titulo'] as String,
          tipo: TipoAgendamento.values.byName(l['tipo'] as String),
          dataHora: DateTime.parse(l['data_hora'] as String).toLocal(),
          local: l['local'] as String,
        ),
    ];
  }
}

class SupabaseChatRepository implements ChatRepository {
  @override
  Future<List<Mensagem>> conversa(String alunoId) async {
    final id = await _resolveAlunoId(alunoId);
    final linhas = await _db
        .from('mensagens')
        .select()
        .eq('aluno_id', id)
        .order('criada_em', ascending: true);
    final euSouAluno = await _souAluno();
    return [
      for (final l in linhas)
        _mapear(l, autorEhAluno: euSouAluno
            ? l['autor_perfil_id'] == _db.auth.currentUser!.id
            : l['autor_perfil_id'] != _db.auth.currentUser!.id),
    ];
  }

  @override
  Future<Mensagem> enviar({
    required String alunoId,
    required bool doAluno,
    required String texto,
  }) async {
    final id = await _resolveAlunoId(alunoId);
    final empresa = await _db
        .from('perfis')
        .select('empresa_id')
        .eq('id', _db.auth.currentUser!.id)
        .single();
    final l = await _db
        .from('mensagens')
        .insert({
          'empresa_id': empresa['empresa_id'],
          'aluno_id': id,
          'autor_perfil_id': _db.auth.currentUser!.id,
          'texto': texto,
        })
        .select()
        .single();
    return _mapear(l, autorEhAluno: doAluno);
  }

  Mensagem _mapear(Map<String, dynamic> l, {required bool autorEhAluno}) =>
      Mensagem(
        id: l['id'] as String,
        alunoId: l['aluno_id'] as String,
        doAluno: autorEhAluno,
        texto: l['texto'] as String,
        dataHora: DateTime.parse(l['criada_em'] as String).toLocal(),
      );

  Future<bool> _souAluno() async {
    final l = await _db
        .from('perfis')
        .select('papel')
        .eq('id', _db.auth.currentUser!.id)
        .single();
    return l['papel'] == 'aluno';
  }
}

class SupabaseEvolucaoRepository implements EvolucaoRepository {
  @override
  Future<List<RegistroPeso>> pesos(String alunoId) async {
    final linhas = await _db
        .from('registros_peso')
        .select()
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .order('data', ascending: true);
    return [
      for (final l in linhas)
        RegistroPeso(
          data: DateTime.parse(l['data'] as String),
          pesoKg: (l['peso_kg'] as num).toDouble(),
        ),
    ];
  }

  @override
  Future<List<AvaliacaoFisica>> avaliacoes(String alunoId) async {
    final linhas = await _db
        .from('avaliacoes_fisicas')
        .select()
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .order('data', ascending: true);
    return [
      for (final l in linhas)
        AvaliacaoFisica(
          data: DateTime.parse(l['data'] as String),
          pesoKg: (l['peso_kg'] as num).toDouble(),
          gorduraPct: (l['gordura_pct'] as num?)?.toDouble() ?? 0,
          massaMagraKg: (l['massa_magra_kg'] as num?)?.toDouble() ?? 0,
        ),
    ];
  }

  @override
  Future<List<RegistroCarga>> cargas(String alunoId, String exercicioId) async {
    final linhas = await _db
        .from('registros_carga')
        .select()
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .eq('exercicio_id', exercicioId)
        .order('data', ascending: true);
    return [
      for (final l in linhas)
        RegistroCarga(
          exercicioId: exercicioId,
          data: DateTime.parse(l['data'] as String),
          cargaKg: (l['carga_kg'] as num).toDouble(),
        ),
    ];
  }
}
