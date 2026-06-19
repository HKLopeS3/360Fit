import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme/brand_theme.dart';
import 'core/config/app_config.dart';
import 'core/models/models.dart';
import 'data/providers.dart';
import 'data/repositories/supabase_repositories.dart';
import 'features/auth/boas_vindas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  Usuario? sessaoRestaurada;
  if (AppConfig.usarSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    try {
      sessaoRestaurada = await SupabaseAuthRepository().usuarioAtual();
    } catch (_) {
      // Sem rede ou sessão irrecuperável: segue para o login normalmente.
    }
  }
  if (sessaoRestaurada != null) {
    final String destino;
    if (BoasVindasScreen.deveExibir(sessaoRestaurada.id)) {
      destino = '/boas-vindas';
    } else {
      destino = sessaoRestaurada.perfil == PerfilUsuario.aluno
          ? '/aluno/hoje'
          : '/personal/dashboard';
    }
    router = criarRouter(initialLocation: destino);
  }

  runApp(ProviderScope(
    overrides: [
      if (sessaoRestaurada != null)
        sessaoProvider.overrideWith(() => SessaoNotifier(sessaoRestaurada)),
    ],
    child: const Fit360App(),
  ));
}

class Fit360App extends StatelessWidget {
  const Fit360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '360Fit',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}

