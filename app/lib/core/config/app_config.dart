/// Configuração de build do app.
///
/// O backend Supabase é ativado passando as credenciais no build:
/// ```
/// flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///             --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
/// Sem elas o app roda 100% nos repositórios mock (modo demo/desenvolvimento).
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Senha dos usuários de demonstração criados junto com o seed.
  static const demoSenha =
      String.fromEnvironment('DEMO_SENHA', defaultValue: 'demo360fit');

  static bool get usarSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
