import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  MediaItem? _mediaItem;
  List<MediaItem> _queue = [];
  int _queueIndex = -1;
  bool _isLoopMode = false;

  AudioPlayerHandler() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Configure audio session for iOS
    if (Platform.isIOS) {
      _player.setAutomaticallyWaitsToMinimizeStalling(false);
    }

    // Set initial loop mode
    _player.setLoopMode(LoopMode.one);
    _isLoopMode = true;

    // Listen to playback events
    _player.playbackEventStream.listen(_broadcastState);

    // Listen to player state changes
    _player.playerStateStream.listen((playerState) {
      // Update playing state
      _broadcastState(_player.playbackEvent);

      // Handle completion
      if (playerState.processingState == ProcessingState.completed) {
        if (_isLoopMode) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          skipToNext();
        }
      }
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null && _mediaItem != null) {
        mediaItem.add(_mediaItem!.copyWith(duration: duration));
      }
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      _broadcastState(_player.playbackEvent);
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final processingState =
        {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ??
        AudioProcessingState.idle;

    // Ensure position doesn't exceed duration
    final position = _player.position;
    final duration = _player.duration ?? Duration.zero;
    final validPosition = position > duration ? duration : position;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.custom(
            name: 'loop',
            label: _isLoopMode ? 'Loop On' : 'Loop Off',
            androidIcon: 'drawable/ic_loop',
          ),
        ],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToPrevious,
          MediaAction.skipToNext,
        },
        androidCompactActionIndices: [0, 1, 2],
        processingState: processingState,
        playing: _player.playing,
        updatePosition: validPosition,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _queueIndex,
        repeatMode: _isLoopMode ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none,
      ),
    );
  }

  Future<void> toggleLoopMode() async {
    _isLoopMode = !_isLoopMode;
    await _player.setLoopMode(_isLoopMode ? LoopMode.one : LoopMode.off);
    _broadcastState(_player.playbackEvent);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'loop') {
      await toggleLoopMode();
    }
  }

  @override
  Future<void> setAudioSource(Song song) async {
    try {
      // Stop current playback
      await _player.stop();

      _mediaItem = MediaItem(
        id: song.id,
        album: '',
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: Uri.parse(song.albumArt),
      );

      mediaItem.add(_mediaItem!);

      // Set new audio source with headers for iOS
      final audioSource = AudioSource.uri(
        Uri.parse(song.url),
        headers: Platform.isIOS ? {'User-Agent': 'MyApp/1.0'} : null,
      );

      await _player.setAudioSource(audioSource, preload: true);

      // Set loop mode for the new source
      await _player.setLoopMode(_isLoopMode ? LoopMode.one : LoopMode.off);

      // Broadcast initial state
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Error setting audio source: $e");
      throw Exception('Could not load audio source: $e');
    }
  }

  Future<void> loadPlaylist(List<Song> songs, int initialIndex) async {
    try {
      // Convert songs to MediaItems
      final mediaItems =
          songs
              .map(
                (song) => MediaItem(
                  id: song.url, // Use URL as ID for audio source
                  album: '',
                  title: song.title,
                  artist: song.artist,
                  duration: song.duration,
                  artUri: Uri.parse(song.albumArt),
                  extras: {'url': song.url}, // Store URL in extras
                ),
              )
              .toList();

      // Update the queue
      await updateQueue(mediaItems);

      // Play the initial song
      if (initialIndex >= 0 && initialIndex < songs.length) {
        _queueIndex = initialIndex;
        await skipToQueueItem(initialIndex);
      }
    } catch (e) {
      print("Error loading playlist: $e");
      throw Exception('Could not load playlist: $e');
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    try {
      _queue = queue;
      // Update the queue
      this.queue.add(_queue);
    } catch (e) {
      print("Error updating queue: $e");
      throw Exception('Could not update queue: $e');
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    try {
      _queueIndex = index;
      final mediaItem = _queue[index];
      final url = mediaItem.extras?['url'] as String? ?? mediaItem.id;

      final song = Song(
        id: mediaItem.id,
        title: mediaItem.title,
        artist: mediaItem.artist ?? '',
        albumArt: mediaItem.artUri?.toString() ?? '',
        url: url,
        duration: mediaItem.duration ?? Duration.zero,
      );

      await setAudioSource(song);
      await play();
    } catch (e) {
      print("Error skipping to queue item: $e");
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_isLoopMode) {
      // If loop mode is enabled, restart the current song
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_queueIndex < _queue.length - 1) {
      await skipToQueueItem(_queueIndex + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_isLoopMode) {
      // If loop mode is enabled, restart the current song
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_player.position > const Duration(seconds: 3)) {
      // If we're more than 3 seconds into the song, restart it
      await _player.seek(Duration.zero);
    } else if (_queueIndex > 0) {
      // Otherwise go to previous song
      await skipToQueueItem(_queueIndex - 1);
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Error playing audio: $e");
      throw Exception('Could not play audio: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Error pausing audio: $e");
      throw Exception('Could not pause audio: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Error seeking audio: $e");
      throw Exception('Could not seek audio: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.dispose();
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Error stopping audio: $e");
      throw Exception('Could not stop audio: $e');
    }
  }
}
