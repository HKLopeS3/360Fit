import '../../core/mock/mock_database.dart';
import '../../core/models/models.dart';
import 'repositories.dart';

/// Latência artificial para a UI exercitar estados de loading.
Future<T> _simulaRede<T>(T valor) =>
    Future.delayed(const Duration(milliseconds: 350), () => valor);

class MockAuthRepository implements AuthRepository {
  final _db = MockDatabase.instance;

  @override
  Future<Usuario> login(PerfilUsuario perfil) => _simulaRede(
        perfil == PerfilUsuario.aluno ? _db.usuarioAluno : _db.usuarioPersonal,
      );

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
    _db.alunos.add(aluno);
    return _simulaRede(aluno);
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
}
