import 'package:flutter/material.dart';
import 'models.dart';

final _hoje = DateTime.now();
DateTime _d(int diasOffset) => _hoje.add(Duration(days: diasOffset));

// ── Usuário logado (gestor demo) ──────────────────────────────────────────────
const usuarioDemo = UsuarioAcademia(
  id: 'u1',
  nome: 'José Herick',
  perfil: PerfilAcademia.gestor,
  academiaId: 'ac1',
  academiaNome: 'FitZone Academia',
);

// ── Alunos ────────────────────────────────────────────────────────────────────
final alunos = <AlunoAcademia>[
  AlunoAcademia(id:'a1',  nome:'Mariana Costa',     email:'mariana@email.com',  telefone:'(11) 99999-0001', plano:PlanoTipo.mensal,     vencimento:_d(12),  ativo:true,  ultimoCheckin:_d(-1),  cpf:'123.456.789-00', dataNascimento:DateTime(1995,3,22),  sexo:Sexo.feminino,  objetivo:'Emagrecimento', cep:'01310-100', logradouro:'Av. Paulista',     numero:'1000', bairro:'Bela Vista', cidade:'São Paulo',   professor:'Prof. Anderson'),
  AlunoAcademia(id:'a2',  nome:'Carlos Mendes',     email:'carlos@email.com',   telefone:'(11) 99999-0002', plano:PlanoTipo.trimestral, vencimento:_d(45),  ativo:true,  ultimoCheckin:_d(0),   cpf:'234.567.890-11', dataNascimento:DateTime(1990,7,15),  sexo:Sexo.masculino, objetivo:'Hipertrofia',    cep:'01415-001', logradouro:'R. Augusta',       numero:'500',  bairro:'Consolação', cidade:'São Paulo',   professor:'Prof. Lucas'),
  AlunoAcademia(id:'a3',  nome:'Fernanda Lima',     email:'fernanda@email.com', telefone:'(11) 99999-0003', plano:PlanoTipo.mensal,     vencimento:_d(-8),  ativo:true,  ultimoCheckin:_d(-10), cpf:'345.678.901-22', dataNascimento:DateTime(1998,11,5),  sexo:Sexo.feminino,  objetivo:'Condicionamento',cep:'04546-000', logradouro:'R. Funchal',       numero:'160',  bairro:'Vila Olímpia',cidade:'São Paulo',   professor:'Prof. Anderson'),
  AlunoAcademia(id:'a4',  nome:'Rafael Santos',     email:'rafael@email.com',   telefone:'(11) 99999-0004', plano:PlanoTipo.anual,      vencimento:_d(180), ativo:true,  ultimoCheckin:_d(0),   cpf:'456.789.012-33', dataNascimento:DateTime(1985,2,28),  sexo:Sexo.masculino, objetivo:'Hipertrofia',    cep:'01310-200', logradouro:'Av. Brigadeiro',   numero:'2500', bairro:'Jardins',    cidade:'São Paulo',   professor:'Prof. Lucas'),
  AlunoAcademia(id:'a5',  nome:'Ana Paula Ribeiro', email:'ana@email.com',      telefone:'(11) 99999-0005', plano:PlanoTipo.mensal,     vencimento:_d(3),   ativo:true,  ultimoCheckin:_d(-2),  cpf:'567.890.123-44', dataNascimento:DateTime(2000,9,10),  sexo:Sexo.feminino,  objetivo:'Emagrecimento', cep:'05422-010', logradouro:'R. Teodoro Sampaio',numero:'88',  bairro:'Pinheiros',  cidade:'São Paulo',   professor:'Prof. Carla'),
  AlunoAcademia(id:'a6',  nome:'Bruno Alves',       email:'bruno@email.com',    telefone:'(11) 99999-0006', plano:PlanoTipo.semestral,  vencimento:_d(60),  ativo:true,  ultimoCheckin:_d(0),   cpf:'678.901.234-55', dataNascimento:DateTime(1993,6,1),   sexo:Sexo.masculino, objetivo:'Saúde geral',    cep:'04728-000', logradouro:'Av. Santo Amaro',  numero:'400',  bairro:'Santo Amaro',cidade:'São Paulo',   professor:'Prof. Roberto'),
  AlunoAcademia(id:'a7',  nome:'Juliana Neves',     email:'juliana@email.com',  telefone:'(11) 99999-0007', plano:PlanoTipo.mensal,     vencimento:_d(-15), ativo:false, ultimoCheckin:_d(-20), cpf:'789.012.345-66', dataNascimento:DateTime(1997,4,18),  sexo:Sexo.feminino,  objetivo:'Flexibilidade', cep:'04025-001', logradouro:'R. Vergueiro',     numero:'3000', bairro:'Paraíso',    cidade:'São Paulo',   professor:'Prof. Marina'),
  AlunoAcademia(id:'a8',  nome:'Diego Oliveira',    email:'diego@email.com',    telefone:'(11) 99999-0008', plano:PlanoTipo.trimestral, vencimento:_d(4),   ativo:true,  ultimoCheckin:_d(-3),  cpf:'890.123.456-77', dataNascimento:DateTime(1988,12,25), sexo:Sexo.masculino, objetivo:'Hipertrofia',    cep:'01001-000', logradouro:'Praça da Sé',      numero:'1',    bairro:'Sé',         cidade:'São Paulo',   professor:'Prof. Lucas'),
  AlunoAcademia(id:'a9',  nome:'Camila Torres',     email:'camila@email.com',   telefone:'(11) 99999-0009', plano:PlanoTipo.mensal,     vencimento:_d(20),  ativo:true,  ultimoCheckin:_d(0),   cpf:'901.234.567-88', dataNascimento:DateTime(2001,8,30),  sexo:Sexo.feminino,  objetivo:'Emagrecimento', cep:'04551-060', logradouro:'R. Joaquim Floriano',numero:'820', bairro:'Itaim Bibi', cidade:'São Paulo',   professor:'Prof. Carla'),
  AlunoAcademia(id:'a10', nome:'Thiago Martins',    email:'thiago@email.com',   telefone:'(11) 99999-0010', plano:PlanoTipo.anual,      vencimento:_d(90),  ativo:true,  ultimoCheckin:_d(-1),  cpf:'012.345.678-99', dataNascimento:DateTime(1983,1,7),   sexo:Sexo.masculino, objetivo:'Condicionamento',cep:'01402-000', logradouro:'R. Haddock Lobo',  numero:'595',  bairro:'Cerqueira César',cidade:'São Paulo',professor:'Prof. Anderson'),
];

// ── Mensalidades ──────────────────────────────────────────────────────────────
final mensalidades = <MensalidadeAcademia>[
  MensalidadeAcademia(id:'m1', alunoId:'a1', alunoNome:'Mariana Costa',    valor:120, vencimento:_d(12),  pagoEm: _d(-18)),
  MensalidadeAcademia(id:'m2', alunoId:'a2', alunoNome:'Carlos Mendes',    valor:320, vencimento:_d(45),  pagoEm: _d(-5)),
  MensalidadeAcademia(id:'m3', alunoId:'a3', alunoNome:'Fernanda Lima',    valor:120, vencimento:_d(-8),  pagoEm: null),
  MensalidadeAcademia(id:'m4', alunoId:'a4', alunoNome:'Rafael Santos',    valor:900, vencimento:_d(180), pagoEm: _d(-60)),
  MensalidadeAcademia(id:'m5', alunoId:'a5', alunoNome:'Ana Paula Ribeiro',valor:120, vencimento:_d(3),   pagoEm: null),
  MensalidadeAcademia(id:'m6', alunoId:'a6', alunoNome:'Bruno Alves',      valor:550, vencimento:_d(60),  pagoEm: _d(-10)),
  MensalidadeAcademia(id:'m7', alunoId:'a7', alunoNome:'Juliana Neves',    valor:120, vencimento:_d(-15), pagoEm: null),
  MensalidadeAcademia(id:'m8', alunoId:'a8', alunoNome:'Diego Oliveira',   valor:320, vencimento:_d(4),   pagoEm: null),
  MensalidadeAcademia(id:'m9', alunoId:'a9', alunoNome:'Camila Torres',    valor:120, vencimento:_d(20),  pagoEm: _d(-2)),
  MensalidadeAcademia(id:'m10',alunoId:'a10',alunoNome:'Thiago Martins',   valor:900, vencimento:_d(90),  pagoEm: _d(-30)),
];

// ── Turmas ────────────────────────────────────────────────────────────────────
final turmas = <Turma>[
  Turma(id:'t1', nome:'Musculação Manhã',   professor:'Prof. Anderson', horario:const TimeOfDay(hour:6,  minute:0),  diasSemana:[DateTime.monday,DateTime.wednesday,DateTime.friday],    vagas:30, inscritos:22, sala:'Sala A'),
  Turma(id:'t2', nome:'Spinning',           professor:'Prof. Carla',    horario:const TimeOfDay(hour:7,  minute:0),  diasSemana:[DateTime.tuesday,DateTime.thursday],                      vagas:20, inscritos:20, sala:'Sala B'),
  Turma(id:'t3', nome:'Funcional',          professor:'Prof. Roberto',  horario:const TimeOfDay(hour:8,  minute:30), diasSemana:[DateTime.monday,DateTime.wednesday,DateTime.friday],    vagas:15, inscritos:10, sala:'Área Externa'),
  Turma(id:'t4', nome:'Yoga',               professor:'Prof. Marina',   horario:const TimeOfDay(hour:9,  minute:0),  diasSemana:[DateTime.tuesday,DateTime.thursday,DateTime.saturday], vagas:12, inscritos:8,  sala:'Sala C'),
  Turma(id:'t5', nome:'Musculação Tarde',   professor:'Prof. Anderson', horario:const TimeOfDay(hour:17, minute:0),  diasSemana:[DateTime.monday,DateTime.wednesday,DateTime.friday],    vagas:30, inscritos:28, sala:'Sala A'),
  Turma(id:'t6', nome:'Zumba',              professor:'Prof. Fernanda', horario:const TimeOfDay(hour:18, minute:0),  diasSemana:[DateTime.tuesday,DateTime.thursday,DateTime.saturday], vagas:25, inscritos:18, sala:'Sala B'),
  Turma(id:'t7', nome:'Musculação Noite',   professor:'Prof. Lucas',    horario:const TimeOfDay(hour:19, minute:0),  diasSemana:[DateTime.monday,DateTime.tuesday,DateTime.wednesday,DateTime.thursday,DateTime.friday], vagas:30, inscritos:25, sala:'Sala A'),
  Turma(id:'t8', nome:'Pilates',            professor:'Prof. Beatriz',  horario:const TimeOfDay(hour:10, minute:0),  diasSemana:[DateTime.monday,DateTime.wednesday,DateTime.friday],    vagas:10, inscritos:7,  sala:'Sala C'),
];

// ── Check-ins de hoje ─────────────────────────────────────────────────────────
final checkInsHoje = <CheckIn>[
  CheckIn(id:'c1', alunoId:'a2', alunoNome:'Carlos Mendes',    alunoIniciais:'CM', quando: DateTime(_hoje.year,_hoje.month,_hoje.day, 6, 12)),
  CheckIn(id:'c2', alunoId:'a4', alunoNome:'Rafael Santos',    alunoIniciais:'RS', quando: DateTime(_hoje.year,_hoje.month,_hoje.day, 7, 3)),
  CheckIn(id:'c3', alunoId:'a6', alunoNome:'Bruno Alves',      alunoIniciais:'BA', quando: DateTime(_hoje.year,_hoje.month,_hoje.day, 7, 45)),
  CheckIn(id:'c4', alunoId:'a9', alunoNome:'Camila Torres',    alunoIniciais:'CT', quando: DateTime(_hoje.year,_hoje.month,_hoje.day, 8, 10)),
];

// ── Helpers de resumo ─────────────────────────────────────────────────────────
int get totalAtivos      => alunos.where((a) => a.ativo).length;
int get totalInadimplentes => alunos.where((a) => a.situacao == SituacaoFinanceira.inadimplente).length;
int get checkInsHojeCount => checkInsHoje.length;
double get receitaMes    => mensalidades.where((m) => m.paga).fold(0, (s, m) => s + m.valor);
double get receitaPendente => mensalidades.where((m) => !m.paga).fold(0, (s, m) => s + m.valor);

// Check-ins por dia (últimos 7 dias — simulado)
List<int> get checkInsPorDia => [8, 12, 6, 15, 10, 18, checkInsHojeCount];
