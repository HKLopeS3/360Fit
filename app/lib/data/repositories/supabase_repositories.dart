import 'dart:async';
import 'dart:typed_data';

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
  static const emailsDemo = {
    PerfilUsuario.aluno: 'carlos.mendes@email.com',
    PerfilUsuario.personal: 'joao.silva@360fit.com.br',
  };

  @override
  Future<Usuario> login(PerfilUsuario perfil) =>
      entrarComEmailSenha(emailsDemo[perfil]!, AppConfig.demoSenha);

  @override
  Future<Usuario> entrarComEmailSenha(String email, String senha) async {
    final resposta = await _db.auth.signInWithPassword(
      email: email.trim(),
      password: senha,
    );
    return _usuarioDoPerfil(resposta.user!.id);
  }

  @override
  Future<Usuario?> usuarioAtual() async {
    final sessao = _db.auth.currentSession;
    if (sessao == null) return null;
    try {
      return await _usuarioDoPerfil(sessao.user.id);
    } catch (_) {
      // Sessão inválida/expirada: limpa e exige novo login.
      await _db.auth.signOut();
      return null;
    }
  }

  @override
  Future<void> sair() => _db.auth.signOut();

  @override
  Future<void> recuperarSenha(String email) =>
      _db.auth.resetPasswordForEmail(email.trim());

  Future<Usuario> _usuarioDoPerfil(String userId) async {
    final dados =
        await _db.from('perfis').select().eq('id', userId).single();
    final papel = dados['papel'] as String;
    return Usuario(
      id: userId,
      nome: dados['nome'] as String,
      email: dados['email'] as String,
      // admin_empresa usa a visão do profissional até o painel admin existir.
      perfil:
          papel == 'aluno' ? PerfilUsuario.aluno : PerfilUsuario.personal,
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
        sexo: (l['sexo'] as String?) ?? 'masculino',
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

  Map<String, dynamic> _paraLinha(Aluno a) => {
        'nome': a.nome,
        'idade': a.idade,
        'objetivo': a.objetivo,
        'frequencia_semanal': a.frequenciaSemanal,
        'peso_atual_kg': a.pesoAtualKg,
        'risco_evasao': a.riscoEvasao,
        'sexo': a.sexo,
      };

  @override
  Future<Aluno> criar(Aluno aluno) async {
    final perfil = await _db
        .from('perfis')
        .select('empresa_id')
        .eq('id', _db.auth.currentUser!.id)
        .single();
    final l = await _db
        .from('alunos')
        .insert({
          ..._paraLinha(aluno),
          'empresa_id': perfil['empresa_id'],
          'profissional_id': _db.auth.currentUser!.id,
          'inicio': aluno.inicio.toIso8601String().substring(0, 10),
        })
        .select()
        .single();
    return _mapear(l);
  }

  @override
  Future<void> atualizar(Aluno aluno) async {
    await _db.from('alunos').update(_paraLinha(aluno)).eq('id', aluno.id);
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
          videoUrl: (l['video_url'] as String?) ?? '',
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

  @override
  Future<void> definirVideo(String exercicioId, String url) async {
    await _db
        .from('exercicios')
        .update({'video_url': url}).eq('id', exercicioId);
    final atual = _cache[exercicioId];
    if (atual != null) {
      _cache[exercicioId] = Exercicio(
        id: atual.id,
        nome: atual.nome,
        grupoMuscular: atual.grupoMuscular,
        equipamento: atual.equipamento,
        videoUrl: url,
      );
    }
  }
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
              cadencia: (i['cadencia'] as String?) ?? '',
              metodo: MetodoTreinoX.doBd(i['metodo'] as String?),
              agrupamento: (i['agrupamento'] as num?)?.toInt() ?? 0,
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
            'cadencia': item.cadencia,
            'metodo': item.metodo.bd,
            'agrupamento': item.agrupamento,
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

  @override
  Future<void> concluirTreino(TreinoConcluido conclusao) async {
    final alunoId = await _resolveAlunoId(conclusao.alunoId);
    final criado = await _db
        .from('treinos_concluidos')
        .insert({
          'empresa_id': await _empresaDoUsuario(),
          'aluno_id': alunoId,
          'treino_id': conclusao.treinoId,
          'nome_treino': conclusao.nomeTreino,
          'data': conclusao.data.toIso8601String(),
          'duracao_min': conclusao.duracaoMin,
        })
        .select('id')
        .single();
    if (conclusao.series.isNotEmpty) {
      await _db.from('series_realizadas').insert([
        for (final s in conclusao.series)
          {
            'conclusao_id': criado['id'],
            'indice_item': s.indiceItem,
            'serie': s.serie,
            'carga_kg': s.cargaKg,
            'repeticoes': s.repeticoes,
          },
      ]);
    }
  }

  @override
  Future<List<Programa>> programas(String alunoId) async {
    final linhas = await _db
        .from('programas')
        .select()
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .order('inicio', ascending: false);
    return [
      for (final l in linhas)
        Programa(
          id: l['id'] as String,
          alunoId: l['aluno_id'] as String,
          nome: l['nome'] as String,
          objetivo: l['objetivo'] as String,
          inicio: DateTime.parse(l['inicio'] as String),
          fim: DateTime.parse(l['fim'] as String),
          macrociclo: l['macrociclo'] as String,
          mesociclo: l['mesociclo'] as String,
          microciclo: l['microciclo'] as String,
          observacoes: l['observacoes'] as String,
        ),
    ];
  }

  @override
  Future<void> salvarPrograma(Programa p) async {
    final dados = {
      'empresa_id': await _empresaDoUsuario(),
      'aluno_id': p.alunoId,
      'nome': p.nome,
      'objetivo': p.objetivo,
      'inicio': p.inicio.toIso8601String().substring(0, 10),
      'fim': p.fim.toIso8601String().substring(0, 10),
      'macrociclo': p.macrociclo,
      'mesociclo': p.mesociclo,
      'microciclo': p.microciclo,
      'observacoes': p.observacoes,
    };
    if (p.id.startsWith('pg-novo-')) {
      await _db.from('programas').insert(dados);
    } else {
      await _db.from('programas').update(dados).eq('id', p.id);
    }
  }

  @override
  Future<List<TreinoConcluido>> historicoConcluidos(String alunoId) async {
    final linhas = await _db
        .from('treinos_concluidos')
        .select('*, series_realizadas(*)')
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .order('data', ascending: false);
    return [
      for (final l in linhas)
        TreinoConcluido(
          id: l['id'] as String,
          alunoId: l['aluno_id'] as String,
          treinoId: (l['treino_id'] as String?) ?? '',
          nomeTreino: l['nome_treino'] as String,
          data: DateTime.parse(l['data'] as String).toLocal(),
          duracaoMin: (l['duracao_min'] as num).toInt(),
          series: [
            for (final s in (l['series_realizadas'] as List? ?? []))
              SerieRealizada(
                indiceItem: (s['indice_item'] as num).toInt(),
                serie: (s['serie'] as num).toInt(),
                cargaKg: (s['carga_kg'] as num).toDouble(),
                repeticoes: (s['repeticoes'] as num).toInt(),
              ),
          ],
        ),
    ];
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
          status: StatusAgendamento.values
              .byName((l['status'] as String?) ?? 'pendente'),
        ),
    ];
  }

  @override
  Future<void> criar(Agendamento agendamento) async {
    final perfil = await _db
        .from('perfis')
        .select('empresa_id')
        .eq('id', _db.auth.currentUser!.id)
        .single();
    await _db.from('agendamentos').insert({
      'empresa_id': perfil['empresa_id'],
      'aluno_id': agendamento.alunoId,
      'profissional_id': _db.auth.currentUser!.id,
      'titulo': agendamento.titulo,
      'tipo': agendamento.tipo.name,
      'data_hora': agendamento.dataHora.toIso8601String(),
      'local': agendamento.local,
      'status': agendamento.status.name,
    });
  }

  @override
  Future<void> remarcar(String id, DateTime novaDataHora) async {
    await _db.from('agendamentos').update({
      'data_hora': novaDataHora.toIso8601String(),
      'status': StatusAgendamento.pendente.name,
    }).eq('id', id);
  }

  @override
  Future<void> cancelar(String id) async {
    await _db
        .from('agendamentos')
        .update({'status': StatusAgendamento.cancelado.name}).eq('id', id);
  }

  @override
  Future<void> confirmarPresenca(String id) async {
    await _db
        .from('agendamentos')
        .update({'status': StatusAgendamento.confirmado.name}).eq('id', id);
  }
}

class SupabaseChatRepository implements ChatRepository {
  @override
  Stream<Mensagem> novasMensagens(String alunoId) {
    final controller = StreamController<Mensagem>();
    RealtimeChannel? canal;

    Future<void> assinar() async {
      final id = await _resolveAlunoId(alunoId);
      final souAluno = await _souAluno();
      final eu = _db.auth.currentUser!.id;
      canal = _db.channel('mensagens-$id')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensagens',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'aluno_id',
            value: id,
          ),
          callback: (payload) {
            final l = payload.newRecord;
            if (controller.isClosed) return;
            controller.add(_mapear(
              l,
              autorEhAluno: souAluno
                  ? l['autor_perfil_id'] == eu
                  : l['autor_perfil_id'] != eu,
            ));
          },
        )
        ..subscribe();
    }

    controller
      ..onListen = assinar
      ..onCancel = () {
        if (canal != null) _db.removeChannel(canal!);
      };
    return controller.stream;
  }

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
          medidas: _mapaNum(l['medidas']),
          observacoes: (l['observacoes'] as String?) ?? '',
          pro: AvaliacaoPro(
            protocolo: (l['protocolo'] as String?) ?? '',
            dobras: _mapaNum(l['dobras']),
            bioimpedancia: _mapaNum(l['bioimpedancia']),
            testes: _mapaNum(l['testes']),
          ),
        ),
    ];
  }

  Map<String, double> _mapaNum(Object? json) => {
        for (final MapEntry(:key, :value)
            in ((json as Map?) ?? const {}).entries)
          key as String: (value as num).toDouble(),
      };

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

  Future<String> _empresa() async {
    final l = await _db
        .from('perfis')
        .select('empresa_id')
        .eq('id', _db.auth.currentUser!.id)
        .single();
    return l['empresa_id'] as String;
  }

  @override
  Future<void> salvarAvaliacao(String alunoId, AvaliacaoFisica a) async {
    final id = await _resolveAlunoId(alunoId);
    final empresa = await _empresa();
    await _db.from('avaliacoes_fisicas').insert({
      'empresa_id': empresa,
      'aluno_id': id,
      'data': a.data.toIso8601String().substring(0, 10),
      'peso_kg': a.pesoKg,
      'gordura_pct': a.gorduraPct,
      'massa_magra_kg': a.massaMagraKg,
      'medidas': a.medidas,
      'observacoes': a.observacoes,
      'protocolo': a.pro.protocolo,
      'dobras': a.pro.dobras,
      'bioimpedancia': a.pro.bioimpedancia,
      'testes': a.pro.testes,
    });
    await _db.from('registros_peso').insert({
      'empresa_id': empresa,
      'aluno_id': id,
      'data': a.data.toIso8601String().substring(0, 10),
      'peso_kg': a.pesoKg,
    });
  }

  @override
  Future<void> registrarPeso(String alunoId, double pesoKg) async {
    await _db.from('registros_peso').insert({
      'empresa_id': await _empresa(),
      'aluno_id': await _resolveAlunoId(alunoId),
      'peso_kg': pesoKg,
    });
  }

  @override
  Future<void> salvarAnamnese(Anamnese a) async {
    await _db.from('anamneses').insert({
      'empresa_id': await _empresa(),
      'aluno_id': a.alunoId,
      'data': a.data.toIso8601String().substring(0, 10),
      'parq': a.parq,
      'lesoes': a.lesoes,
      'cirurgias': a.cirurgias,
      'medicamentos': a.medicamentos,
      'horas_sono': a.horasSono,
      'habitos': a.habitos,
    });
  }

  @override
  Future<Anamnese?> ultimaAnamnese(String alunoId) async {
    final linhas = await _db
        .from('anamneses')
        .select()
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .order('data', ascending: false)
        .limit(1);
    if (linhas.isEmpty) return null;
    final l = linhas.first;
    return Anamnese(
      alunoId: l['aluno_id'] as String,
      data: DateTime.parse(l['data'] as String),
      parq: [for (final r in l['parq'] as List) r as bool],
      lesoes: l['lesoes'] as String,
      cirurgias: l['cirurgias'] as String,
      medicamentos: l['medicamentos'] as String,
      horasSono: (l['horas_sono'] as num).toInt(),
      habitos: l['habitos'] as String,
    );
  }

  @override
  Future<void> salvarFotoPostura({
    required String alunoId,
    required AnguloFoto angulo,
    required List<int> bytes,
  }) async {
    final empresa = await _empresa();
    final caminho =
        '$empresa/$alunoId/${DateTime.now().millisecondsSinceEpoch}-${angulo.name}.jpg';
    await _db.storage.from('fotos-avaliacao').uploadBinary(
        caminho, Uint8List.fromList(bytes),
        fileOptions: const FileOptions(contentType: 'image/jpeg'));
    final url = await _db.storage
        .from('fotos-avaliacao')
        .createSignedUrl(caminho, 60 * 60 * 24 * 365);
    await _db.from('fotos_postura').insert({
      'empresa_id': empresa,
      'aluno_id': alunoId,
      'angulo': angulo.name,
      'url': url,
    });
  }

  @override
  Future<List<FotoAluno>> fotosPostura(String alunoId) async {
    final linhas = await _db
        .from('fotos_postura')
        .select()
        .eq('aluno_id', await _resolveAlunoId(alunoId))
        .order('data', ascending: false);
    return [
      for (final l in linhas)
        FotoAluno(
          id: l['id'] as String,
          alunoId: l['aluno_id'] as String,
          data: DateTime.parse(l['data'] as String),
          angulo: AnguloFoto.values.byName(l['angulo'] as String),
          url: l['url'] as String,
        ),
    ];
  }
}
