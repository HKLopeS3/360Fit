import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/models/models.dart';
import 'repositories/mock_repositories.dart';
import 'repositories/repositories.dart';
import 'repositories/supabase_repositories.dart';

// ------------------------------------------------------------- repositórios
// Com credenciais Supabase (--dart-define) usa o backend real; sem elas,
// os mocks — a UI não percebe a diferença.

final _supabase = AppConfig.usarSupabase;

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => _supabase ? SupabaseAuthRepository() : MockAuthRepository());
final alunoRepositoryProvider = Provider<AlunoRepository>(
    (ref) => _supabase ? SupabaseAlunoRepository() : MockAlunoRepository());
final exercicioRepositoryProvider = Provider<ExercicioRepository>((ref) =>
    _supabase ? SupabaseExercicioRepository() : MockExercicioRepository());
final treinoRepositoryProvider = Provider<TreinoRepository>(
    (ref) => _supabase ? SupabaseTreinoRepository() : MockTreinoRepository());
final agendaRepositoryProvider = Provider<AgendaRepository>(
    (ref) => _supabase ? SupabaseAgendaRepository() : MockAgendaRepository());
final chatRepositoryProvider = Provider<ChatRepository>(
    (ref) => _supabase ? SupabaseChatRepository() : MockChatRepository());
final evolucaoRepositoryProvider = Provider<EvolucaoRepository>((ref) =>
    _supabase ? SupabaseEvolucaoRepository() : MockEvolucaoRepository());

// -------------------------------------------------------------------- sessão

class SessaoNotifier extends Notifier<Usuario?> {
  @override
  Usuario? build() => null;

  Future<Usuario> entrar(PerfilUsuario perfil) async {
    final usuario = await ref.read(authRepositoryProvider).login(perfil);
    state = usuario;
    return usuario;
  }

  void sair() => state = null;
}

final sessaoProvider =
    NotifierProvider<SessaoNotifier, Usuario?>(SessaoNotifier.new);

/// Id do aluno vinculado ao usuário logado como aluno (mock: Carlos = a1).
const alunoLogadoId = 'a1';

// --------------------------------------------------------------------- dados

final alunosProvider = FutureProvider<List<Aluno>>(
  (ref) => ref.watch(alunoRepositoryProvider).listar(),
);

final alunoProvider = FutureProvider.family<Aluno, String>(
  (ref, id) => ref.watch(alunoRepositoryProvider).buscar(id),
);

final bibliotecaExerciciosProvider = FutureProvider<List<Exercicio>>(
  (ref) => ref.watch(exercicioRepositoryProvider).biblioteca(),
);

final treinosDoAlunoProvider = FutureProvider.family<List<Treino>, String>(
  (ref, alunoId) => ref.watch(treinoRepositoryProvider).doAluno(alunoId),
);

final treinoDoDiaProvider = FutureProvider<Treino?>(
  (ref) => ref.watch(treinoRepositoryProvider).treinoDoDia(alunoLogadoId),
);

final agendaProvider = FutureProvider.family<List<Agendamento>, String?>(
  (ref, alunoId) =>
      ref.watch(agendaRepositoryProvider).proximos(alunoId: alunoId),
);

final pesosProvider = FutureProvider.family<List<RegistroPeso>, String>(
  (ref, alunoId) => ref.watch(evolucaoRepositoryProvider).pesos(alunoId),
);

final avaliacoesProvider = FutureProvider.family<List<AvaliacaoFisica>, String>(
  (ref, alunoId) => ref.watch(evolucaoRepositoryProvider).avaliacoes(alunoId),
);

final cargasProvider =
    FutureProvider.family<List<RegistroCarga>, ({String alunoId, String exercicioId})>(
  (ref, args) => ref
      .watch(evolucaoRepositoryProvider)
      .cargas(args.alunoId, args.exercicioId),
);

// ----------------------------------------------------------- execução treino

/// Itens do treino do dia já concluídos (índices), por treino.
class ExecucaoTreinoNotifier extends Notifier<Map<String, Set<int>>> {
  @override
  Map<String, Set<int>> build() => {};

  void alternar(String treinoId, int indiceItem) {
    final atual = Set<int>.of(state[treinoId] ?? const {});
    if (!atual.remove(indiceItem)) atual.add(indiceItem);
    state = {...state, treinoId: atual};
  }

  Set<int> concluidos(String treinoId) => state[treinoId] ?? const {};
}

final execucaoTreinoProvider =
    NotifierProvider<ExecucaoTreinoNotifier, Map<String, Set<int>>>(
        ExecucaoTreinoNotifier.new);

// ----------------------------------------------------------------------- chat

class ConversaNotifier extends FamilyAsyncNotifier<List<Mensagem>, String> {
  @override
  Future<List<Mensagem>> build(String alunoId) =>
      ref.watch(chatRepositoryProvider).conversa(alunoId);

  Future<void> enviar(String texto, {required bool doAluno}) async {
    final msg = await ref.read(chatRepositoryProvider).enviar(
          alunoId: arg,
          doAluno: doAluno,
          texto: texto,
        );
    state = AsyncData([...state.valueOrNull ?? const [], msg]);
  }
}

final conversaProvider = AsyncNotifierProvider.family<ConversaNotifier,
    List<Mensagem>, String>(ConversaNotifier.new);
