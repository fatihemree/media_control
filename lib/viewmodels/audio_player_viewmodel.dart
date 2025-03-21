import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/audio_handler.dart';
import '../services/song_service.dart';

class AudioPlayerViewModel extends ChangeNotifier {
  final AudioPlayerHandler _audioHandler;
  final SongService _songService = SongService();
  final Random _random = Random();

  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;

  Song? _currentSong;
  List<Song> _songs = [];
  List<Song> _shuffledSongs = [];
  bool _isPlaying = false;
  bool _isRepeatEnabled = false;
  bool _isShuffleEnabled = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  AudioPlayerViewModel(this._audioHandler) {
    _loadSongs();
    _initStreams();
  }

  void _initStreams() {
    _playbackStateSubscription = _audioHandler.playbackState.listen(
      (state) {
        _isPlaying = state.playing;
        _position = state.position;

        // Handle completion
        if (state.processingState == AudioProcessingState.completed) {
          if (_isRepeatEnabled) {
            _handleRepeat();
          } else {
            playNext();
          }
        }
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    _mediaItemSubscription = _audioHandler.mediaItem.listen(
      (item) {
        if (item?.duration != null) {
          _duration = item!.duration!;
          notifyListeners();
        }
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void _loadSongs() {
    try {
      _songs = _songService.getSampleSongs();
      _shuffledSongs = List.from(_songs);
      if (_songs.isNotEmpty) {
        playSong(_songs[0]);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _handleRepeat() async {
    if (_currentSong != null) {
      await _audioHandler.seek(Duration.zero);
      await _audioHandler.play();
    }
  }

  void _shuffleSongs() {
    _shuffledSongs = List.from(_songs);
    for (var i = _shuffledSongs.length - 1; i > 0; i--) {
      var j = _random.nextInt(i + 1);
      var temp = _shuffledSongs[i];
      _shuffledSongs[i] = _shuffledSongs[j];
      _shuffledSongs[j] = temp;
    }
  }

  List<Song> get _currentPlaylist => _isShuffleEnabled ? _shuffledSongs : _songs;

  Song? get currentSong => _currentSong;
  List<Song> get songs => _songs;
  bool get isPlaying => _isPlaying;
  bool get isRepeatEnabled => _isRepeatEnabled;
  bool get isShuffleEnabled => _isShuffleEnabled;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get error => _error;

  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled) {
      _shuffleSongs();
      // Keep current song at the start of shuffled list
      if (_currentSong != null) {
        final index = _shuffledSongs.indexOf(_currentSong!);
        if (index != -1) {
          _shuffledSongs.removeAt(index);
          _shuffledSongs.insert(0, _currentSong!);
        }
      }
    }
    notifyListeners();
  }

  Future<void> playSong(Song song) async {
    try {
      _currentSong = song;
      _duration = song.duration;
      _error = null;
      await _audioHandler.setAudioSource(song);
      await _audioHandler.play();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void play() {
    _audioHandler.play();
  }

  void pause() {
    _audioHandler.pause();
  }

  void seek(Duration position) {
    _audioHandler.seek(position);
  }

  void stop() {
    _audioHandler.stop();
  }

  void playNext() {
    if (_currentSong == null || _currentPlaylist.isEmpty) return;
    final currentIndex = _currentPlaylist.indexOf(_currentSong!);
    if (currentIndex < _currentPlaylist.length - 1) {
      playSong(_currentPlaylist[currentIndex + 1]);
    } else if (_isRepeatEnabled) {
      // If repeat is enabled and we're at the end, play the first song
      playSong(_currentPlaylist[0]);
    }
  }

  void playPrevious() {
    if (_currentSong == null || _currentPlaylist.isEmpty) return;
    final currentIndex = _currentPlaylist.indexOf(_currentSong!);
    // If we're more than 3 seconds into the song, restart it
    if (_position.inSeconds > 3) {
      seek(Duration.zero);
    } else if (currentIndex > 0) {
      playSong(_currentPlaylist[currentIndex - 1]);
    } else if (_isRepeatEnabled) {
      // If repeat is enabled and we're at the start, play the last song
      playSong(_currentPlaylist.last);
    }
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
