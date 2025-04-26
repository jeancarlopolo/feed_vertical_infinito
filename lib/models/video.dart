class Video {
  final String id;
  final String authorHandle;
  final String authorDisplayName;
  final String authorAvatar;
  final String text;
  final String videoUrl;

  Video({
    required this.id,
    required this.authorHandle,
    required this.authorDisplayName,
    this.authorAvatar = '',
    required this.text,
    required this.videoUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final post = json['post'] ?? json;
    final record = post['record'] ?? {};
    final author = post['author'] ?? {};
    final embed = record['embed'] ?? {};
    
    // Tentando obter a URL do vídeo dos diferentes campos possíveis da API
    String videoUrl = '';
    if (embed[r'$type'] == 'app.bsky.embed.external' && embed['external']?['uri'] != null) {
      videoUrl = embed['external']['uri'];
    } else if (embed[r'$type'] == 'app.bsky.embed.media' && 
               embed['media']?['items']?.isNotEmpty == true &&
               embed['media']['items'][0]?['blob']?['ref'] != null) {
      final blob = embed['media']['items'][0]['blob'];
      final cid = blob['ref'][r'$link'] ?? '';
      videoUrl = 'https://cdn.bsky.app/img/feed_thumbnail/plain/${post['author']['did']}/$cid@jpeg';
    } else if (embed[r'$type'] == 'app.bsky.embed.images' && 
              embed['images']?.isNotEmpty == true &&
              embed['images'][0]?['image']?['ref'] != null) {
      final blob = embed['images'][0]['image'];
      final cid = blob['ref'][r'$link'] ?? '';
      videoUrl = 'https://cdn.bsky.app/img/feed_thumbnail/plain/${post['author']['did']}/$cid@jpeg';
    }

    return Video(
      id: post['id'] ?? '',
      authorHandle: author['handle'] ?? '',
      authorDisplayName: author['displayName'] ?? '',
      authorAvatar: author['avatar'] ?? '',
      text: record['text'] ?? '',
      videoUrl: videoUrl,
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
