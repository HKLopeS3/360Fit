import 'dart:async';

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
  SessaoNotifier([this._inicial]);

  /// Sessão restaurada antes do runApp (boot com Supabase).
  final Usuario? _inicial;

  @override
  Usuario? build() => _inicial;

  Future<Usuario> entrar(PerfilUsuario perfil) async {
    final usuario = await ref.read(authRepositoryProvider).login(perfil);
    state = usuario;
    return usuario;
  }

  Future<Usuario> entrarComEmailSenha(String email, String senha) async {
    final usuario = await ref
        .read(authRepositoryProvider)
        .entrarComEmailSenha(email, senha);
    state = usuario;
    return usuario;
  }

  Future<void> sair() async {
    await ref.read(authRepositoryProvider).sair();
    state = null;
  }
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
  (ref, alunoId) async {
    // Garante a biblioteca carregada para o lookup síncrono porId
    // (nomes dos exercícios) usado pelas telas de treino.
    await ref.watch(bibliotecaExerciciosProvider.future);
    return ref.watch(treinoRepositoryProvider).doAluno(alunoId);
  },
);

final treinoDoDiaProvider = FutureProvider<Treino?>(
  (ref) async {
    await ref.watch(bibliotecaExerciciosProvider.future);
    return ref.watch(treinoRepositoryProvider).treinoDoDia(alunoLogadoId);
  },
);

final historicoConcluidosProvider =
    FutureProvider.family<List<TreinoConcluido>, String>(
  (ref, alunoId) =>
      ref.watch(treinoRepositoryProvider).historicoConcluidos(alunoId),
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

final anamneseProvider = FutureProvider.family<Anamnese?, String>(
  (ref, alunoId) =>
      ref.watch(evolucaoRepositoryProvider).ultimaAnamnese(alunoId),
);

final fotosPosturaProvider = FutureProvider.family<List<FotoAluno>, String>(
  (ref, alunoId) =>
      ref.watch(evolucaoRepositoryProvider).fotosPostura(alunoId),
);

final cargasProvider =
    FutureProvider.family<List<RegistroCarga>, ({String alunoId, String exercicioId})>(
  (ref, args) => ref
      .watch(evolucaoRepositoryProvider)
      .cargas(args.alunoId, args.exercicioId),
);

// ------------------------------------------------- sessão de execução ao vivo

/// Estado de um treino em andamento (tela de execução).
class EstadoExecucao {
  const EstadoExecucao({
    required this.treino,
    required this.inicio,
    this.itemAtual = 0,
    this.serieAtual = 1,
    this.realizadas = const [],
    this.descansoRestante = 0,
  });

  final Treino treino;
  final DateTime inicio;

  /// Índice do exercício corrente em `treino.itens`.
  final int itemAtual;

  /// Série corrente (1-based) do exercício corrente.
  final int serieAtual;
  final List<SerieRealizada> realizadas;

  /// Segundos restantes de descanso; 0 = nenhum descanso ativo.
  final int descansoRestante;

  ItemTreino get item => treino.itens[itemAtual];
  bool get ultimaSerieDoTreino =>
      itemAtual == treino.itens.length - 1 && serieAtual == item.series;
  int get totalSeries =>
      treino.itens.fold(0, (total, i) => total + i.series);

  EstadoExecucao copyWith({
    int? itemAtual,
    int? serieAtual,
    List<SerieRealizada>? realizadas,
    int? descansoRestante,
  }) {
    return EstadoExecucao(
      treino: treino,
      inicio: inicio,
      itemAtual: itemAtual ?? this.itemAtual,
      serieAtual: serieAtual ?? this.serieAtual,
      realizadas: realizadas ?? this.realizadas,
      descansoRestante: descansoRestante ?? this.descansoRestante,
    );
  }
}

class ExecucaoSessaoNotifier extends Notifier<EstadoExecucao?> {
  Timer? _cronometro;

  @override
  EstadoExecucao? build() {
    ref.onDispose(() => _cronometro?.cancel());
    return null;
  }

  void iniciar(Treino treino) {
    _cronometro?.cancel();
    state = EstadoExecucao(treino: treino, inicio: DateTime.now());
  }

  /// Conclui a série corrente e avança (com descanso quando há próxima).
  void concluirSerie({required double cargaKg, required int repeticoes}) {
    final s = state;
    if (s == null) return;
    final realizadas = [
      ...s.realizadas,
      SerieRealizada(
        indiceItem: s.itemAtual,
        serie: s.serieAtual,
        cargaKg: cargaKg,
        repeticoes: repeticoes,
      ),
    ];
    if (s.ultimaSerieDoTreino) {
      state = s.copyWith(realizadas: realizadas, descansoRestante: 0);
      return;
    }
    final proximaEhMesmoExercicio = s.serieAtual < s.item.series;
    state = s.copyWith(
      realizadas: realizadas,
      itemAtual: proximaEhMesmoExercicio ? s.itemAtual : s.itemAtual + 1,
      serieAtual: proximaEhMesmoExercicio ? s.serieAtual + 1 : 1,
      descansoRestante: s.item.descansoSeg,
    );
    _iniciarDescanso();
  }

  void pularDescanso() {
    _cronometro?.cancel();
    state = state?.copyWith(descansoRestante: 0);
  }

  void _iniciarDescanso() {
    _cronometro?.cancel();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
      final restante = (state?.descansoRestante ?? 0) - 1;
      if (restante <= 0) {
        timer.cancel();
        state = state?.copyWith(descansoRestante: 0);
      } else {
        state = state?.copyWith(descansoRestante: restante);
      }
    });
  }

  /// Encerra a sessão e persiste a conclusão.
  Future<TreinoConcluido?> finalizar() async {
    final s = state;
    if (s == null) return null;
    _cronometro?.cancel();
    final conclusao = TreinoConcluido(
      id: 'tc-${DateTime.now().millisecondsSinceEpoch}',
      alunoId: s.treino.alunoId,
      treinoId: s.treino.id,
      nomeTreino: '${s.treino.nome} — ${s.treino.foco}',
      data: DateTime.now(),
      duracaoMin:
          DateTime.now().difference(s.inicio).inMinutes.clamp(1, 600),
      series: s.realizadas,
    );
    await ref.read(treinoRepositoryProvider).concluirTreino(conclusao);
    ref.invalidate(historicoConcluidosProvider(s.treino.alunoId));
    state = null;
    return conclusao;
  }

  void descartar() {
    _cronometro?.cancel();
    state = null;
  }
}

final execucaoSessaoProvider =
    NotifierProvider<ExecucaoSessaoNotifier, EstadoExecucao?>(
        ExecucaoSessaoNotifier.new);

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
  Future<List<Mensagem>> build(String alunoId) {
    final repo = ref.watch(chatRepositoryProvider);
    // Tempo real: anexa mensagens novas (descartando duplicadas, já que as
    // enviadas localmente entram pelo `enviar`).
    final assinatura = repo.novasMensagens(alunoId).listen((msg) {
      final atual = state.valueOrNull ?? const <Mensagem>[];
      if (atual.any((m) => m.id == msg.id)) return;
      state = AsyncData([...atual, msg]);
    });
    ref.onDispose(assinatura.cancel);
    return repo.conversa(alunoId);
  }

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
