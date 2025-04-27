import 'package:feed_vertical_infinito/app/main_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:bluesky/bluesky.dart' hide Feed;
import 'package:atproto/atproto.dart';
import 'package:atproto_core/atproto_core.dart' hide Response;
import 'package:logging/logging.dart';
import '../services/bsky_videos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupApp();
}

Future<void> setupApp() async {
  // Configurar apenas logs essenciais (INFO e acima)
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('meulog ${record.time}: ${record.loggerName}: ${record.message}');
  });

  // devido ao feed vids não ser público, ATProto.anonymous não funciona
  // então usamos credenciais de uma conta autenticada
  // essa conta foi criada especialmente para esse propósito com um email temporário
  const String handle = 'contaautenticadora.bsky.social';
  const String appPassword = 'bbnj-5icx-bj5e-3tbo';

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
    await setup(session.data);

    // Configurar a orientação do dispositivo para retrato
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Configurar a UI do sistema para melhor aparência
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    runApp(const MainApp());
  } catch (e) {
    // ignore: avoid_print
    print('Erro fatal durante a autenticação inicial: $e');
    runApp(const ErrorApp());
  }
}

// Registra instâncias no GetIt
Future<void> setup(Session sessionData) async {
  // Registrar Bluesky autenticado
  GetIt.instance.registerSingleton<Bluesky>(Bluesky.fromSession(sessionData));
  GetIt.instance.registerSingleton<BskyVideos>(BskyVideos());
  GetIt.instance.registerSingleton<CacheManager>(
    CacheManager(
      Config(
        "BSKY_REELS_CACHE",
        stalePeriod: const Duration(
          hours: 1,
        ), // Tempo que um arquivo é considerado "novo"
        maxNrOfCacheObjects: 50, // Limite máximo de arquivos no cache
        repo: JsonCacheInfoRepository(
          databaseName: "BSKY_REELS_CACHE",
        ), // Gerencia informações do cache
        fileService: HttpFileService(), // Serviço para baixar arquivos via HTTP
      ),
    ),
  );
}

// Widget simples para exibir erro de inicialização
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Erro ao iniciar. Verifique as credenciais e a conexão.'),
        ),
      ),
    );
  }
}

