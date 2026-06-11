import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme/brand_theme.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  if (AppConfig.usarSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const ProviderScope(child: Fit360App()));
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
