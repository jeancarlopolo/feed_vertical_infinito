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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Bloquear orientação para retrato apenas
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
      home: Feed(),
    );
  }
}
