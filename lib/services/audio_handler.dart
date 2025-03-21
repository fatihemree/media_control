import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  MediaItem? _mediaItem;

  AudioPlayerHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      _broadcastState(_player.playbackEvent);
    });

    _player.durationStream.listen((duration) {
      if (duration != null && _mediaItem != null) {
        mediaItem.add(_mediaItem!.copyWith(duration: duration));
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        androidCompactActionIndices: [0, 1, 2],
        processingState:
            {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  Future<void> setAudioSource(Song song) async {
    try {
      _mediaItem = MediaItem(
        id: song.id,
        album: '',
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: Uri.parse(song.albumArt),
      );

      mediaItem.add(_mediaItem!);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.url)));
    } catch (e) {
      print("Error setting audio source: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
  }
}
