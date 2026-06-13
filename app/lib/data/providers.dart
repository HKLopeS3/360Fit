import 'dart:async';

import 'package:flutter/services.dart';
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
final financeiroRepositoryProvider = Provider<FinanceiroRepository>((ref) =>
    _supabase ? SupabaseFinanceiroRepository() : MockFinanceiroRepository());
final feedRepositoryProvider = Provider<FeedRepository>(
    (ref) => _supabase ? SupabaseFeedRepository() : MockFeedRepository());

final feedProvider = FutureProvider<List<Postagem>>(
  (ref) => ref.watch(feedRepositoryProvider).feed(),
);

final postagensPendentesProvider = FutureProvider<List<Postagem>>(
  (ref) => ref.watch(feedRepositoryProvider).pendentes(),
);

// -------------------------------------------------------------------- sessão

class SessaoNotifier extends Notifier<Usuario?> {
  SessaoNotifier([this._inicial]);

  /// Sessão restaurada antes do runApp (boot com Supabase).
  final Usuario? _inicial;

  @override
  Usuario? build() => _inicial;

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

  Future<void> atualizarPerfil({
    String? nome,
    String? cref,
    String? cpf,
    List<int>? fotoBytes,
  }) async {
    state = await ref.read(authRepositoryProvider).atualizarPerfil(
          nome: nome,
          cref: cref,
          cpf: cpf,
          fotoBytes: fotoBytes,
        );
  }
}

final sessaoProvider =
    NotifierProvider<SessaoNotifier, Usuario?>(SessaoNotifier.new);

final configuracaoEmpresaProvider = FutureProvider<ConfiguracaoEmpresa>(
  (ref) => ref.watch(financeiroRepositoryProvider).configuracaoEmpresa(),
);

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

/// Alerta acionável exibido no dashboard do personal.
class AlertaPersonal {
  const AlertaPersonal({
    required this.tipo,
    required this.titulo,
    required this.detalhe,
    this.alunoId,
  });

  /// 'dor' | 'sumido' | 'programa' | 'aniversario'
  final String tipo;
  final String titulo;
  final String detalhe;
  final String? alunoId;
}

/// Treinos concluídos pelos alunos do profissional logado, por dia da
/// semana (índice 0 = segunda), nos últimos 7 dias.
final treinosSemanaProvider = FutureProvider<List<int>>((ref) async {
  final concluidos =
      await ref.watch(treinoRepositoryProvider).historicoEmpresa(7);
  final contagem = List.filled(7, 0);
  for (final c in concluidos) {
    contagem[c.data.weekday - 1]++;
  }
  return contagem;
});

final alertasProvider = FutureProvider<List<AlertaPersonal>>((ref) async {
  final alunos = await ref.watch(alunosProvider.future);
  final repo = ref.watch(treinoRepositoryProvider);
  final concluidos = await repo.historicoEmpresa(30);
  final programas = await repo.programasEmpresa();
  final inadimplentes =
      await ref.watch(financeiroRepositoryProvider).inadimplentes();
  final agora = DateTime.now();

  String nome(String alunoId) => alunos
      .where((a) => a.id == alunoId)
      .map((a) => a.nome)
      .firstOrNull ??
      'Aluno';

  final alertas = <AlertaPersonal>[
    // 🔴 dor articular nos últimos 7 dias
    for (final c in concluidos)
      if (c.dorArticular && agora.difference(c.data).inDays <= 7)
        AlertaPersonal(
          tipo: 'dor',
          titulo: '${nome(c.alunoId)} relatou dor articular',
          detalhe:
              '${c.dorRelato.isEmpty ? 'Sem detalhes' : c.dorRelato} · ${c.nomeTreino}',
          alunoId: c.alunoId,
        ),
    // 🟠 sem treinar há 5+ dias
    for (final a in alunos)
      if (() {
        final ultimo = concluidos
            .where((c) => c.alunoId == a.id)
            .map((c) => c.data)
            .fold<DateTime?>(null,
                (max, d) => max == null || d.isAfter(max) ? d : max);
        return ultimo == null || agora.difference(ultimo).inDays >= 5;
      }())
        AlertaPersonal(
          tipo: 'sumido',
          titulo: '${a.nome} sem treinar há 5+ dias',
          detalhe: 'Que tal mandar uma mensagem?',
          alunoId: a.id,
        ),
    // 🟡 programas vencendo em até 7 dias
    for (final p in programas)
      if (p.vigente && p.fim.difference(agora).inDays <= 7)
        AlertaPersonal(
          tipo: 'programa',
          titulo: 'Programa de ${nome(p.alunoId)} vence em breve',
          detalhe:
              '${p.nome} termina em ${p.fim.difference(agora).inDays} dia(s) — planeje o próximo ciclo',
          alunoId: p.alunoId,
        ),
    // 💰 mensalidades atrasadas
    for (final m in inadimplentes)
      AlertaPersonal(
        tipo: 'financeiro',
        titulo: '${nome(m.alunoId)} com mensalidade atrasada',
        detalhe:
            'Competência ${m.competencia.month.toString().padLeft(2, '0')}/${m.competencia.year} · R\$ ${m.valor.toStringAsFixed(2)}',
        alunoId: m.alunoId,
      ),
    // 🎂 aniversários nos próximos 7 dias
    for (final a in alunos)
      if (a.diasParaAniversario != null && a.diasParaAniversario! <= 7)
        AlertaPersonal(
          tipo: 'aniversario',
          titulo: a.diasParaAniversario == 0
              ? 'Hoje é aniversário de ${a.nome}! 🎉'
              : 'Aniversário de ${a.nome} em ${a.diasParaAniversario} dia(s)',
          detalhe: 'Uma mensagem faz diferença na retenção.',
          alunoId: a.id,
        ),
  ];
  return alertas;
});

final programasProvider = FutureProvider.family<List<Programa>, String>(
  (ref, alunoId) => ref.watch(treinoRepositoryProvider).programas(alunoId),
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

final fotosEvolucaoProvider = FutureProvider.family<List<FotoAluno>, String>(
  (ref, alunoId) =>
      ref.watch(evolucaoRepositoryProvider).fotosEvolucao(alunoId),
);

final mensalidadesProvider = FutureProvider.family<List<Mensalidade>, String>(
  (ref, alunoId) => ref.watch(financeiroRepositoryProvider).doAluno(alunoId),
);

/// Contador de copos de água do dia (aluno logado).
class AguaNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() =>
      ref.watch(evolucaoRepositoryProvider).coposHoje(alunoLogadoId);

  Future<void> ajustar(int delta) async {
    final novo = await ref
        .read(evolucaoRepositoryProvider)
        .registrarCopo(alunoLogadoId, delta);
    state = AsyncData(novo);
  }
}

final aguaProvider =
    AsyncNotifierProvider<AguaNotifier, int>(AguaNotifier.new);

/// Medalhas derivadas do histórico do aluno logado.
final medalhasProvider = FutureProvider<List<Medalha>>((ref) async {
  final historico = await ref
      .watch(treinoRepositoryProvider)
      .historicoConcluidos(alunoLogadoId);
  final agora = DateTime.now();

  // semanas consecutivas com ao menos 1 treino (a partir da semana atual)
  var streak = 0;
  for (var s = 0; s < 52; s++) {
    final inicio = agora.subtract(Duration(days: 7 * (s + 1)));
    final fim = agora.subtract(Duration(days: 7 * s));
    final treinou = historico
        .any((c) => c.data.isAfter(inicio) && !c.data.isAfter(fim));
    if (treinou) {
      streak++;
    } else {
      break;
    }
  }

  final mesAtual = historico.where(
      (c) => c.data.year == agora.year && c.data.month == agora.month);
  final toneladasMes =
      mesAtual.fold<double>(0, (t, c) => t + c.volumeTotalKg) / 1000;
  final total = historico.length;

  return [
    Medalha(
      id: 'streak4',
      titulo: '4 semanas sem faltar',
      descricao: 'Treine ao menos 1x por semana, 4 semanas seguidas',
      emoji: '🔥',
      conquistada: streak >= 4,
    ),
    Medalha(
      id: 't10',
      titulo: '10 treinos concluídos',
      descricao: 'Complete 10 treinos no app',
      emoji: '🥉',
      conquistada: total >= 10,
    ),
    Medalha(
      id: 't50',
      titulo: '50 treinos concluídos',
      descricao: 'Complete 50 treinos no app',
      emoji: '🥈',
      conquistada: total >= 50,
    ),
    Medalha(
      id: 'ton10',
      titulo: '10 toneladas no mês',
      descricao:
          'Levante 10.000 kg somados no mês (você está em ${toneladasMes.toStringAsFixed(1)} t)',
      emoji: '🏋️',
      conquistada: toneladasMes >= 10,
    ),
    Medalha(
      id: 'madrugador',
      titulo: 'Consistência total',
      descricao: 'Treine na sua frequência-alvo por um mês inteiro',
      emoji: '🏆',
      conquistada: mesAtual.length >= 12,
    ),
  ];
});

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
        // Avisa que o descanso acabou (vibração + som do sistema).
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
      } else {
        state = state?.copyWith(descansoRestante: restante);
      }
    });
  }

  /// Substitui o exercício corrente (aparelho ocupado) mantendo a prescrição.
  void trocarExercicio(String novoExercicioId) {
    final s = state;
    if (s == null) return;
    final itens = List.of(s.treino.itens);
    itens[s.itemAtual] =
        itens[s.itemAtual].copyWith(exercicioId: novoExercicioId);
    state = EstadoExecucao(
      treino: s.treino.copyWith(itens: itens),
      inicio: s.inicio,
      itemAtual: s.itemAtual,
      serieAtual: s.serieAtual,
      realizadas: s.realizadas,
      descansoRestante: s.descansoRestante,
    );
  }

  /// Encerra a sessão e persiste a conclusão (com feedback do aluno).
  Future<TreinoConcluido?> finalizar({
    int pse = 0,
    bool dorArticular = false,
    String dorRelato = '',
  }) async {
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
      pse: pse,
      dorArticular: dorArticular,
      dorRelato: dorRelato,
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
