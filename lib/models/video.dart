class Video {
  final String id;
  final String authorHandle;
  final String authorDisplayName;
  final String authorAvatar;
  final String text;
  final String videoUrl;

  // Lista de extensões de vídeo comuns
  static const List<String> _videoExtensions = ['.mp4', '.mov', '.webm', '.avi', '.mkv', '.flv'];
  // Lista de hosts de vídeo conhecidos (incompleta, pode ser expandida)
  static const List<String> _videoHosts = ['youtube.com', 'youtu.be', 'vimeo.com'];

  Video({
    required this.id,
    required this.authorHandle,
    required this.authorDisplayName,
    this.authorAvatar = '',
    required this.text,
    required this.videoUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final post = json;
    final record = post['record'] ?? {};
    final author = post['author'] ?? {};
    final embed = record['embed'] ?? {};

    String videoUrl = '';
    final embedType = embed[r'$type'];
    final pdsHost = 'bsky.social'; // ATENÇÃO: Hardcoded! Idealmente dinâmico.

    if (embedType == 'app.bsky.embed.video') {
      final videoBlob = embed['video'];
      final authorDid = author['did'];
      final cid = videoBlob?['ref']?[r'$link'];

      if (authorDid != null && cid != null) {
        // Construir URL para o endpoint getBlob XRPC
        videoUrl = 'https://$pdsHost/xrpc/com.atproto.sync.getBlob?did=$authorDid&cid=$cid';
      } else {
        // print('WARN: app.bsky.embed.video sem did ou cid em post ${post['uri']}');
      }

    } else if (embedType == 'app.bsky.embed.external') {
      final uriString = embed['external']?['uri'] as String?;
      if (uriString != null) {
        try {
          final uri = Uri.parse(uriString);
          final host = uri.host.toLowerCase();
          final path = uri.path.toLowerCase();

          bool isKnownHost = _videoHosts.any((videoHost) => host.contains(videoHost));
          bool hasVideoExtension = _videoExtensions.any((ext) => path.endsWith(ext));

          if (isKnownHost || hasVideoExtension) {
            videoUrl = uriString;
          }
        } catch (e) {
          // Ignorar URIs inválidas
        }
      }
    } 
    // Adicionar mais `else if` aqui para outros tipos de embed se necessário (ex: record_with_media)
    // A lógica anterior para embed.media e embed.images foi removida pois gerava URLs de thumbnail

    return Video(
      id: post['uri'] ?? '', // Usar uri como ID único
      authorHandle: author['handle'] ?? '',
      authorDisplayName: author['displayName'] ?? '',
      authorAvatar: author['avatar'] ?? '',
      text: record['text'] ?? '',
      videoUrl: videoUrl, // Será vazio se nenhum vídeo válido foi encontrado
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorHandle': authorHandle,
      'authorDisplayName': authorDisplayName,
      'authorAvatar': authorAvatar,
      'text': text,
      'videoUrl': videoUrl,
    };
  }
}
