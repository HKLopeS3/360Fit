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
  Future<Aluno> criar(Aluno aluno);
  Future<void> atualizar(Aluno aluno);
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

  /// Registra a conclusão de um treino executado pelo aluno.
  Future<void> concluirTreino(TreinoConcluido conclusao);

  /// Histórico de conclusões, mais recentes primeiro.
  Future<List<TreinoConcluido>> historicoConcluidos(String alunoId);
}

abstract interface class AgendaRepository {
  /// Agendamentos futuros; filtra por aluno quando [alunoId] é informado.
  Future<List<Agendamento>> proximos({String? alunoId});

  Future<void> criar(Agendamento agendamento);

  /// Remarca o horário (volta o status para pendente).
  Future<void> remarcar(String id, DateTime novaDataHora);

  Future<void> cancelar(String id);

  /// Aluno confirma presença.
  Future<void> confirmarPresenca(String id);
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

  /// Salva uma nova avaliação física (também registra o peso da data).
  Future<void> salvarAvaliacao(String alunoId, AvaliacaoFisica avaliacao);

  /// Registro rápido de peso pelo aluno ou profissional.
  Future<void> registrarPeso(String alunoId, double pesoKg);
}
