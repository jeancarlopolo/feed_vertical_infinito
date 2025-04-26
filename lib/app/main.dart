import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:bluesky/bluesky.dart';
import 'package:atproto/atproto.dart';
import 'package:atproto_core/atproto_core.dart';
import 'package:logging/logging.dart';
import 'main_app.dart';
import '../services/bsky_videos.dart';

Future<void> main() async {
  await setupApp();
}

Future<void> setupApp() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('meulog: ${record.loggerName}: ${record.message}');
  });

  // **** IMPORTANTE: NÃO USE CREDENCIAIS HARDCODED EM PRODUÇÃO ****
  const String handle = 'tonhaomototaxi.bsky.social'; // <-- Substitua!
  const String appPassword = 'z5g2-wlmi-z3jl-vdmr'; // <-- Substitua! (Formato: xxxx-xxxx-xxxx-xxxx)

  try {
    // Tentar criar a sessão usando atproto.createSession
    final session = await createSession(
      service: 'bsky.social', // Ou o PDS correto se não for bsky.social
      identifier: handle,
      password: appPassword,
    );

    if (session.data.handle.isEmpty) {
      throw Exception('Falha ao criar sessão - verifique as credenciais');
    }

    // Configurar GetIt com a sessão autenticada
    setup(session.data);
    runApp(const MainApp());
  } catch (e) {
    // ignore: avoid_print
    print('E/ Erro fatal durante a autenticação inicial: $e');
    runApp(const ErrorApp());
  }
}


// Modificar setup para aceitar a sessão
void setup(Session sessionData) {
  // Registrar Bluesky autenticado
  GetIt.instance.registerSingleton<Bluesky>(Bluesky.fromSession(sessionData));
  GetIt.instance.registerSingleton<BskyVideos>(BskyVideos());
}

// Widget simples para exibir erro de inicialização
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erro ao iniciar. Verifique as credenciais e a conexão.'),
        ),
      ),
    );
  }
}


