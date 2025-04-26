import 'package:feed_vertical_infinito/pages/videos_feed.dart';
import 'package:flutter/material.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluesky Reels',
      home: const VideosFeed(),
    );
  }
}
