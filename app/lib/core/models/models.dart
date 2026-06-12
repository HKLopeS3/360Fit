/// Modelos de domínio do 360Fit.
///
/// Nesta fase os dados são mockados; os modelos já refletem o contrato
/// esperado da futura API (NestJS), para que a troca de fonte de dados
/// não exija mudanças na UI.
library;

enum PerfilUsuario { aluno, personal }

class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  final String id;
  final String nome;
  final String email;
  final PerfilUsuario perfil;

  String get primeiroNome => nome.split(' ').first;
}

class Aluno {
  const Aluno({
    required this.id,
    required this.nome,
    required this.idade,
    required this.objetivo,
    required this.inicio,
    required this.frequenciaSemanal,
    required this.pesoAtualKg,
    this.riscoEvasao = false,
    this.sexo = 'masculino',
    this.nascimento,
  });

  /// 'masculino' | 'feminino' — usado pelos protocolos de avaliação.
  final String sexo;

  /// Data de nascimento (alertas de aniversário no dashboard).
  final DateTime? nascimento;

  /// Dias até o próximo aniversário (0 = hoje); null sem nascimento.
  int? get diasParaAniversario {
    final n = nascimento;
    if (n == null) return null;
    final hoje = DateTime.now();
    var proximo = DateTime(hoje.year, n.month, n.day);
    if (proximo.isBefore(DateTime(hoje.year, hoje.month, hoje.day))) {
      proximo = DateTime(hoje.year + 1, n.month, n.day);
    }
    return proximo.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  }

  Aluno copyWith({
    String? nome,
    int? idade,
    String? objetivo,
    int? frequenciaSemanal,
    double? pesoAtualKg,
    bool? riscoEvasao,
    String? sexo,
    DateTime? nascimento,
  }) {
    return Aluno(
      id: id,
      nome: nome ?? this.nome,
      idade: idade ?? this.idade,
      objetivo: objetivo ?? this.objetivo,
      inicio: inicio,
      frequenciaSemanal: frequenciaSemanal ?? this.frequenciaSemanal,
      pesoAtualKg: pesoAtualKg ?? this.pesoAtualKg,
      riscoEvasao: riscoEvasao ?? this.riscoEvasao,
      sexo: sexo ?? this.sexo,
      nascimento: nascimento ?? this.nascimento,
    );
  }

  final String id;
  final String nome;
  final int idade;
  final String objetivo;
  final DateTime inicio;

  /// Quantos treinos por semana o aluno tem feito em média.
  final int frequenciaSemanal;
  final double pesoAtualKg;
  final bool riscoEvasao;

  String get primeiroNome => nome.split(' ').first;
  String get iniciais {
    final partes = nome.split(' ');
    if (partes.length == 1) return partes.first.substring(0, 1);
    return '${partes.first[0]}${partes.last[0]}';
  }
}

class Exercicio {
  const Exercicio({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
    required this.equipamento,
    this.videoUrl = '',
  });

  final String id;
  final String nome;
  final String grupoMuscular;
  final String equipamento;

  /// URL de vídeo demonstrativo (YouTube ou Storage).
  final String videoUrl;
}

/// Métodos de intensificação aplicáveis a um item de treino.
enum MetodoTreino { normal, biSet, dropSet, cluster, restPause }

extension MetodoTreinoX on MetodoTreino {
  String get rotulo => switch (this) {
        MetodoTreino.normal => 'Normal',
        MetodoTreino.biSet => 'Bi-set',
        MetodoTreino.dropSet => 'Drop-set',
        MetodoTreino.cluster => 'Cluster set',
        MetodoTreino.restPause => 'Rest-pause',
      };

  String get bd => switch (this) {
        MetodoTreino.normal => 'normal',
        MetodoTreino.biSet => 'bi_set',
        MetodoTreino.dropSet => 'drop_set',
        MetodoTreino.cluster => 'cluster',
        MetodoTreino.restPause => 'rest_pause',
      };

  static MetodoTreino doBd(String? valor) => MetodoTreino.values.firstWhere(
        (m) => m.bd == valor,
        orElse: () => MetodoTreino.normal,
      );
}

/// Programa de treino periodizado (macro/meso/microciclo com vigência).
class Programa {
  const Programa({
    required this.id,
    required this.alunoId,
    required this.nome,
    required this.objetivo,
    required this.inicio,
    required this.fim,
    this.macrociclo = '',
    this.mesociclo = '',
    this.microciclo = '',
    this.observacoes = '',
  });

  final String id;
  final String alunoId;
  final String nome;
  final String objetivo;
  final DateTime inicio;
  final DateTime fim;
  final String macrociclo;
  final String mesociclo;
  final String microciclo;
  final String observacoes;

  int get semanasTotais =>
      (fim.difference(inicio).inDays / 7).ceil().clamp(1, 520);

  int get semanaAtual {
    final dias = DateTime.now().difference(inicio).inDays;
    return (dias / 7).floor().clamp(0, semanasTotais - 1) + 1;
  }

  bool get vigente =>
      !DateTime.now().isBefore(inicio) &&
      !DateTime.now().isAfter(fim.add(const Duration(days: 1)));
}

class ItemTreino {
  const ItemTreino({
    required this.exercicioId,
    required this.series,
    required this.repeticoes,
    required this.cargaKg,
    this.descansoSeg = 60,
    this.cadencia = '',
    this.metodo = MetodoTreino.normal,
    this.agrupamento = 0,
  });

  final String exercicioId;
  final int series;
  final String repeticoes; // ex.: "8-12", "15"
  final double cargaKg;
  final int descansoSeg;

  /// Cadência excêntrica/pausa/concêntrica/pausa — ex.: "4010".
  final String cadencia;
  final MetodoTreino metodo;

  /// Itens com o mesmo número (> 0) são executados em conjunto (bi-set…).
  final int agrupamento;

  ItemTreino copyWith({
    String? exercicioId,
    int? series,
    String? repeticoes,
    double? cargaKg,
    int? descansoSeg,
    String? cadencia,
    MetodoTreino? metodo,
    int? agrupamento,
  }) {
    return ItemTreino(
      exercicioId: exercicioId ?? this.exercicioId,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      cargaKg: cargaKg ?? this.cargaKg,
      descansoSeg: descansoSeg ?? this.descansoSeg,
      cadencia: cadencia ?? this.cadencia,
      metodo: metodo ?? this.metodo,
      agrupamento: agrupamento ?? this.agrupamento,
    );
  }
}

class Treino {
  const Treino({
    required this.id,
    required this.alunoId,
    required this.nome,
    required this.foco,
    required this.diasSemana,
    required this.itens,
  });

  final String id;
  final String alunoId;
  final String nome; // ex.: "Treino A"
  final String foco; // ex.: "Peito e Tríceps"
  final List<int> diasSemana; // DateTime.monday..sunday
  final List<ItemTreino> itens;

  Treino copyWith({List<ItemTreino>? itens, String? foco, String? nome}) {
    return Treino(
      id: id,
      alunoId: alunoId,
      nome: nome ?? this.nome,
      foco: foco ?? this.foco,
      diasSemana: diasSemana,
      itens: itens ?? this.itens,
    );
  }
}

enum TipoAgendamento { treino, avaliacao, consulta }

enum StatusAgendamento { pendente, confirmado, cancelado }

class Agendamento {
  const Agendamento({
    required this.id,
    required this.alunoId,
    required this.titulo,
    required this.tipo,
    required this.dataHora,
    required this.local,
    this.status = StatusAgendamento.pendente,
  });

  final String id;
  final String alunoId;
  final String titulo;
  final TipoAgendamento tipo;
  final DateTime dataHora;
  final String local;
  final StatusAgendamento status;

  Agendamento copyWith({DateTime? dataHora, StatusAgendamento? status}) {
    return Agendamento(
      id: id,
      alunoId: alunoId,
      titulo: titulo,
      tipo: tipo,
      dataHora: dataHora ?? this.dataHora,
      local: local,
      status: status ?? this.status,
    );
  }
}

class Mensagem {
  const Mensagem({
    required this.id,
    required this.alunoId,
    required this.doAluno,
    required this.texto,
    required this.dataHora,
  });

  final String id;
  final String alunoId;

  /// true = enviada pelo aluno; false = enviada pelo personal.
  final bool doAluno;
  final String texto;
  final DateTime dataHora;
}

class RegistroPeso {
  const RegistroPeso({required this.data, required this.pesoKg});

  final DateTime data;
  final double pesoKg;
}

class AvaliacaoFisica {
  const AvaliacaoFisica({
    required this.data,
    required this.pesoKg,
    required this.gorduraPct,
    required this.massaMagraKg,
    this.medidas = const {},
    this.observacoes = '',
    this.pro = const AvaliacaoPro(),
  });

  final DateTime data;
  final double pesoKg;
  final double gorduraPct;
  final double massaMagraKg;
  final AvaliacaoPro pro;

  /// Circunferências em cm — chaves padrão: 'Braço', 'Cintura',
  /// 'Quadril', 'Coxa'.
  final Map<String, double> medidas;
  final String observacoes;
}

/// Dados profissionais opcionais anexados a uma avaliação.
class AvaliacaoPro {
  const AvaliacaoPro({
    this.protocolo = '',
    this.dobras = const {},
    this.bioimpedancia = const {},
    this.testes = const {},
  });

  /// 'pollock3', 'pollock7', 'petroski' ou '' (percentual digitado).
  final String protocolo;

  /// Dobras em mm — chaves: tricipital, subescapular, peitoral,
  /// axilar_media, suprailiaca, abdominal, coxa, panturrilha.
  final Map<String, double> dobras;

  /// agua_pct, gordura_visceral, massa_ossea_kg…
  final Map<String, double> bioimpedancia;

  /// um_rm_kg, cooper_m, vo2, wells_cm…
  final Map<String, double> testes;
}

/// Anamnese digital (PAR-Q + histórico de saúde).
class Anamnese {
  const Anamnese({
    required this.alunoId,
    required this.data,
    required this.parq,
    this.lesoes = '',
    this.cirurgias = '',
    this.medicamentos = '',
    this.horasSono = 7,
    this.habitos = '',
  });

  final String alunoId;
  final DateTime data;

  /// Respostas das 7 perguntas do PAR-Q (true = sim).
  final List<bool> parq;
  final String lesoes;
  final String cirurgias;
  final String medicamentos;
  final int horasSono;
  final String habitos;

  /// Qualquer "sim" no PAR-Q exige liberação médica.
  bool get exigeLiberacaoMedica => parq.any((r) => r);
}

enum AnguloFoto { frente, costas, perfilDireito, perfilEsquerdo }

/// Mensalidade gerada manualmente pelo personal (Fase 1: sem gateway).
class Mensalidade {
  const Mensalidade({
    required this.id,
    required this.alunoId,
    required this.competencia,
    required this.valor,
    required this.vencimento,
    this.pagoEm,
  });

  final String id;
  final String alunoId;

  /// 1º dia do mês de referência.
  final DateTime competencia;
  final double valor;
  final DateTime vencimento;
  final DateTime? pagoEm;

  bool get paga => pagoEm != null;
  bool get atrasada => !paga && DateTime.now().isAfter(vencimento);
}

enum StatusPostagem { pendente, aprovada, rejeitada }

/// Postagem do feed social (criada pelo aluno, moderada pelo personal).
class Postagem {
  const Postagem({
    required this.id,
    required this.alunoId,
    required this.autorNome,
    required this.texto,
    required this.criadaEm,
    this.fotoUrl,
    this.fotoBytes,
    this.status = StatusPostagem.pendente,
    this.motivoRejeicao = '',
    this.curtidas = 0,
    this.euCurti = false,
  });

  final String id;
  final String alunoId;
  final String autorNome;
  final String texto;
  final DateTime criadaEm;
  final String? fotoUrl;
  final List<int>? fotoBytes;
  final StatusPostagem status;
  final String motivoRejeicao;
  final int curtidas;
  final bool euCurti;

  Postagem copyWith({
    StatusPostagem? status,
    String? motivoRejeicao,
    int? curtidas,
    bool? euCurti,
  }) {
    return Postagem(
      id: id,
      alunoId: alunoId,
      autorNome: autorNome,
      texto: texto,
      criadaEm: criadaEm,
      fotoUrl: fotoUrl,
      fotoBytes: fotoBytes,
      status: status ?? this.status,
      motivoRejeicao: motivoRejeicao ?? this.motivoRejeicao,
      curtidas: curtidas ?? this.curtidas,
      euCurti: euCurti ?? this.euCurti,
    );
  }
}

/// Medalha de gamificação derivada do histórico (sem persistência).
class Medalha {
  const Medalha({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.emoji,
    required this.conquistada,
  });

  final String id;
  final String titulo;
  final String descricao;
  final String emoji;
  final bool conquistada;
}

/// Foto postural ou de evolução. No mock os bytes vivem em memória;
/// no Supabase a foto vai para o Storage e [url] é preenchida.
class FotoAluno {
  const FotoAluno({
    required this.id,
    required this.alunoId,
    required this.data,
    this.angulo,
    this.url,
    this.bytes,
    this.observacao = '',
  });

  final String id;
  final String alunoId;
  final DateTime data;
  final AnguloFoto? angulo;
  final String? url;
  final List<int>? bytes;
  final String observacao;
}

/// Uma série efetivamente executada durante um treino.
class SerieRealizada {
  const SerieRealizada({
    required this.indiceItem,
    required this.serie,
    required this.cargaKg,
    required this.repeticoes,
  });

  /// Índice do exercício dentro de `Treino.itens`.
  final int indiceItem;

  /// Número da série (1..n).
  final int serie;
  final double cargaKg;
  final int repeticoes;
}

/// Registro de um treino concluído pelo aluno.
class TreinoConcluido {
  const TreinoConcluido({
    required this.id,
    required this.alunoId,
    required this.treinoId,
    required this.nomeTreino,
    required this.data,
    required this.duracaoMin,
    required this.series,
    this.pse = 0,
    this.dorArticular = false,
    this.dorRelato = '',
  });

  final String id;
  final String alunoId;
  final String treinoId;
  final String nomeTreino; // ex.: "Treino A — Peito e Tríceps"
  final DateTime data;
  final int duracaoMin;
  final List<SerieRealizada> series;

  /// Percepção subjetiva de esforço — Escala de Borg (0–10).
  final int pse;
  final bool dorArticular;
  final String dorRelato;

  /// Soma de carga × repetições de todas as séries (kg).
  double get volumeTotalKg => series.fold(
      0, (total, s) => total + s.cargaKg * s.repeticoes);
}

/// Evolução de carga em um exercício-chave (ex.: supino, agachamento).
class RegistroCarga {
  const RegistroCarga({
    required this.exercicioId,
    required this.data,
    required this.cargaKg,
  });

  final String exercicioId;
  final DateTime data;
  final double cargaKg;
}
