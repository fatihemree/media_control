import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/audio_player_viewmodel.dart';
import 'player_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Widget _buildAlbumArtThumbnail(String imageUrl, String songTitle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[850],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  strokeWidth: 2,
                ),
              ),
            ),
        errorWidget:
            (context, url, error) =>
                Container(color: Colors.grey[850], child: const Icon(Icons.album, color: Colors.white54, size: 30)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Your Library', style: TextStyle(color: Colors.white)),
          ),
          body: Column(
            children: [
              if (viewModel.error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(viewModel.error!, style: const TextStyle(color: Colors.red))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: viewModel.clearError),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: viewModel.songs.length,
                  itemBuilder: (context, index) {
                    final song = viewModel.songs[index];
                    final isPlaying = viewModel.currentSong?.id == song.id && viewModel.isPlaying;

                    return ListTile(
                      onTap: () {
                        viewModel.playSong(song);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerView()));
                      },
                      leading: Hero(
                        tag: 'album-art-${song.id}',
                        child: _buildAlbumArtThumbnail(song.albumArt, song.title),
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          color: isPlaying ? Colors.green : Colors.white,
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: TextStyle(
                          color: isPlaying ? Colors.green.withOpacity(0.7) : Colors.white.withOpacity(0.6),
                        ),
                      ),
                      trailing:
                          isPlaying
                              ? const Icon(Icons.equalizer, color: Colors.green)
                              : const Icon(Icons.play_arrow, color: Colors.white),
                    );
                  },
                ),
              ),
              if (viewModel.currentSong != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerView()));
                  },
                  child: Container(
                    height: 60,
                    color: Colors.grey[900],
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Hero(
                          tag: 'album-art-mini-${viewModel.currentSong!.id}',
                          child: _buildAlbumArtThumbnail(viewModel.currentSong!.albumArt, viewModel.currentSong!.title),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                viewModel.currentSong!.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                viewModel.currentSong!.artist,
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(viewModel.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            if (viewModel.isPlaying) {
                              viewModel.pause();
                            } else {
                              viewModel.play();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
