import 'dart:io' as io;
import 'package:atproto_core/atproto_core.dart' hide Response;
import 'package:bluesky/bluesky.dart';
import 'package:feed_vertical_infinito/models/video.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

class BskyVideos {
  final Bluesky bluesky = GetIt.instance<Bluesky>();
  final _logger = Logger('BskyVideos');

  // Feed URI
  final String _popularFeedUriString =
      'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/thevids';

  // Pagination
  String? _cursor;
  bool _hasMoreVideos = true;
  final int _limit = 20;

  static const List<String> _compatibleFormats = [
    'video/mp4',
    'video/quicktime', // .mov
    'video/3gpp', // .3gp
  ];

  static const List<String> _androidOnlyFormats = [
    'video/webm',
    'video/x-matroska', // .mkv
  ];

  // Formats known to be problematic or less common in mobile apps
  static const List<String> _problematicFormats = [
    'video/x-msvideo', // .avi
    'video/divx',
    'video/x-flv', // .flv
    'video/mpeg',
  ];

  /// Checks if the video format is likely compatible with the current platform.
  /// This is a relaxed check, prioritizing common mobile formats.
  bool _isFormatCompatible(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) {
      _logger.warning('Skipping video due to missing mimeType');
      return false;
    }

    final lowerMimeType = mimeType.toLowerCase();
    _logger.info('Checking format compatibility for: $lowerMimeType');

    // 1. Reject known problematic formats first
    if (_problematicFormats.any((format) => lowerMimeType.contains(format))) {
      _logger.warning('Rejecting known problematic format: $lowerMimeType');
      return false;
    }

    // 2. Allow generally compatible formats (includes MP4/MOV which use AVC)
    if (_compatibleFormats.any((format) => lowerMimeType.contains(format))) {
      _logger.info('Allowing generally compatible format: $lowerMimeType');
      return true;
    }

    // 3. Allow Android-specific formats if on Android
    if (io.Platform.isAndroid) {
      if (_androidOnlyFormats.any((format) => lowerMimeType.contains(format))) {
        _logger.info('Allowing Android-specific format: $lowerMimeType');
        return true;
      }
    }

    // 4. If it didn't match any allowed rule, skip it.
    _logger.warning('Skipping format not explicitly allowed: $lowerMimeType');
    return false;
  }

  BskyVideos();

  void resetPagination() {
    _cursor = null;
    _hasMoreVideos = true;
  }

  bool get hasMoreVideos => _hasMoreVideos;

  Future<List<Video>> fetchVideos() async {
    if (!_hasMoreVideos) return [];

    try {
      final response = await bluesky.feed.getFeed(
        generatorUri: AtUri.parse(_popularFeedUriString),
        limit: _limit,
        cursor: _cursor,
      );

      if (response.data.feed.isEmpty) {
        _hasMoreVideos = false;
        return [];
      }

      final List<Video> videos = [];
      for (final item in response.data.feed) {
        final postJson = item.post.toJson();
        final mimeType =
            postJson['record']?['embed']?['video']?['mimeType'] as String?;

        // Use the relaxed compatibility check
        if (!_isFormatCompatible(mimeType)) {
          // Se o formato não for compatível, simplesmente pule para o próximo item.
          continue; // Pula para o próximo item do loop
        }

        // Se o formato for compatível, tente criar o Video
        try {
          final video = Video.fromJson(postJson);
          if (video.videoUrl.isNotEmpty) {
            videos.add(video);
          }
        } catch (e, stackTrace) {
          _logger.severe(
            'Error processing post ${item.post.uri}: $e\nStack trace: $stackTrace',
          );
          // Não continue ou retorne aqui, apenas logue o erro e prossiga com outros itens.
        }
      } // Fim do Loop

      _cursor = response.data.cursor;
      _hasMoreVideos = _cursor != null && _cursor!.isNotEmpty;
      _logger.info(
        'Returning ${videos.length} videos. New cursor: ${_cursor != null}',
      );
      return videos;
    } on XRPCException catch (e, stackTrace) {
      _logger.severe(
        'API error when fetching from Bluesky: $e\nStack trace: $stackTrace',
      );
      _hasMoreVideos = false;
      return [];
    } catch (e, stackTrace) {
      _logger.severe(
        'Unexpected error fetching videos: $e\nStack trace: $stackTrace',
      );
      _hasMoreVideos = false;
      return [];
    }
  }
}
