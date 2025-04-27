import 'dart:async';
import 'dart:io';

import 'package:feed_vertical_infinito/models/video.dart';
import 'package:feed_vertical_infinito/pages/splash_screen.dart';
import 'package:feed_vertical_infinito/services/bsky_videos.dart';
import 'package:feed_vertical_infinito/utils/queue.dart';
import 'package:feed_vertical_infinito/widgets/my_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:signals_flutter/signals_flutter.dart';

class FileVideo {
  final File file;
  final Video video;

  FileVideo({required this.file, required this.video});
}

class Feed extends StatefulWidget {
  const Feed({super.key});

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
  final List<File> cachedVideoFiles = [];
  final List<Video> cachedVideos = [];
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
  Queue<FileVideo> previousVideos = Queue<FileVideo>();
  Queue<FileVideo> nextVideos = Queue<FileVideo>();
  // controller pra controlar as páginas
  PageController pageController = PageController();

  // flag pro caso em que o usuário chegou no final da lista de vídeos sem cachear mais vídeos
  final missingNextPage = signal(false);
  bool wasMissingNextPage = false;

  @override
  void initState() {
    super.initState();
    _fetchMoreVideos();
    missingNextPage.subscribe((value) {
      if (value) {
        Fluttertoast.showToast(
          msg: "Carregando mais vídeos...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black.withAlpha(128),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        wasMissingNextPage = true;
      } else {
        Fluttertoast.cancel();
        if (wasMissingNextPage) {
          if (completed > pages.length) {
            wasMissingNextPage = false;
          } else {
            missingNextPage.value = true;
          }
        }
      }
    });
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
        _fetchMoreVideos();
      }
      // se não for o primeiro vídeo, empilhar o antigo anterior no topo da pilha de anteriores
      if (oldIndex != 0) {
        previousVideos.enqueueHead(
          FileVideo(
            file: cachedVideoFiles[oldIndex - 1],
            video: cachedVideos[oldIndex - 1],
          ),
        );
        pages.internalValue[oldIndex - 1] = SizedBox();
      }
      // próximo vídeo não existe, então vai ter que carregar mais
      if (newIndex + 1 > pages.length || nextVideos.isEmpty()) {
        missingNextPage.value = true;
      } else {
        try {
          // criar a página do vídeo seguinte
          FileVideo fileVideo = nextVideos.dequeueHead();
          pages.internalValue[newIndex + 1] = MyVideoPlayer(
            UniqueKey(),
            file: fileVideo.file,
            videoData: fileVideo.video,
          );
          pagesLength.value = pages.length;
        } catch (e) {
          _logger.severe('Error creating next page: $e');
          _logger.severe('pages.length: ${pages.length}');
          _logger.severe('cachedVideos.length: ${cachedVideoFiles.length}');
          _logger.severe('newIndex: $newIndex');
        }
      }
      setState(() {});
    }
    // subindo
    else if (oldIndex > newIndex) {
      // se não for o primeiro vídeo, vai ter mais vídeos na fila de anteriores, então cria uma página de vídeo anterior
      if (newIndex != 0) {
        FileVideo fileVideo = previousVideos.dequeueHead();
        pages[newIndex - 1] = MyVideoPlayer(
          UniqueKey(),
          file: fileVideo.file,
          videoData: fileVideo.video,
        );
      }
      try {
        // empilhar o antigo vídeo seguinte na fila de seguintes
        if (oldIndex + 1 < pages.length) {
          nextVideos.enqueueHead(
            FileVideo(
              file: cachedVideoFiles[oldIndex + 1],
              video: cachedVideos[oldIndex + 1],
            ),
          );
          pages[oldIndex + 1] = SizedBox();
        }
      } catch (e) {
        _logger.severe('Error moving video: $e');
        _logger.severe('oldIndex: $oldIndex');
        _logger.severe('newIndex: $newIndex');
        _logger.severe('pages.length: ${pages.length}');
        _logger.severe('cachedVideos.length: ${cachedVideoFiles.length}');
      }
    }
    _logger.info('previousVideos: ${previousVideos.toString()}');
    _logger.info('nextVideos: ${nextVideos.toString()}');
  }

  void _createInitialPages() {
    pages.add(
      MyVideoPlayer(
        UniqueKey(),
        file: cachedVideoFiles[0],
        videoData: cachedVideos[0],
      ),
    );
    pages.add(
      MyVideoPlayer(
        UniqueKey(),
        file: cachedVideoFiles[1],
        videoData: cachedVideos[1],
      ),
    );
    pagesLength.value = pages.length;
  }

  int completed = 0;

  Future<void> _downloadAndCacheVideos(List<Video> apiVideos) async {
    fetchingMoreVideos = true;
    var completedThisFetch = 0;
    _logger.info('Downloading and caching videos');
    apiVideos.asMap().forEach((index, video) async {
      // pra cada vídeo da api, baixar e cachear
      // os mais leves acabam sendo cacheados primeiro por conta do microtask
      try {
        Future.microtask(() async {
          File file = await _cacheManager.getSingleFile(video.videoUrl);
          cachedVideoFiles.add(file);
          cachedVideos.add(video);
          completed++;
          completedThisFetch++;

          if (missingNextPage.value) {
            missingNextPage.value = false;
          }
          if (completed == 2) {
            // se já baixou 2 vídeos, pode criar as páginas iniciais
            _createInitialPages();
          } else if (completed > 2) {
            // usuário está parado na última página esperando carregar mais vídeos
            if (pages[pages.length - 1] is MyVideoPlayer &&
                MyVideoPlayer.totalVideoPages < 3 &&
                pages.length > 2) {
              pages.add(
                MyVideoPlayer(UniqueKey(), file: file, videoData: video),
              );
            } else {
              pages.add(SizedBox());
              nextVideos.enqueueTail(FileVideo(file: file, video: video));
            }
            pagesLength.value = pages.length;
          }
          _logger.info('$completedThisFetch/$completed completed: $indexº finished loading');
          if (completedThisFetch == 10) {
            fetchingMoreVideos = false;
          }
        });
      } catch (e) {
        _logger.severe('Error downloading and caching video: $e');
        completed++;
        completedThisFetch++;
      }
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
            move(currentPage.round(), index.round());
            currentPage = index.round();
            pagesLength.value = pages.length;
          },
          itemCount: pagesLength.watch(context),
          itemBuilder: (context, index) {
            if (pages.watch(context)[index] is SizedBox) {
              _logger.info('SizedBox at $index');
            }
            return pages.watch(context)[index];
          },
        );
  }
}
