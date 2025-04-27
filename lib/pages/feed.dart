import 'dart:async';
import 'dart:io';

import 'package:feed_vertical_infinito/models/video.dart';
import 'package:feed_vertical_infinito/pages/splash_screen.dart';
import 'package:feed_vertical_infinito/services/bsky_videos.dart';
import 'package:feed_vertical_infinito/utils/queue.dart';
import 'package:feed_vertical_infinito/widgets/my_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:signals_flutter/signals_flutter.dart';

class Feed extends StatefulWidget {
  final List<Video> videos;

  const Feed({super.key, required this.videos});

  @override
  FeedState createState() => FeedState();
}

class FeedState extends State<Feed> {
  // logger pra debugar
  final _logger = Logger('Feed');
  // cache manager pra baixar e cachear vídeos
  final _cacheManager = GetIt.instance<CacheManager>();
  // serviço pra buscar vídeos na api
  BskyVideos bskyVideos = GetIt.instance<BskyVideos>();
  // flag pra evitar mais de uma requisição de vídeos ao mesmo tempo
  bool fetchingMoreVideos = false;
  // lista de vídeos já baixados e cacheados
  final List<File> cachedVideos = [];
  // lista de widgets de vídeo
  // páginas distantes tomam dispose e viram SizedBox
  final ListSignal<Widget> pages = ListSignal([]);
  final pagesLength = signal(0);
  // página atual
  int currentPage = 0;
  // a fila precisa se adaptar dependendo da direção do scroll
  // USUÁRIO DESCENDO: vídeo de cima é empilhado no topo da queue de anteriores e a fila de seguintes é dequeuada
  // USUÁRIO SUBINDO: vídeo de baixo é empilhado na fila de seguintes e a pilha de anteriores é desempilhada
  // VÍDEOS NOVOS DA API: são enfileirados na fila de seguintes
  // por indução, só vai existir três vídeos na lista de páginas
  Queue<File> previousVideos = Queue<File>();
  Queue<File> nextVideos = Queue<File>();
  // controller pra controlar as páginas
  PageController pageController = PageController();

  // flag pro caso em que o usuário chegou no final da lista de vídeos sem cachear mais vídeos
  final missingNextPage = signal(false);

  @override
  void initState() {
    super.initState();
    _fetchMoreVideos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void move(int oldIndex, int newIndex) async {
    // descendo
    if (oldIndex < newIndex) {
      // se estiverem acabando vídeos, começar a buscar mais
      if (nextVideos.length < 10 && !fetchingMoreVideos) {
        Future.microtask(() => _fetchMoreVideos());
      }
      // se não for o primeiro vídeo, empilhar o antigo anterior no topo da pilha de anteriores
      if (oldIndex != 0) {
        previousVideos.enqueueHead(cachedVideos[oldIndex - 1]);
        pages[oldIndex - 1] = SizedBox();
      }
      if (newIndex + 1 > pagesLength.value) {
        missingNextPage.value = true;
      } else {
        // criar a página do vídeo seguinte
        pages[newIndex + 1] = MyVideoPlayer(
          UniqueKey(),
          file: nextVideos.dequeueHead(),
          videoData: widget.videos[newIndex + 1],
        );
      }
      setState(() {});
    }
    // subindo
    else if (oldIndex > newIndex) {
      // se não for o primeiro vídeo, vai ter mais vídeos na fila de anteriores, então cria uma página de vídeo anterior
      if (newIndex != 0) {
        pages[newIndex - 1] = MyVideoPlayer(
          UniqueKey(),
          file: previousVideos.dequeueHead(),
          videoData: widget.videos[newIndex - 1],
        );
      }
      // empilhar o antigo vídeo seguinte na fila de seguintes
      nextVideos.enqueueHead(cachedVideos[oldIndex + 1]);
      pages[oldIndex + 1] = SizedBox();
    }
    _logger.info('previousVideos: ${previousVideos.toString()}');
    _logger.info('nextVideos: ${nextVideos.toString()}');
  }

  void _createInitialPages() {
    pages.add(
      MyVideoPlayer(
        UniqueKey(),
        file: cachedVideos[0],
        videoData: widget.videos[0],
      ),
    );
    pages.add(
      MyVideoPlayer(
        UniqueKey(),
        file: cachedVideos[1],
        videoData: widget.videos[1],
      ),
    );
    pagesLength.value = pages.length;
  }
  int completed = 0;

  Future<void> _downloadAndCacheVideos(List<Video> apiVideos) async {
    fetchingMoreVideos = true;
    _logger.info('Downloading and caching videos');
    apiVideos.asMap().forEach((index, video) async {
      // pra cada vídeo da api, baixar e cachear
      // os mais leves acabam sendo cacheados primeiro por conta do microtask
      Future.microtask(() async {
        cachedVideos.add(await _cacheManager.getSingleFile(video.videoUrl));
        nextVideos.enqueueTail(cachedVideos.last);
        _logger.info('nextVideos: ${nextVideos.toString()}');
        completed++;
        if (missingNextPage.value) {
          missingNextPage.value = false;
        }
        if (completed == 2) {
          // se já baixou 2 vídeos, pode criar as páginas iniciais
          _createInitialPages();
        } else if (completed > 2) {
          pages.add(SizedBox());
          pagesLength.value = pages.length;
        }
        _logger.info('$completed completed $index finished loading');
        if (completed == apiVideos.length) {
          fetchingMoreVideos = false;
        }
      });
    });
  }

  Future<void> _fetchMoreVideos() async {
    _logger.info('Fetching more videos');
    try {
      final newVideos = await bskyVideos.fetchVideos();
      _logger.info('Fetched ${newVideos.length} new videos');
      _downloadAndCacheVideos(newVideos);
    } catch (e) {
      _logger.severe('Error fetching more videos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return pages.watch(context).isEmpty
        ? SplashScreen()
        : PageView.builder(
          pageSnapping: true,
          scrollDirection: Axis.vertical,
          controller: pageController,
          physics: const PageScrollPhysics(),
          onPageChanged: (index) {
            move(currentPage, index);
            currentPage = index;
          },
          itemCount: pagesLength.watch(context),
          itemBuilder: (context, index) {
            if (missingNextPage.watch(context)) {
              return Stack(
                children: [
                  pages.watch(context)[index],
                  Positioned(
                    bottom: 0,
                    child: Column(
                      children: [
                        Text('Carregando mais vídeos...'),
                        CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ],
              );
            }
            return pages.watch(context)[index];
          },
        );
  }
}
