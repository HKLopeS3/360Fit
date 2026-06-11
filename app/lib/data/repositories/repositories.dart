import '../../core/models/models.dart';

/// Contratos de acesso a dados.
///
/// A UI depende apenas destas interfaces; na fase atual elas são servidas
/// por implementações mock (`mock_repositories.dart`) e, no futuro, por um
/// client HTTP da API NestJS.
abstract interface class AuthRepository {
  /// Login de demonstração por papel (modo mock / botões demo).
  Future<Usuario> login(PerfilUsuario perfil);

  /// Login real com credenciais; o papel vem do perfil persistido.
  Future<Usuario> entrarComEmailSenha(String email, String senha);

  /// Usuário da sessão persistida, ou null se não houver/expirou.
  Future<Usuario?> usuarioAtual();

  Future<void> sair();

  Future<void> recuperarSenha(String email);
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

  /// Define/atualiza o vídeo demonstrativo de um exercício.
  Future<void> definirVideo(String exercicioId, String url);
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

  // ----------------------------------------------------------- periodização

  Future<List<Programa>> programas(String alunoId);
  Future<void> salvarPrograma(Programa programa);

  // ------------------------------------------ visão da carteira (alertas)

  /// Conclusões de todos os alunos visíveis nos últimos [dias].
  Future<List<TreinoConcluido>> historicoEmpresa(int dias);

  /// Programas de todos os alunos visíveis.
  Future<List<Programa>> programasEmpresa();
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

  /// Mensagens chegando em tempo real (Realtime no Supabase;
  /// stream vazio no mock).
  Stream<Mensagem> novasMensagens(String alunoId);
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

  // ------------------------------------------------- avaliação profissional

  Future<void> salvarAnamnese(Anamnese anamnese);
  Future<Anamnese?> ultimaAnamnese(String alunoId);

  /// Salva uma foto postural (Storage no Supabase; memória no mock).
  Future<void> salvarFotoPostura({
    required String alunoId,
    required AnguloFoto angulo,
    required List<int> bytes,
  });

  Future<List<FotoAluno>> fotosPostura(String alunoId);

  // ------------------------------------------------------ retenção (aluno)

  Future<void> salvarFotoEvolucao({
    required String alunoId,
    required List<int> bytes,
    String observacao = '',
  });

  Future<List<FotoAluno>> fotosEvolucao(String alunoId);

  /// Copos de água registrados hoje.
  Future<int> coposHoje(String alunoId);

  /// Ajusta o total de copos de hoje (delta +1/-1).
  Future<int> registrarCopo(String alunoId, int delta);
}

abstract interface class FinanceiroRepository {
  Future<List<Mensalidade>> doAluno(String alunoId);

  /// Gera a mensalidade do mês (competência = 1º dia do mês).
  Future<void> gerar(String alunoId, DateTime competencia, double valor);

  Future<void> marcarPaga(String id);

  /// Mensalidades em atraso de toda a carteira.
  Future<List<Mensalidade>> inadimplentes();
}
