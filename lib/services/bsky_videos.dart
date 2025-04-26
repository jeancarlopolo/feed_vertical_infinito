import 'package:atproto_core/atproto_core.dart' hide Response;
import 'package:bluesky/bluesky.dart';
import 'package:feed_vertical_infinito/models/video.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

class BskyVideos {
  final Bluesky bluesky = GetIt.instance<Bluesky>();
  final _logger = Logger('BskyVideos');

  // Voltando para a URI original (com DID) do feed "The Vids"
  final String _popularFeedUriString = 'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/thevids';

  // Cursor para paginação
  String? _cursor;
  bool _hasMoreVideos = true;

  // Limite de itens por página
  final int _limit = 10;

  BskyVideos();

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
    _logger.info('>>> MÉTODO fetchVideos CHAMADO <<<');
    if (!_hasMoreVideos) {
      _logger.info('fetchVideos: _hasMoreVideos é false, retornando lista vazia.');
      return [];
    }

    _logger.info('Buscando feed popular ($_popularFeedUriString)... Cursor: $_cursor, Limite: $_limit');

    try {
      final response = await bluesky.feed.getFeed(
        generatorUri: AtUri.parse(_popularFeedUriString),
        limit: _limit,
        cursor: _cursor,
      );

      if (response.data.feed.isEmpty) {
        _logger.info('Nenhum post encontrado na resposta.');
        _hasMoreVideos = false;
        return [];
      }

      final List<Video> videos = [];
      for (final item in response.data.feed) {
        // Logar o embed completo para depuração
        final postJson = item.post.toJson();
        final embedData = postJson['record']?['embed'];
        _logger.info('Post URI: ${item.post.uri} - Embed Data: $embedData');

        // Tenta criar um objeto Video a partir do post
        try {
          final video = Video.fromJson(postJson);
          if (video.videoUrl.isNotEmpty) {
            _logger.info('>>> Vídeo VÁLIDO encontrado: ${video.videoUrl}');
            videos.add(video);
          }
        } catch (e) {
          _logger.warning('Erro ao processar post ${item.post.uri}: $e');
        }
      }

      _cursor = response.data.cursor;
      _hasMoreVideos = _cursor != null && _cursor!.isNotEmpty;

      _logger.info('Busca concluída. ${videos.length} vídeos encontrados. Próximo cursor: $_cursor. Há mais vídeos: $_hasMoreVideos');

      return videos;

    } on XRPCException catch (e) {
      _logger.severe('Erro na API Bluesky ao buscar feed ($_popularFeedUriString): ${e.toString()}');
      _hasMoreVideos = false;
      return [];
    } catch (e) {
      _logger.severe('Erro inesperado ao buscar vídeos: $e');
      _hasMoreVideos = false;
      return [];
    }
  }

  /// Método específico para uso com infinite_scroll_pagination
  ///
  /// [pageKey] é o cursor para a próxima página
  /// [pageSize] é a quantidade de itens por página
  Future<PaginationResult> fetchPage({String? pageKey, int? pageSize}) async {
    _logger.info('>>> MÉTODO fetchPage CHAMADO - pageKey: $pageKey, pageSize: $pageSize <<<');
    // Se um pageKey foi fornecido, atualiza o cursor interno
    if (pageKey != null) {
      _logger.info('fetchPage: Atualizando cursor interno para $pageKey');
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
