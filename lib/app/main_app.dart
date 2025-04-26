import 'package:flutter/material.dart';
import '../pages/video_feed_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluesky Reels',
      home: const VideoFeedPage(),
    );
  }
}
