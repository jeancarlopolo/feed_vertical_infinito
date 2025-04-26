import 'package:feed_vertical_infinito/models/video.dart';
import 'package:feed_vertical_infinito/services/bsky_videos.dart';
import 'package:feed_vertical_infinito/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:get_it/get_it.dart';

class VideosFeed extends StatefulWidget {
  const VideosFeed({super.key});

  @override
  State<VideosFeed> createState() => _VideosFeedState();
}

class _VideosFeedState extends State<VideosFeed> {
  final BskyVideos _bskyVideos = GetIt.I<BskyVideos>();
  final PagingController<String?, Video> _pagingController = 
      PagingController<String?, Video>(firstPageKey: null);
  
  final PageController _pageController = PageController();
  int _currentVideoIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    
    // Ouvir mudanças de página
    _pageController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_pageController.hasClients && _pageController.page != null) {
      final newIndex = _pageController.page!.round();
      if (newIndex != _currentVideoIndex) {
        setState(() {
          _currentVideoIndex = newIndex;
        });
        
        // Pré-carregar mais vídeos quando chegar perto do final
        if (_pagingController.itemList != null && 
            newIndex >= _pagingController.itemList!.length - 3) {
          _checkForMoreItems();
        }
      }
    }
  }
  
  void _checkForMoreItems() {
    // Se há uma próxima página e não está carregando, solicita mais
    if (_pagingController.nextPageKey != null) {
      _pagingController.notifyPageRequestListeners(_pagingController.nextPageKey);
    }
  }
  
  Future<void> _fetchPage(String? pageKey) async {
    try {
      final result = await _bskyVideos.fetchPage(pageKey: pageKey);
      
      if (result.nextPageKey == null) {
        _pagingController.appendLastPage(result.items);
      } else {
        _pagingController.appendPage(result.items, result.nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }
  
  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pagingController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PagedListView<String?, Video>.separated(
        pagingController: _pagingController,
        scrollController: _pageController,
        scrollDirection: Axis.vertical,
        separatorBuilder: (context, index) => const SizedBox.shrink(),
        builderDelegate: PagedChildBuilderDelegate<Video>(
          itemBuilder: (context, video, index) {
            // Cada item ocupa toda a altura da tela
            return SizedBox(
              height: MediaQuery.of(context).size.height,
              child: VideoPlayerWidget(
                video: video,
                autoPlay: index == _currentVideoIndex,
              ),
            );
          },
          firstPageProgressIndicatorBuilder: (_) => SizedBox(
            height: MediaQuery.of(context).size.height,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          newPageProgressIndicatorBuilder: (_) => SizedBox(
            height: 50,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          noItemsFoundIndicatorBuilder: (_) => SizedBox(
            height: MediaQuery.of(context).size.height,
            child: const Center(
              child: Text(
                'Nenhum vídeo encontrado',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        physics: const PageScrollPhysics().applyTo(
          const AlwaysScrollableScrollPhysics(),
        ),
      ),
    );
  }
}