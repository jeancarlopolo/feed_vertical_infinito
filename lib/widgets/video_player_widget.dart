import 'package:feed_vertical_infinito/models/video.dart';
import 'package:feed_vertical_infinito/widgets/author_info.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:logging/logging.dart';

class VideoPlayerWidget extends StatefulWidget {
  final ChewieController chewieController;
  final Video video;
  final bool lazyLoad;
  final int maxBufferSize;

  /// Widget que reproduz vídeos usando Chewie com otimizações para vídeos grandes
  /// 
  /// [chewieController] - O controller do Chewie para reprodução de vídeo
  /// [video] - O modelo de vídeo com informações para exibição
  /// [lazyLoad] - Se true, apenas carrega o vídeo quando o widget se torna visível
  /// [maxBufferSize] - Tamanho máximo do buffer em bytes (defaults para 10MB)
  const VideoPlayerWidget({
    super.key,
    required this.chewieController,
    required this.video,
    this.lazyLoad = true,
    this.maxBufferSize = 10 * 1024 * 1024, // 10MB default
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> with WidgetsBindingObserver {
  final Logger _logger = Logger('VideoPlayerWidget');
  bool _isPlaying = true;
  bool _isTapping = false;
  bool _isBuffering = false;
  bool _isInitialized = false;
  bool _isVisible = false;
  double _bufferingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _logger.info('VideoPlayerWidget initialized for video: ${widget.video.id}');
    
    // Registre o observador para detectar quando o app está em segundo plano
    WidgetsBinding.instance.addObserver(this);
    
    if (!widget.lazyLoad) {
      _initializePlayer();
    }
  }

  /// Inicializa o player com configurações otimizadas para vídeos grandes
  void _initializePlayer() {
    if (_isInitialized) return;
    
    _logger.info('Initializing player for video: ${widget.video.id}');
    setState(() => _isBuffering = true);
    
    // Configure o buffer máximo conforme definido
    try {
      final controller = widget.chewieController.videoPlayerController;
      
      // Configurações de otimização (se suportado pelo dispositivo)
      controller.setPlaybackSpeed(1.0);
      
      // Adiciona listeners para monitorar o estado de reprodução e buffering
      controller.addListener(_updatePlayingState);
      controller.addListener(_updateBufferingState);
      
      setState(() {
        _isInitialized = true;
        _isBuffering = false;
      });
    } catch (e) {
      _logger.severe('Error initializing player: $e');
      setState(() => _isBuffering = false);
    }
  }
  
  /// Monitora o progresso de buffering do vídeo
  void _updateBufferingState() {
    if (!mounted) return;
    
    final controller = widget.chewieController.videoPlayerController;
    final value = controller.value;
    
    // Monitora o buffering
    final isBuffering = value.isBuffering;
    final bufferingProgress = value.buffered.isNotEmpty ? 
        value.buffered.last.end.inMilliseconds / value.duration.inMilliseconds : 
        0.0;
    
    // Atualiza o estado apenas se houver mudança
    if (isBuffering != _isBuffering || 
        (bufferingProgress - _bufferingProgress).abs() > 0.01) {
      setState(() {
        _isBuffering = isBuffering;
        _bufferingProgress = bufferingProgress;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkVisibility();
  }

  /// Monitora mudanças de ciclo de vida da aplicação
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pausa o vídeo quando o app está em segundo plano
    if (state == AppLifecycleState.paused) {
      if (_isPlaying) {
        widget.chewieController.pause();
      }
    }
  }

  /// Verifica se o widget está visível e inicia o player se necessário
  void _checkVisibility() {
    if (widget.lazyLoad && !_isInitialized) {
      _initializePlayer();
      setState(() => _isVisible = true);
    }
  }

  @override
  void dispose() {
    _logger.info('VideoPlayerWidget disposed for video: ${widget.video.id}');
    // Remove os listeners para evitar vazamentos de memória
    final controller = widget.chewieController.videoPlayerController;
    controller.removeListener(_updatePlayingState);
    controller.removeListener(_updateBufferingState);
    
    // Remove o observer de ciclo de vida
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  void _updatePlayingState() {
    // Only update state if mounted and playing state changed
    if (mounted) {
      final isPlaying = widget.chewieController.videoPlayerController.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    }
  }

  void _togglePlayPause() {
    // Prevent multiple rapid taps from causing issues
    if (_isTapping) return;

    _isTapping = true;
    _logger.info('Toggle play/pause state. Current state: $_isPlaying');

    if (_isPlaying) {
      widget.chewieController.pause();
    } else {
      widget.chewieController.play();
    }

    // Reset the tap lock after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _isTapping = false;
      }
    });
  }

  /// Usa um Visibility widget para controlar o carregamento do player
  Widget _buildVideoPlayer() {
    // Usa Visibility para lazy loading
    return Visibility(
      // Sempre mantém o widget na árvore, mas só constrói quando visível
      maintainState: true,
      visible: _isVisible,
      replacement: const Center(child: CircularProgressIndicator()),
      child: AspectRatio(
        aspectRatio: MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
        child: Chewie(
          controller: widget.chewieController,
        ),
      ),
    );
  }

  /// Constrói o indicador de progresso de buffering
  Widget _buildBufferingIndicator() {
    return AnimatedOpacity(
      opacity: _isBuffering ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (_bufferingProgress > 0)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${(_bufferingProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verifica visibilidade ao construir
    if (!_isVisible && widget.lazyLoad) {
      // Configura a visibilidade após o primeiro frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkVisibility();
      });
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player filling the entire screen com lazy loading
          _buildVideoPlayer(),
          
          // Indicador de buffering
          _buildBufferingIndicator(),
          
          // Author information overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: AuthorInfo(
              authorHandle: widget.video.authorHandle,
              authorDisplayName: widget.video.authorDisplayName,
              authorAvatar: widget.video.authorAvatar,
            ),
          ),

          // Play icon overlay when video is paused
          if (!_isPlaying && !_isBuffering)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withAlpha(128),
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
        ],
      ),
    );
  }
}