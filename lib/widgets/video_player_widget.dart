import 'package:feed_vertical_infinito/models/video.dart';
import 'package:feed_vertical_infinito/widgets/author_info.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:signals_flutter/signals_flutter.dart';

class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final bool autoPlay;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    this.autoPlay = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  final _isInitialized = signal(false);
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quando o autoPlay muda, atualize o estado de reprodução
    if (widget.autoPlay != oldWidget.autoPlay) {
      _updatePlayState();
    }
  }

  void _updatePlayState() {
    if (widget.autoPlay && _isInitialized.watch(context) && !_controller.value.isPlaying) {
      _controller.play();
      setState(() {
        _isPlaying = true;
      });
    } else if (!widget.autoPlay && _isInitialized.watch(context) && _controller.value.isPlaying) {
      _controller.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );

    await _controller.initialize();

    // Configurar para reprodução em loop
    await _controller.setLooping(true);

    // Iniciar reprodução com base no autoPlay
    if (widget.autoPlay) {
      await _controller.play();
      _isPlaying = true;
    }

    if (mounted) {
      _isInitialized.value = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized.watch(context)) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vídeo em tela cheia
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            left: 16,
            child: AuthorInfo(
              authorHandle: widget.video.authorHandle,
              authorDisplayName: widget.video.authorDisplayName,
              authorAvatar: widget.video.authorAvatar,
            ),
          ),

          // Ícone de play quando pausado
          if (!_isPlaying)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }
}
