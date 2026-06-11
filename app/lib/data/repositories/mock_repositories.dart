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
}

class MockAlunoRepository implements AlunoRepository {
  final _db = MockDatabase.instance;

  @override
  Future<List<Aluno>> listar() => _simulaRede(List.of(_db.alunos));

  @override
  Future<Aluno> buscar(String id) =>
      _simulaRede(_db.alunos.firstWhere((a) => a.id == id));
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
}

class MockChatRepository implements ChatRepository {
  final _db = MockDatabase.instance;

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
}
