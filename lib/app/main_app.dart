import 'package:feed_vertical_infinito/app/main.dart';
import 'package:feed_vertical_infinito/models/video.dart';
import 'package:feed_vertical_infinito/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feed_vertical_infinito/services/bsky_videos.dart';
import 'package:feed_vertical_infinito/pages/feed.dart';
import 'package:get_it/get_it.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  BskyVideos bskyVideos = GetIt.instance<BskyVideos>();
  List<Video>? _initialVideos; // Armazena os vídeos iniciais ou null se estiver carregando
  bool _isLoading = true;
  bool _hasError = false;



  @override
  void initState() {
    super.initState();
    _fetchInitialVideos();
  }

  Future<void> _fetchInitialVideos() async {
    try {
      final bskyVideos = GetIt.instance<BskyVideos>();
      final videos = await bskyVideos.fetchVideos();
      if (!mounted) return; // Verifica se o widget ainda está na árvore
      setState(() {
        _initialVideos = videos;
        _isLoading = false;
        _hasError = videos.isEmpty; // Considera erro se a lista inicial estiver vazia
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      // Exibe a SplashScreen enquanto carrega
      return const SplashScreen();
    }

    if (_hasError || _initialVideos == null || _initialVideos!.isEmpty) {
      // Exibe uma mensagem de erro se algo deu errado ou não há vídeos
      return const ErrorApp(); // Reutiliza o ErrorApp ou cria uma tela de erro específica
    }

    // Bloquear orientação para retrato apenas
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Deixar a barra de status transparente para melhor experiência visual
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluesky Reels',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: Feed(videos: _initialVideos!),
    );
  }
}
