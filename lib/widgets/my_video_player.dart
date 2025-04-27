import 'dart:io';

import 'package:feed_vertical_infinito/models/video.dart';
import 'package:feed_vertical_infinito/widgets/author_info.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyVideoPlayer extends StatefulWidget {
  final UniqueKey uniqueKey;
  MyVideoPlayer(
    this.uniqueKey, {
    required this.file,
    required this.videoData,
  }) : super(key: uniqueKey) {
    totalVideoPages++;
  }
  final File file;
  final Video videoData;
  static int totalVideoPages = 0;

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    _videoController = VideoPlayerController.file(widget.file);
    _videoController.initialize().then((_) {
      setState(() {});
      _videoController.play();
      _videoController.setLooping(true);
    });
    super.initState();
  }

  @override
  void dispose() {
    _videoController.dispose();
    MyVideoPlayer.totalVideoPages--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _videoController.value.isPlaying;
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                isPlaying
                    ? _videoController.pause()
                    : _videoController.play();
              });
            },
          ),
        ),
        isPlaying
            ? const SizedBox.shrink()
            : const Icon(Icons.play_arrow, color: Colors.white70, size: 60),
        Positioned(
          left: 16,
          bottom: 30,
          right: 16,
          child: AuthorInfo(
            authorHandle: widget.videoData.authorHandle,
            authorDisplayName: widget.videoData.authorDisplayName,
            authorAvatar: widget.videoData.authorAvatar,
          ),
        ),
      ],
    );
  }
}
