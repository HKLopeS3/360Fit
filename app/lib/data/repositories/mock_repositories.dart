import '../../core/mock/mock_database.dart';
import '../../core/models/models.dart';
import 'repositories.dart';

/// Latência artificial para a UI exercitar estados de loading.
Future<T> _simulaRede<T>(T valor) =>
    Future.delayed(const Duration(milliseconds: 350), () => valor);

class MockAuthRepository implements AuthRepository {
  final _db = MockDatabase.instance;

  @override
  Future<Usuario> entrarComEmailSenha(String email, String senha) {
    final normalizado = email.trim().toLowerCase();
    if (normalizado == _db.usuarioPersonal.email) {
      return _simulaRede(_db.usuarioPersonal);
    }
    return _simulaRede(_db.usuarioAluno);
  }

  @override
  Future<Usuario?> usuarioAtual() => _simulaRede(null);

  @override
  Future<void> sair() => _simulaRede(null);

  @override
  Future<void> recuperarSenha(String email) => _simulaRede(null);

  @override
  Future<bool> validarCodigoConvite(String codigo) => _simulaRede(
        _db.alunos.any((a) => a.codigoConvite == codigo),
      );

  @override
  Future<Usuario?> registrar(String nome, String email, String senha,
      {String? codigoConvite}) {
    if (codigoConvite != null) {
      final i =
          _db.alunos.indexWhere((a) => a.codigoConvite == codigoConvite);
      if (i < 0) throw Exception('Código de convite inválido');
      _db.alunos[i] = Aluno(
        id: _db.alunos[i].id,
        nome: nome.isEmpty ? _db.alunos[i].nome : nome,
        idade: _db.alunos[i].idade,
        objetivo: _db.alunos[i].objetivo,
        inicio: _db.alunos[i].inicio,
        frequenciaSemanal: _db.alunos[i].frequenciaSemanal,
        pesoAtualKg: _db.alunos[i].pesoAtualKg,
        riscoEvasao: _db.alunos[i].riscoEvasao,
        sexo: _db.alunos[i].sexo,
        nascimento: _db.alunos[i].nascimento,
        codigoConvite: null,
      );
      return _simulaRede(Usuario(
        id: 'u-aluno-novo',
        nome: nome,
        email: email,
        perfil: PerfilUsuario.aluno,
      ));
    }
    return _simulaRede(Usuario(
      id: 'u-personal-novo',
      nome: nome,
      email: email,
      perfil: PerfilUsuario.personal,
    ));
  }

  @override
  Future<Usuario> atualizarPerfil({
    String? nome,
    String? cref,
    String? cpf,
    List<int>? fotoBytes,
  }) {
    _db.usuarioPersonal = _db.usuarioPersonal.copyWith(
      nome: nome,
      cref: cref,
      cpf: cpf,
      fotoUrl: fotoBytes != null ? 'mock://avatar' : null,
    );
    return _simulaRede(_db.usuarioPersonal);
  }
}

class MockAlunoRepository implements AlunoRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Aluno>> listar() => _simulaRede(List.of(_db.alunos));

  @override
  Future<Aluno> buscar(String id) =>
      _simulaRede(_db.alunos.firstWhere((a) => a.id == id));

  @override
  Future<Aluno> criar(Aluno aluno) {
    final comCodigo = Aluno(
      id: aluno.id,
      nome: aluno.nome,
      idade: aluno.idade,
      objetivo: aluno.objetivo,
      inicio: aluno.inicio,
      frequenciaSemanal: aluno.frequenciaSemanal,
      pesoAtualKg: aluno.pesoAtualKg,
      riscoEvasao: aluno.riscoEvasao,
      sexo: aluno.sexo,
      nascimento: aluno.nascimento,
      codigoConvite: 'DEMO-${aluno.id.toUpperCase()}',
    );
    _db.alunos.add(comCodigo);
    return _simulaRede(comCodigo);
  }

  @override
  Future<void> atualizar(Aluno aluno) {
    final i = _db.alunos.indexWhere((a) => a.id == aluno.id);
    if (i >= 0) _db.alunos[i] = aluno;
    return _simulaRede(null);
  }
}

class MockExercicioRepository implements ExercicioRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Exercicio>> biblioteca() => _simulaRede(List.of(_db.exercicios));

  @override
  Exercicio porId(String id) => _db.exercicioPorId(id);

  @override
  Future<void> definirVideo(String exercicioId, String url) {
    final i = _db.exercicios.indexWhere((e) => e.id == exercicioId);
    if (i >= 0) {
      final e = _db.exercicios[i];
      _db.exercicios[i] = Exercicio(
        id: e.id,
        nome: e.nome,
        grupoMuscular: e.grupoMuscular,
        equipamento: e.equipamento,
        videoUrl: url,
      );
    }
    return _simulaRede(null);
  }
}

class MockTreinoRepository implements TreinoRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Treino>> doAluno(String alunoId) => _simulaRede(
        _db.treinos.where((t) => t.alunoId == alunoId).toList(),
      );

  @override
  Future<Treino?> treinoDoDia(String alunoId) {
    final hoje = DateTime.now().weekday;
    final doDia = _db.treinos
        .where((t) => t.alunoId == alunoId && t.diasSemana.contains(hoje))
        .toList();
    return _simulaRede(doDia.isEmpty ? null : doDia.first);
  }

  @override
  Future<void> salvar(Treino treino) {
    final i = _db.treinos.indexWhere((t) => t.id == treino.id);
    if (i >= 0) {
      _db.treinos[i] = treino;
    } else {
      _db.treinos.add(treino);
    }
    return _simulaRede(null);
  }

  @override
  Future<void> concluirTreino(TreinoConcluido conclusao) {
    _db.treinosConcluidos.add(conclusao);
    return _simulaRede(null);
  }

  @override
  Future<List<TreinoConcluido>> historicoConcluidos(String alunoId) =>
      _simulaRede(
        _db.treinosConcluidos.where((c) => c.alunoId == alunoId).toList()
          ..sort((a, b) => b.data.compareTo(a.data)),
      );

  @override
  Future<List<Programa>> programas(String alunoId) => _simulaRede(
        _db.programas.where((p) => p.alunoId == alunoId).toList()
          ..sort((a, b) => b.inicio.compareTo(a.inicio)),
      );

  @override
  Future<void> salvarPrograma(Programa programa) {
    final i = _db.programas.indexWhere((p) => p.id == programa.id);
    if (i >= 0) {
      _db.programas[i] = programa;
    } else {
      _db.programas.add(programa);
    }
    return _simulaRede(null);
  }

  @override
  Future<List<TreinoConcluido>> historicoEmpresa(int dias) {
    final corte = DateTime.now().subtract(Duration(days: dias));
    return _simulaRede(
      _db.treinosConcluidos.where((c) => c.data.isAfter(corte)).toList(),
    );
  }

  @override
  Future<List<Programa>> programasEmpresa() =>
      _simulaRede(List.of(_db.programas));
}

class MockAgendaRepository implements AgendaRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Agendamento>> proximos({String? alunoId}) {
    final agora = DateTime.now().subtract(const Duration(hours: 12));
    final lista = _db.agendamentos
        .where((a) => a.dataHora.isAfter(agora))
        .where((a) => alunoId == null || a.alunoId == alunoId)
        .toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return _simulaRede(lista);
  }

  @override
  Future<void> criar(Agendamento agendamento) {
    _db.agendamentos.add(agendamento);
    return _simulaRede(null);
  }

  void _trocar(String id, Agendamento Function(Agendamento) transforma) {
    final i = _db.agendamentos.indexWhere((a) => a.id == id);
    if (i >= 0) _db.agendamentos[i] = transforma(_db.agendamentos[i]);
  }

  @override
  Future<void> remarcar(String id, DateTime novaDataHora) {
    _trocar(
        id,
        (a) => a.copyWith(
            dataHora: novaDataHora, status: StatusAgendamento.pendente));
    return _simulaRede(null);
  }

  @override
  Future<void> cancelar(String id) {
    _trocar(id, (a) => a.copyWith(status: StatusAgendamento.cancelado));
    return _simulaRede(null);
  }

  @override
  Future<void> confirmarPresenca(String id) {
    _trocar(id, (a) => a.copyWith(status: StatusAgendamento.confirmado));
    return _simulaRede(null);
  }
}

class MockChatRepository implements ChatRepository {
  final _db = MockDatabase.instance;

  @override
  Stream<Mensagem> novasMensagens(String alunoId) => const Stream.empty();

  @override
  Future<List<Mensagem>> conversa(String alunoId) => _simulaRede(
        _db.mensagens.where((m) => m.alunoId == alunoId).toList()
          ..sort((a, b) => a.dataHora.compareTo(b.dataHora)),
      );

  @override
  Future<Mensagem> enviar({
    required String alunoId,
    required bool doAluno,
    required String texto,
  }) {
    final msg = Mensagem(
      id: 'm${_db.mensagens.length + 1}',
      alunoId: alunoId,
      doAluno: doAluno,
      texto: texto,
      dataHora: DateTime.now(),
    );
    _db.mensagens.add(msg);
    return _simulaRede(msg);
  }
}

class MockEvolucaoRepository implements EvolucaoRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<RegistroPeso>> pesos(String alunoId) =>
      _simulaRede(_db.pesos[alunoId] ?? const []);

  @override
  Future<List<AvaliacaoFisica>> avaliacoes(String alunoId) =>
      _simulaRede(_db.avaliacoes[alunoId] ?? const []);

  @override
  Future<List<RegistroCarga>> cargas(String alunoId, String exercicioId) =>
      _simulaRede(
        _db.cargas.where((c) => c.exercicioId == exercicioId).toList(),
      );

  @override
  Future<void> salvarAvaliacao(String alunoId, AvaliacaoFisica avaliacao) {
    (_db.avaliacoes[alunoId] ??= []).add(avaliacao);
    (_db.pesos[alunoId] ??= [])
        .add(RegistroPeso(data: avaliacao.data, pesoKg: avaliacao.pesoKg));
    return _simulaRede(null);
  }

  @override
  Future<void> registrarPeso(String alunoId, double pesoKg) {
    (_db.pesos[alunoId] ??= [])
        .add(RegistroPeso(data: DateTime.now(), pesoKg: pesoKg));
    return _simulaRede(null);
  }

  @override
  Future<void> salvarAnamnese(Anamnese anamnese) {
    _db.anamneses.add(anamnese);
    return _simulaRede(null);
  }

  @override
  Future<Anamnese?> ultimaAnamnese(String alunoId) {
    final doAluno =
        _db.anamneses.where((a) => a.alunoId == alunoId).toList();
    return _simulaRede(doAluno.isEmpty ? null : doAluno.last);
  }

  @override
  Future<void> salvarFotoPostura({
    required String alunoId,
    required AnguloFoto angulo,
    required List<int> bytes,
  }) {
    _db.fotosPostura.add(FotoAluno(
      id: 'fp${_db.fotosPostura.length + 1}',
      alunoId: alunoId,
      data: DateTime.now(),
      angulo: angulo,
      bytes: bytes,
    ));
    return _simulaRede(null);
  }

  @override
  Future<List<FotoAluno>> fotosPostura(String alunoId) => _simulaRede(
        _db.fotosPostura.where((f) => f.alunoId == alunoId).toList(),
      );

  @override
  Future<void> salvarFotoEvolucao({
    required String alunoId,
    required List<int> bytes,
    String observacao = '',
  }) {
    _db.fotosEvolucao.add(FotoAluno(
      id: 'fe${_db.fotosEvolucao.length + 1}',
      alunoId: alunoId,
      data: DateTime.now(),
      bytes: bytes,
      observacao: observacao,
    ));
    return _simulaRede(null);
  }

  @override
  Future<List<FotoAluno>> fotosEvolucao(String alunoId) => _simulaRede(
        _db.fotosEvolucao.where((f) => f.alunoId == alunoId).toList()
          ..sort((a, b) => a.data.compareTo(b.data)),
      );

  String _chaveAgua(String alunoId) {
    final hoje = DateTime.now();
    return '$alunoId|${hoje.year}-${hoje.month}-${hoje.day}';
  }

  @override
  Future<int> coposHoje(String alunoId) =>
      _simulaRede(_db.agua[_chaveAgua(alunoId)] ?? 0);

  @override
  Future<int> registrarCopo(String alunoId, int delta) {
    final chave = _chaveAgua(alunoId);
    final novo = ((_db.agua[chave] ?? 0) + delta).clamp(0, 30);
    _db.agua[chave] = novo;
    return _simulaRede(novo);
  }
}

class MockFeedRepository implements FeedRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Postagem>> feed() => _simulaRede(
        _db.postagens
            .where((p) =>
                p.status == StatusPostagem.aprovada ||
                p.alunoId == 'a1') // próprias do aluno demo
            .toList()
          ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm)),
      );

  @override
  Future<List<Postagem>> pendentes() => _simulaRede(
        _db.postagens
            .where((p) => p.status == StatusPostagem.pendente)
            .toList()
          ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm)),
      );

  @override
  Future<void> publicar({
    required String alunoId,
    required String texto,
    List<int>? fotoBytes,
  }) {
    final aluno = _db.alunos.firstWhere((a) => a.id == alunoId);
    _db.postagens.add(Postagem(
      id: 'po${_db.postagens.length + 1}',
      alunoId: alunoId,
      autorNome: aluno.nome,
      texto: texto,
      criadaEm: DateTime.now(),
      fotoBytes: fotoBytes,
    ));
    return _simulaRede(null);
  }

  @override
  Future<void> moderar(String postagemId,
      {required bool aprovar, String motivo = ''}) {
    final i = _db.postagens.indexWhere((p) => p.id == postagemId);
    if (i >= 0) {
      _db.postagens[i] = _db.postagens[i].copyWith(
        status:
            aprovar ? StatusPostagem.aprovada : StatusPostagem.rejeitada,
        motivoRejeicao: motivo,
      );
    }
    return _simulaRede(null);
  }

  @override
  Future<void> alternarCurtida(String postagemId) {
    final i = _db.postagens.indexWhere((p) => p.id == postagemId);
    if (i >= 0) {
      final p = _db.postagens[i];
      _db.postagens[i] = p.copyWith(
        euCurti: !p.euCurti,
        curtidas: p.euCurti ? p.curtidas - 1 : p.curtidas + 1,
      );
    }
    return _simulaRede(null);
  }
}

class MockFinanceiroRepository implements FinanceiroRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Mensalidade>> doAluno(String alunoId) => _simulaRede(
        _db.mensalidades.where((m) => m.alunoId == alunoId).toList()
          ..sort((a, b) => b.competencia.compareTo(a.competencia)),
      );

  @override
  Future<void> gerar(String alunoId, DateTime competencia, double valor,
      {DateTime? vencimento}) {
    final comp = DateTime(competencia.year, competencia.month, 1);
    final jaExiste = _db.mensalidades.any((m) =>
        m.alunoId == alunoId &&
        m.competencia.year == comp.year &&
        m.competencia.month == comp.month);
    if (!jaExiste) {
      _db.mensalidades.add(Mensalidade(
        id: 'me${_db.mensalidades.length + 1}',
        alunoId: alunoId,
        competencia: comp,
        valor: valor,
        vencimento: vencimento ?? DateTime(comp.year, comp.month, 10),
      ));
    }
    return _simulaRede(null);
  }

  @override
  Future<void> marcarPaga(String id) {
    final i = _db.mensalidades.indexWhere((m) => m.id == id);
    if (i >= 0) {
      final m = _db.mensalidades[i];
      _db.mensalidades[i] = Mensalidade(
        id: m.id,
        alunoId: m.alunoId,
        competencia: m.competencia,
        valor: m.valor,
        vencimento: m.vencimento,
        pagoEm: DateTime.now(),
      );
    }
    return _simulaRede(null);
  }

  @override
  Future<List<Mensalidade>> inadimplentes() => _simulaRede(
        _db.mensalidades.where((m) => m.atrasada).toList(),
      );

  @override
  Future<ConfiguracaoEmpresa> configuracaoEmpresa() =>
      _simulaRede(_db.configuracaoEmpresa);

  @override
  Future<void> atualizarConfiguracaoEmpresa({
    required double mensalidadeValor,
    required int mensalidadeValidadeDias,
  }) {
    _db.configuracaoEmpresa = _db.configuracaoEmpresa.copyWith(
      mensalidadeValor: mensalidadeValor,
      mensalidadeValidadeDias: mensalidadeValidadeDias,
    );
    return _simulaRede(null);
  }
}
