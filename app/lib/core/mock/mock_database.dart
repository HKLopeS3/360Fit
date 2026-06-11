import '../models/models.dart';

/// Fonte única dos dados mockados da fase de validação de UX.
///
/// Datas são geradas em relação a hoje para o app sempre parecer "vivo".
class MockDatabase {
  MockDatabase._();

  static final MockDatabase instance = MockDatabase._();

  final DateTime _hoje = DateTime.now();

  DateTime _diasAtras(int dias) => _hoje.subtract(Duration(days: dias));
  DateTime _emDias(int dias, int hora, [int minuto = 0]) {
    final d = _hoje.add(Duration(days: dias));
    return DateTime(d.year, d.month, d.day, hora, minuto);
  }

  // ---------------------------------------------------------------- usuários

  late final Usuario usuarioAluno = const Usuario(
    id: 'u-aluno-1',
    nome: 'Carlos Mendes',
    email: 'carlos.mendes@email.com',
    perfil: PerfilUsuario.aluno,
  );

  late final Usuario usuarioPersonal = const Usuario(
    id: 'u-personal-1',
    nome: 'João Silva',
    email: 'joao.silva@360fit.com.br',
    perfil: PerfilUsuario.personal,
  );

  // ------------------------------------------------------------------ alunos

  late final List<Aluno> alunos = [
    Aluno(
      id: 'a1',
      nome: 'Carlos Mendes',
      idade: 32,
      objetivo: 'Hipertrofia',
      inicio: _diasAtras(180),
      frequenciaSemanal: 4,
      pesoAtualKg: 82.4,
    ),
    Aluno(
      id: 'a2',
      nome: 'Fernanda Costa',
      idade: 28,
      objetivo: 'Emagrecimento',
      inicio: _diasAtras(95),
      frequenciaSemanal: 3,
      pesoAtualKg: 67.1,
    ),
    Aluno(
      id: 'a3',
      nome: 'Ricardo Almeida',
      idade: 45,
      objetivo: 'Condicionamento',
      inicio: _diasAtras(320),
      frequenciaSemanal: 2,
      pesoAtualKg: 91.0,
      riscoEvasao: true,
    ),
    Aluno(
      id: 'a4',
      nome: 'Juliana Rocha',
      idade: 24,
      objetivo: 'Hipertrofia',
      inicio: _diasAtras(60),
      frequenciaSemanal: 5,
      pesoAtualKg: 58.9,
    ),
    Aluno(
      id: 'a5',
      nome: 'Marcos Pereira',
      idade: 38,
      objetivo: 'Emagrecimento',
      inicio: _diasAtras(40),
      frequenciaSemanal: 1,
      pesoAtualKg: 104.7,
      riscoEvasao: true,
    ),
    Aluno(
      id: 'a6',
      nome: 'Patrícia Lima',
      idade: 51,
      objetivo: 'Saúde e mobilidade',
      inicio: _diasAtras(400),
      frequenciaSemanal: 3,
      pesoAtualKg: 70.3,
    ),
    Aluno(
      id: 'a7',
      nome: 'Bruno Tavares',
      idade: 21,
      objetivo: 'Hipertrofia',
      inicio: _diasAtras(15),
      frequenciaSemanal: 4,
      pesoAtualKg: 74.5,
    ),
    Aluno(
      id: 'a8',
      nome: 'Amanda Souza',
      idade: 30,
      objetivo: 'Preparação para corrida',
      inicio: _diasAtras(220),
      frequenciaSemanal: 3,
      pesoAtualKg: 61.8,
    ),
  ];

  // ----------------------------------------------------------- biblioteca

  final List<Exercicio> exercicios = const [
    // Peito
    Exercicio(id: 'e1', nome: 'Supino reto', grupoMuscular: 'Peito', equipamento: 'Barra'),
    Exercicio(id: 'e2', nome: 'Supino inclinado', grupoMuscular: 'Peito', equipamento: 'Halteres'),
    Exercicio(id: 'e3', nome: 'Crucifixo', grupoMuscular: 'Peito', equipamento: 'Halteres'),
    Exercicio(id: 'e4', nome: 'Crossover', grupoMuscular: 'Peito', equipamento: 'Polia'),
    // Costas
    Exercicio(id: 'e5', nome: 'Puxada frontal', grupoMuscular: 'Costas', equipamento: 'Polia'),
    Exercicio(id: 'e6', nome: 'Remada curvada', grupoMuscular: 'Costas', equipamento: 'Barra'),
    Exercicio(id: 'e7', nome: 'Remada baixa', grupoMuscular: 'Costas', equipamento: 'Polia'),
    Exercicio(id: 'e8', nome: 'Barra fixa', grupoMuscular: 'Costas', equipamento: 'Peso corporal'),
    // Pernas
    Exercicio(id: 'e9', nome: 'Agachamento livre', grupoMuscular: 'Pernas', equipamento: 'Barra'),
    Exercicio(id: 'e10', nome: 'Leg press 45°', grupoMuscular: 'Pernas', equipamento: 'Máquina'),
    Exercicio(id: 'e11', nome: 'Cadeira extensora', grupoMuscular: 'Pernas', equipamento: 'Máquina'),
    Exercicio(id: 'e12', nome: 'Mesa flexora', grupoMuscular: 'Pernas', equipamento: 'Máquina'),
    Exercicio(id: 'e13', nome: 'Stiff', grupoMuscular: 'Pernas', equipamento: 'Barra'),
    Exercicio(id: 'e14', nome: 'Panturrilha em pé', grupoMuscular: 'Pernas', equipamento: 'Máquina'),
    Exercicio(id: 'e15', nome: 'Avanço', grupoMuscular: 'Pernas', equipamento: 'Halteres'),
    // Ombros
    Exercicio(id: 'e16', nome: 'Desenvolvimento militar', grupoMuscular: 'Ombros', equipamento: 'Barra'),
    Exercicio(id: 'e17', nome: 'Elevação lateral', grupoMuscular: 'Ombros', equipamento: 'Halteres'),
    Exercicio(id: 'e18', nome: 'Elevação frontal', grupoMuscular: 'Ombros', equipamento: 'Halteres'),
    Exercicio(id: 'e19', nome: 'Encolhimento', grupoMuscular: 'Ombros', equipamento: 'Halteres'),
    // Braços
    Exercicio(id: 'e20', nome: 'Rosca direta', grupoMuscular: 'Bíceps', equipamento: 'Barra'),
    Exercicio(id: 'e21', nome: 'Rosca alternada', grupoMuscular: 'Bíceps', equipamento: 'Halteres'),
    Exercicio(id: 'e22', nome: 'Rosca martelo', grupoMuscular: 'Bíceps', equipamento: 'Halteres'),
    Exercicio(id: 'e23', nome: 'Tríceps testa', grupoMuscular: 'Tríceps', equipamento: 'Barra'),
    Exercicio(id: 'e24', nome: 'Tríceps corda', grupoMuscular: 'Tríceps', equipamento: 'Polia'),
    Exercicio(id: 'e25', nome: 'Mergulho no banco', grupoMuscular: 'Tríceps', equipamento: 'Peso corporal'),
    // Core / cardio
    Exercicio(id: 'e26', nome: 'Prancha', grupoMuscular: 'Core', equipamento: 'Peso corporal'),
    Exercicio(id: 'e27', nome: 'Abdominal infra', grupoMuscular: 'Core', equipamento: 'Peso corporal'),
    Exercicio(id: 'e28', nome: 'Elevação de pernas', grupoMuscular: 'Core', equipamento: 'Peso corporal'),
    Exercicio(id: 'e29', nome: 'Esteira (HIIT)', grupoMuscular: 'Cardio', equipamento: 'Esteira'),
    Exercicio(id: 'e30', nome: 'Bicicleta ergométrica', grupoMuscular: 'Cardio', equipamento: 'Bicicleta'),
  ];

  Exercicio exercicioPorId(String id) =>
      exercicios.firstWhere((e) => e.id == id);

  // ------------------------------------------------------------------ treinos

  late final List<Treino> treinos = [
    // Carlos (a1) — aluno logado
    const Treino(
      id: 't1',
      alunoId: 'a1',
      nome: 'Treino A',
      foco: 'Peito e Tríceps',
      diasSemana: [DateTime.monday, DateTime.thursday],
      itens: [
        ItemTreino(exercicioId: 'e1', series: 4, repeticoes: '8-10', cargaKg: 70),
        ItemTreino(exercicioId: 'e2', series: 3, repeticoes: '10-12', cargaKg: 24),
        ItemTreino(exercicioId: 'e4', series: 3, repeticoes: '12-15', cargaKg: 18),
        ItemTreino(exercicioId: 'e23', series: 3, repeticoes: '10-12', cargaKg: 25),
        ItemTreino(exercicioId: 'e24', series: 3, repeticoes: '12-15', cargaKg: 30),
        ItemTreino(exercicioId: 'e26', series: 3, repeticoes: '45s', cargaKg: 0),
      ],
    ),
    const Treino(
      id: 't2',
      alunoId: 'a1',
      nome: 'Treino B',
      foco: 'Costas e Bíceps',
      diasSemana: [DateTime.tuesday, DateTime.friday],
      itens: [
        ItemTreino(exercicioId: 'e5', series: 4, repeticoes: '8-10', cargaKg: 60),
        ItemTreino(exercicioId: 'e6', series: 3, repeticoes: '8-10', cargaKg: 50),
        ItemTreino(exercicioId: 'e7', series: 3, repeticoes: '10-12', cargaKg: 55),
        ItemTreino(exercicioId: 'e20', series: 3, repeticoes: '10-12', cargaKg: 30),
        ItemTreino(exercicioId: 'e22', series: 3, repeticoes: '12', cargaKg: 14),
      ],
    ),
    const Treino(
      id: 't3',
      alunoId: 'a1',
      nome: 'Treino C',
      foco: 'Pernas e Ombros',
      diasSemana: [
        DateTime.wednesday,
        DateTime.saturday,
        DateTime.sunday,
      ],
      itens: [
        ItemTreino(exercicioId: 'e9', series: 4, repeticoes: '6-8', cargaKg: 90),
        ItemTreino(exercicioId: 'e10', series: 4, repeticoes: '10-12', cargaKg: 180),
        ItemTreino(exercicioId: 'e12', series: 3, repeticoes: '12', cargaKg: 45),
        ItemTreino(exercicioId: 'e14', series: 4, repeticoes: '15-20', cargaKg: 60),
        ItemTreino(exercicioId: 'e16', series: 3, repeticoes: '8-10', cargaKg: 40),
        ItemTreino(exercicioId: 'e17', series: 3, repeticoes: '12-15', cargaKg: 10),
      ],
    ),
    // Fernanda (a2)
    const Treino(
      id: 't4',
      alunoId: 'a2',
      nome: 'Treino A',
      foco: 'Full body + cardio',
      diasSemana: [DateTime.monday, DateTime.wednesday, DateTime.friday],
      itens: [
        ItemTreino(exercicioId: 'e10', series: 3, repeticoes: '12-15', cargaKg: 100),
        ItemTreino(exercicioId: 'e5', series: 3, repeticoes: '12', cargaKg: 35),
        ItemTreino(exercicioId: 'e17', series: 3, repeticoes: '15', cargaKg: 6),
        ItemTreino(exercicioId: 'e27', series: 3, repeticoes: '20', cargaKg: 0),
        ItemTreino(exercicioId: 'e29', series: 1, repeticoes: '20min', cargaKg: 0),
      ],
    ),
    // Juliana (a4)
    const Treino(
      id: 't5',
      alunoId: 'a4',
      nome: 'Treino A',
      foco: 'Inferiores',
      diasSemana: [DateTime.monday, DateTime.thursday],
      itens: [
        ItemTreino(exercicioId: 'e9', series: 4, repeticoes: '8', cargaKg: 50),
        ItemTreino(exercicioId: 'e13', series: 3, repeticoes: '10', cargaKg: 40),
        ItemTreino(exercicioId: 'e11', series: 3, repeticoes: '12-15', cargaKg: 35),
        ItemTreino(exercicioId: 'e15', series: 3, repeticoes: '12', cargaKg: 12),
      ],
    ),
  ];

  // ------------------------------------------------------------- agendamentos

  late final List<Agendamento> agendamentos = [
    Agendamento(
      id: 'ag1',
      alunoId: 'a1',
      titulo: 'Treino acompanhado',
      tipo: TipoAgendamento.treino,
      dataHora: _emDias(0, 18, 30),
      local: 'Academia Alpha — Unidade Centro',
    ),
    Agendamento(
      id: 'ag2',
      alunoId: 'a1',
      titulo: 'Avaliação física trimestral',
      tipo: TipoAgendamento.avaliacao,
      dataHora: _emDias(2, 9, 0),
      local: 'Sala de avaliação',
    ),
    Agendamento(
      id: 'ag3',
      alunoId: 'a2',
      titulo: 'Treino acompanhado',
      tipo: TipoAgendamento.treino,
      dataHora: _emDias(0, 7, 0),
      local: 'Academia Alpha — Unidade Centro',
    ),
    Agendamento(
      id: 'ag4',
      alunoId: 'a4',
      titulo: 'Treino acompanhado',
      tipo: TipoAgendamento.treino,
      dataHora: _emDias(0, 10, 0),
      local: 'Academia Alpha — Unidade Centro',
    ),
    Agendamento(
      id: 'ag5',
      alunoId: 'a3',
      titulo: 'Conversa de retorno',
      tipo: TipoAgendamento.consulta,
      dataHora: _emDias(1, 19, 0),
      local: 'Online (videochamada)',
    ),
    Agendamento(
      id: 'ag6',
      alunoId: 'a1',
      titulo: 'Treino acompanhado',
      tipo: TipoAgendamento.treino,
      dataHora: _emDias(7, 18, 30),
      local: 'Academia Alpha — Unidade Centro',
    ),
    Agendamento(
      id: 'ag7',
      alunoId: 'a6',
      titulo: 'Avaliação física',
      tipo: TipoAgendamento.avaliacao,
      dataHora: _emDias(3, 8, 0),
      local: 'Sala de avaliação',
    ),
  ];

  // ---------------------------------------------------------------- mensagens

  late final List<Mensagem> mensagens = [
    Mensagem(
      id: 'm1',
      alunoId: 'a1',
      doAluno: true,
      texto: 'Fala João! Senti um desconforto no ombro no supino ontem.',
      dataHora: _diasAtras(1).copyWith(hour: 20, minute: 14),
    ),
    Mensagem(
      id: 'm2',
      alunoId: 'a1',
      doAluno: false,
      texto:
          'Opa Carlos! Vamos reduzir a carga e ajustar a pegada no próximo treino. Se persistir, te encaminho pra fisio, beleza?',
      dataHora: _diasAtras(1).copyWith(hour: 20, minute: 31),
    ),
    Mensagem(
      id: 'm3',
      alunoId: 'a1',
      doAluno: true,
      texto: 'Fechou! Hoje é treino A mesmo?',
      dataHora: _hoje.copyWith(hour: 8, minute: 2),
    ),
    Mensagem(
      id: 'm4',
      alunoId: 'a1',
      doAluno: false,
      texto: 'Isso! Te vejo às 18h30 na academia. 💪',
      dataHora: _hoje.copyWith(hour: 8, minute: 10),
    ),
  ];

  // ----------------------------------------------------------------- evolução

  late final Map<String, List<RegistroPeso>> pesos = {
    'a1': [
      for (var i = 0; i < 12; i++)
        RegistroPeso(
          data: _diasAtras((11 - i) * 15),
          pesoKg: 78.0 + i * 0.4,
        ),
    ],
    'a2': [
      for (var i = 0; i < 8; i++)
        RegistroPeso(
          data: _diasAtras((7 - i) * 12),
          pesoKg: 72.5 - i * 0.77,
        ),
    ],
  };

  late final Map<String, List<AvaliacaoFisica>> avaliacoes = {
    'a1': [
      AvaliacaoFisica(
          data: _diasAtras(180), pesoKg: 78.0, gorduraPct: 21.5, massaMagraKg: 61.2),
      AvaliacaoFisica(
          data: _diasAtras(90), pesoKg: 80.1, gorduraPct: 19.2, massaMagraKg: 64.7),
      AvaliacaoFisica(
          data: _diasAtras(5), pesoKg: 82.4, gorduraPct: 17.8, massaMagraKg: 67.7),
    ],
    'a2': [
      AvaliacaoFisica(
          data: _diasAtras(95), pesoKg: 72.5, gorduraPct: 31.0, massaMagraKg: 50.0),
      AvaliacaoFisica(
          data: _diasAtras(10), pesoKg: 67.1, gorduraPct: 27.4, massaMagraKg: 48.7),
    ],
  };

  /// Evolução de carga nos exercícios-chave do aluno logado.
  late final List<RegistroCarga> cargas = [
    // Supino reto (e1)
    for (final (i, c) in [50.0, 55.0, 57.5, 60.0, 65.0, 67.5, 70.0].indexed)
      RegistroCarga(
          exercicioId: 'e1', data: _diasAtras((6 - i) * 25), cargaKg: c),
    // Agachamento (e9)
    for (final (i, c) in [60.0, 70.0, 75.0, 80.0, 85.0, 90.0].indexed)
      RegistroCarga(
          exercicioId: 'e9', data: _diasAtras((5 - i) * 30), cargaKg: c),
  ];

  // -------------------------------------------------- treinos concluídos

  /// Histórico de execuções do Carlos (a1) — alimenta o calendário de
  /// frequência e a lista de conclusões.
  late final List<TreinoConcluido> treinosConcluidos = [
    for (final (i, dias) in [2, 3, 5, 7, 9, 10, 12, 14, 16, 17].indexed)
      TreinoConcluido(
        id: 'tc${i + 1}',
        alunoId: 'a1',
        treinoId: 't${(i % 3) + 1}',
        nomeTreino: const [
          'Treino A — Peito e Tríceps',
          'Treino B — Costas e Bíceps',
          'Treino C — Pernas e Ombros',
        ][i % 3],
        data: _diasAtras(dias),
        duracaoMin: 48 + (i * 7) % 25,
        series: const [
          SerieRealizada(indiceItem: 0, serie: 1, cargaKg: 70, repeticoes: 10),
          SerieRealizada(indiceItem: 0, serie: 2, cargaKg: 70, repeticoes: 9),
          SerieRealizada(indiceItem: 1, serie: 1, cargaKg: 24, repeticoes: 12),
        ],
      ),
  ];

  // ---------------------------------------------------- frequência (semana)

  /// Treinos concluídos por dia nos últimos 7 dias (para o dashboard).
  late final List<int> treinosRealizadosSemana = [9, 12, 7, 14, 11, 6, 4];
}
