import 'package:bluesky/bluesky.dart';
import 'package:feed_vertical_infinito/models/video.dart';
import 'package:get_it/get_it.dart';

class BskyVideos {
  late final Bluesky bluesky;

  // Cursor para paginação
  String? _cursor;
  bool _hasMoreVideos = true;

  // Limite de itens por página
  final int _limit = 3;

  BskyVideos() {
    init();
  }

  Future<void> init() async {
    // Obtém a instância do Bluesky do GetIt ou cria uma nova instância anônima
    try {
      bluesky = GetIt.instance<Bluesky>();
    } catch (_) {
      // Se não estiver registrado no GetIt, cria uma instância anônima
      bluesky = Bluesky.anonymous();
    }
  }

  /// Reseta o estado da paginação
  void resetPagination() {
    _cursor = null;
    _hasMoreVideos = true;
  }

  /// Verifica se há mais vídeos disponíveis
  bool get hasMoreVideos => _hasMoreVideos;

  /// Busca a próxima página de vídeos do feed
  ///
  /// Retorna uma lista de objetos [Video]
  /// A funcionalidade de paginação é controlada internamente através do cursor
  Future<List<Video>> fetchVideos() async {
    if (!_hasMoreVideos) {
      return [];
    }

    try {
      // Buscar o timeline de posts com filtro para obter apenas vídeos
      final getTimeline = await bluesky.feed.getTimeline(
        algorithm:
            'reverse-chronological', // algoritmo para ordenação (mais recentes primeiro)
        limit: _limit,
        cursor: _cursor,
      );

      // Atualiza o cursor para a próxima página
      _cursor = getTimeline.data.cursor;

      // Verifica se há mais vídeos disponíveis
      if (getTimeline.data.feed.isEmpty || getTimeline.data.cursor == null) {
        _hasMoreVideos = false;
      }

      // Filtra a timeline para obter apenas posts com vídeos
      final videoItems =
          getTimeline.data.feed.where((item) {
            // Converte o post para JSON para facilitar a verificação dos embeds
            final postJson = item.post.toJson();
            final embed = postJson['embed'];

            // Se não tem embed, não é um vídeo
            if (embed == null) {
              return false;
            }

            // Verifica o tipo de embed
            final embedType = embed[r'$type'] as String?;

            // Verifica se é um dos tipos que podem conter vídeo
            if (embedType?.contains('media') ?? false) {
              // Embeds de mídia podem conter vídeos
              final mediaItems = embed['media']?['items'] as List?;
              if (mediaItems != null && mediaItems.isNotEmpty) {
                return mediaItems.any(
                  (media) =>
                      (media['mimetype'] as String?)?.startsWith('video/') ??
                      false,
                );
              }
            }

            return false;
          }).toList();

      // Converte os itens em objetos Video
      return videoItems
          .map((item) => Video.fromJson({'post': item.post.toJson()}))
          .toList();
    } catch (e) {
      _hasMoreVideos = false;
      return [];
    }
  }

  /// Método específico para uso com infinite_scroll_pagination
  ///
  /// [pageKey] é o cursor para a próxima página
  /// [pageSize] é a quantidade de itens por página
  Future<PaginationResult> fetchPage({String? pageKey, int? pageSize}) async {
    // Se um pageKey foi fornecido, atualiza o cursor interno
    if (pageKey != null) {
      _cursor = pageKey;
    }

    // Se nenhum cursor for fornecido e não tivermos um, começa do início
    if (_cursor == null) {
      resetPagination();
    }

    // Busca os vídeos
    final videos = await fetchVideos();

    // Retorna os resultados formatados para uso com infinite_scroll_pagination
    return PaginationResult(
      items: videos,
      nextPageKey: _hasMoreVideos ? _cursor : null,
    );
  }
}

/// Classe auxiliar para retornar resultados paginados
class PaginationResult {
  final List<Video> items;
  final String? nextPageKey;

  PaginationResult({required this.items, this.nextPageKey});
}
