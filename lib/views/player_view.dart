import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/audio_player_viewmodel.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  Widget _buildAlbumArt(String imageUrl, String songTitle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                color: Colors.grey[850],
                child: const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
                ),
              ),
          errorWidget:
              (context, url, error) => Container(
                color: Colors.grey[850],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.album, color: Colors.white54, size: 72),
                    const SizedBox(height: 8),
                    Text(
                      songTitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, AudioPlayerViewModel viewModel) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: Colors.green,
        inactiveTrackColor: Colors.grey[800],
        thumbColor: Colors.white,
        overlayColor: Colors.green.withOpacity(0.2),
      ),
      child: Slider(
        value: viewModel.position.inMilliseconds.toDouble().clamp(0, viewModel.duration.inMilliseconds.toDouble()),
        min: 0,
        max: viewModel.duration.inMilliseconds.toDouble(),
        onChangeStart: (_) {
          viewModel.seekStart();
        },
        onChanged: (value) {
          viewModel.seek(Duration(milliseconds: value.toInt()));
        },
        onChangeEnd: (_) {
          viewModel.seekEnd();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerViewModel>(
      builder: (context, viewModel, child) {
        final song = viewModel.currentSong;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and song title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('NOW PLAYING', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
                    ],
                  ),

                  if (viewModel.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(viewModel.error!, style: const TextStyle(color: Colors.red))),
                          IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: viewModel.clearError),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  if (song != null) ...[
                    Expanded(
                      child: Center(
                        child: Hero(tag: 'album-art-${song.id}', child: _buildAlbumArt(song.albumArt, song.title)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      song.title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(song.artist, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),

                    const SizedBox(height: 20),

                    _buildSlider(context, viewModel),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(viewModel.position),
                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                          ),
                          Text(
                            _formatDuration(viewModel.duration),
                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shuffle, color: viewModel.isShuffleEnabled ? Colors.green : Colors.white),
                          onPressed: () => viewModel.toggleShuffle(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 35),
                          onPressed: () => viewModel.playPrevious(),
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                          child: IconButton(
                            icon: Icon(
                              viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 35,
                            ),
                            onPressed: () {
                              if (viewModel.isPlaying) {
                                viewModel.pause();
                              } else {
                                viewModel.play();
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 35),
                          onPressed: () => viewModel.playNext(),
                        ),
                        IconButton(
                          icon: Icon(Icons.repeat, color: viewModel.isRepeatEnabled ? Colors.green : Colors.white),
                          onPressed: () => viewModel.toggleRepeat(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
