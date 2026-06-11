import '../../core/config/contato.dart';

/// Conteúdo das políticas exibidas no app.
///
/// Fonte canônica: docs/politicas/*.md (mesmo texto, mantido em sincronia).
/// As lojas exigem também uma URL pública com este conteúdo.
class SecaoDoc {
  const SecaoDoc(this.titulo, this.corpo);

  final String titulo;
  final String corpo;
}

class DocumentoLegal {
  const DocumentoLegal({
    required this.titulo,
    required this.atualizadoEm,
    required this.secoes,
  });

  final String titulo;
  final String atualizadoEm;
  final List<SecaoDoc> secoes;
}

const politicaPrivacidade = DocumentoLegal(
  titulo: 'Política de Privacidade',
  atualizadoEm: '11 de junho de 2026',
  secoes: [
    SecaoDoc(
      'Quem somos',
      'O ${Contato.nomeApp} é uma plataforma de gestão fitness, saúde e '
          'performance que conecta academias, personal trainers, nutricionistas, '
          'fisioterapeutas e seus alunos.\n\n'
          'Contato do controlador de dados: ${Contato.email} · ${Contato.telefone}.',
    ),
    SecaoDoc(
      'Dados que coletamos',
      '• Cadastro (nome, email, telefone) — criar e autenticar a sua conta.\n'
          '• Perfil físico (idade, peso, medidas, objetivo) — acompanhamento do treino.\n'
          '• Dados de saúde (avaliações físicas, restrições) — prescrição segura; '
          'são dados sensíveis pela LGPD, tratados com o seu consentimento e visíveis '
          'apenas a você, ao profissional responsável e ao administrador da sua empresa.\n'
          '• Uso do app (treinos realizados, frequência, agendamentos).\n'
          '• Mensagens trocadas com o seu profissional.',
    ),
    SecaoDoc(
      'O que NÃO fazemos',
      'Não vendemos seus dados, não os compartilhamos para publicidade e não '
          'usamos seus dados de saúde para nada além do acompanhamento contratado.',
    ),
    SecaoDoc(
      'Compartilhamento',
      'Seus dados são visíveis apenas dentro do ambiente da empresa à qual você '
          'está vinculado, conforme o papel de cada usuário. Usamos a infraestrutura '
          'Supabase (banco de dados e autenticação) com isolamento por empresa e '
          'criptografia em trânsito.',
    ),
    SecaoDoc(
      'Retenção e exclusão',
      'Mantemos seus dados enquanto a conta estiver ativa. Você pode excluir a '
          'conta e todos os dados pelo app (Mais → Excluir minha conta) ou pelo '
          'email ${Contato.email}. O processo é concluído em até 30 dias.',
    ),
    SecaoDoc(
      'Seus direitos (LGPD)',
      'A qualquer momento você pode acessar, corrigir, portar ou eliminar seus '
          'dados e revogar consentimentos — basta contatar ${Contato.email}.',
    ),
    SecaoDoc(
      'Menores de idade',
      'O app não é destinado a menores de 13 anos. Entre 13 e 18 anos, o '
          'cadastro deve ser autorizado por responsável legal junto à academia/clínica.',
    ),
    SecaoDoc(
      'Segurança',
      'Controle de acesso por papel e por empresa (Row Level Security), '
          'criptografia em trânsito (TLS) e autenticação segura. Em caso de '
          'incidente relevante, comunicaremos os afetados e a ANPD conforme a LGPD.',
    ),
    SecaoDoc(
      'Permissões do aplicativo',
      'Câmera/galeria (foto de perfil e avaliações, somente quando você optar) '
          'e notificações (lembretes de treino e agendamentos).',
    ),
    SecaoDoc(
      'Contato',
      'Dúvidas sobre privacidade: ${Contato.email} · ${Contato.telefone}.',
    ),
  ],
);

const termosDeUso = DocumentoLegal(
  titulo: 'Termos de Uso',
  atualizadoEm: '11 de junho de 2026',
  secoes: [
    SecaoDoc(
      'Aceitação',
      'Ao criar uma conta ou usar o ${Contato.nomeApp} você concorda com estes '
          'Termos e com a Política de Privacidade.',
    ),
    SecaoDoc(
      'O serviço',
      'Plataforma SaaS de gestão fitness: prescrição e acompanhamento de '
          'treinos, avaliações físicas, agenda, comunicação profissional–aluno e '
          'módulos administrativos, conforme o plano contratado (Basic, Pro ou Premium).',
    ),
    SecaoDoc(
      'Contas e responsabilidades',
      'As credenciais são pessoais e intransferíveis. Profissionais declaram '
          'possuir habilitação válida (CREF, CRN, CREFITO etc.). A empresa '
          'contratante é responsável pelos vínculos com seus alunos e profissionais.',
    ),
    SecaoDoc(
      'Aviso importante de saúde',
      'O ${Contato.nomeApp} é uma ferramenta de gestão — não presta '
          'aconselhamento médico. Treinos e orientações são de responsabilidade do '
          'profissional habilitado. Consulte um médico antes de iniciar exercícios; '
          'em caso de dor ou mal-estar, interrompa a atividade e procure atendimento.',
    ),
    SecaoDoc(
      'Assinaturas e cancelamento',
      'Planos com cobrança recorrente. O cancelamento interrompe as cobranças '
          'seguintes e o acesso permanece até o fim do período pago.',
    ),
    SecaoDoc(
      'Uso aceitável',
      'É proibido usar a plataforma para fins ilícitos, tentar acessar dados de '
          'outras empresas ou usuários, fazer engenharia reversa ou publicar '
          'conteúdo ofensivo.',
    ),
    SecaoDoc(
      'Limitação de responsabilidade',
      'O serviço é fornecido "como está", podendo passar por manutenções. Na '
          'máxima extensão legal, a responsabilidade limita-se aos valores pagos '
          'nos 12 meses anteriores.',
    ),
    SecaoDoc(
      'Foro e contato',
      'Lei brasileira; foro da comarca do domicílio do consumidor. '
          'Contato: ${Contato.email} · ${Contato.telefone}.',
    ),
  ],
);

const exclusaoDeConta = DocumentoLegal(
  titulo: 'Exclusão de Conta e Dados',
  atualizadoEm: '11 de junho de 2026',
  secoes: [
    SecaoDoc(
      'Pelo aplicativo',
      'Mais → Excluir minha conta → confirmar. A conta é desativada '
          'imediatamente e os dados são apagados definitivamente em até 30 dias.',
    ),
    SecaoDoc(
      'Por email',
      'Envie "Exclusão de conta" para ${Contato.email} a partir do email '
          'cadastrado, informando seu nome completo. Concluímos em até 30 dias com '
          'confirmação. Dúvidas: ${Contato.telefone}.',
    ),
    SecaoDoc(
      'O que é excluído',
      'Conta de acesso e perfil; dados físicos e de saúde; treinos, histórico, '
          'agendamentos e mensagens; fotos enviadas.',
    ),
    SecaoDoc(
      'O que pode ser retido',
      'Registros fiscais exigidos por lei e logs técnicos de segurança por até '
          '6 meses (Marco Civil da Internet), isolados e sem outro uso.',
    ),
  ],
);
