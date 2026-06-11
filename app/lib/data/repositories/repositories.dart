import '../../core/models/models.dart';

/// Contratos de acesso a dados.
///
/// A UI depende apenas destas interfaces; na fase atual elas são servidas
/// por implementações mock (`mock_repositories.dart`) e, no futuro, por um
/// client HTTP da API NestJS.
abstract interface class AuthRepository {
  Future<Usuario> login(PerfilUsuario perfil);
}

abstract interface class AlunoRepository {
  Future<List<Aluno>> listar();
  Future<Aluno> buscar(String id);
}

abstract interface class ExercicioRepository {
  Future<List<Exercicio>> biblioteca();
  Exercicio porId(String id);
}

abstract interface class TreinoRepository {
  Future<List<Treino>> doAluno(String alunoId);

  /// Treino previsto para hoje conforme os dias da semana, ou null.
  Future<Treino?> treinoDoDia(String alunoId);

  Future<void> salvar(Treino treino);
}

abstract interface class AgendaRepository {
  /// Agendamentos futuros; filtra por aluno quando [alunoId] é informado.
  Future<List<Agendamento>> proximos({String? alunoId});
}

abstract interface class ChatRepository {
  Future<List<Mensagem>> conversa(String alunoId);
  Future<Mensagem> enviar({
    required String alunoId,
    required bool doAluno,
    required String texto,
  });
}

abstract interface class EvolucaoRepository {
  Future<List<RegistroPeso>> pesos(String alunoId);
  Future<List<AvaliacaoFisica>> avaliacoes(String alunoId);
  Future<List<RegistroCarga>> cargas(String alunoId, String exercicioId);
}
