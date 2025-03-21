import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/audio_handler.dart';
import '../services/song_service.dart';

// Müzik çalar için ViewModel sınıfı
class AudioPlayerViewModel extends ChangeNotifier {
  final AudioPlayerHandler _audioHandler;
  final SongService _songService = SongService();
  final Random _random = Random();

  // Stream abonelikleri
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  Timer? _positionTimer;

  // Durum değişkenleri
  Song? _currentSong;
  List<Song> _songs = [];
  List<Song> _shuffledSongs = [];
  bool _isPlaying = false;
  bool _isRepeatEnabled = false;
  bool _isShuffleEnabled = false;
  bool _isSeeking = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  AudioPlayerViewModel(this._audioHandler) {
    _loadSongs();
    _initStreams();
  }

  // Stream'leri başlatan metod
  void _initStreams() {
    // Önceki stream aboneliklerini iptal et
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _positionTimer?.cancel();

    // Çalma durumu değişikliklerini dinle
    _playbackStateSubscription = _audioHandler.playbackState.listen(
      (state) {
        _isPlaying = state.playing;
        if (!_isSeeking) {
          // Pozisyon değerinin süreyi aşmamasını sağla
          final newPosition = state.position;
          _position = newPosition > _duration ? _duration : newPosition;
        }
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    // Medya öğesi değişikliklerini dinle
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

    // Pozisyon zamanlayıcısını başlat
    _startPositionTimer();
  }

  // Pozisyon güncelleme zamanlayıcısını başlatan metod
  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isPlaying && !_isSeeking) {
        _position += const Duration(milliseconds: 200);
        notifyListeners();
      }
    });
  }

  // Şarkıları yükleyen metod
  void _loadSongs() {
    try {
      _songs = _songService.getSampleSongs();
      _shuffledSongs = List.from(_songs);
      if (_songs.isNotEmpty) {
        _loadPlaylist(_songs, 0);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Çalma listesini yükleyen metod
  Future<void> _loadPlaylist(List<Song> songs, int initialIndex) async {
    try {
      await _audioHandler.loadPlaylist(songs, initialIndex);
      _currentSong = songs[initialIndex];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Tekrar modunu değiştiren metod
  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }

  // Karıştırma modunu değiştiren metod
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled) {
      _shuffleSongs();
      // Mevcut şarkıyı karıştırılmış listenin başına al
      if (_currentSong != null) {
        final index = _shuffledSongs.indexOf(_currentSong!);
        if (index != -1) {
          _shuffledSongs.removeAt(index);
          _shuffledSongs.insert(0, _currentSong!);
        }
      }
      _loadPlaylist(_shuffledSongs, 0);
    } else {
      if (_currentSong != null) {
        final index = _songs.indexOf(_currentSong!);
        if (index != -1) {
          _loadPlaylist(_songs, index);
        }
      }
    }
    notifyListeners();
  }

  // Şarkıları karıştıran yardımcı metod
  void _shuffleSongs() {
    _shuffledSongs = List.from(_songs);
    for (var i = _shuffledSongs.length - 1; i > 0; i--) {
      var j = _random.nextInt(i + 1);
      var temp = _shuffledSongs[i];
      _shuffledSongs[i] = _shuffledSongs[j];
      _shuffledSongs[j] = temp;
    }
  }

  // Aktif çalma listesini döndüren getter
  List<Song> get _currentPlaylist => _isShuffleEnabled ? _shuffledSongs : _songs;

  // Belirli bir şarkıyı çalan metod
  Future<void> playSong(Song song) async {
    try {
      final index = _currentPlaylist.indexOf(song);
      if (index != -1) {
        await _loadPlaylist(_currentPlaylist, index);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Çalmayı başlatan metod
  Future<void> play() async {
    try {
      await _audioHandler.play();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Çalmayı duraklatma metodu
  Future<void> pause() async {
    try {
      await _audioHandler.pause();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // İleri/geri sarma başlangıç metodu
  Future<void> seekStart() async {
    _isSeeking = true;
  }

  // İleri/geri sarma metodu
  Future<void> seek(Duration position) async {
    try {
      _position = position;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // İleri/geri sarma bitiş metodu
  Future<void> seekEnd() async {
    try {
      _isSeeking = false;
      await _audioHandler.seek(_position);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Çalmayı durduran metod
  Future<void> stop() async {
    try {
      await _audioHandler.stop();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Sonraki şarkıya geçen metod
  void playNext() async {
    try {
      await _audioHandler.skipToNext();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Önceki şarkıya geçen metod
  void playPrevious() async {
    try {
      await _audioHandler.skipToPrevious();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Getter metodları
  Song? get currentSong => _currentSong;
  List<Song> get songs => _songs;
  bool get isPlaying => _isPlaying;
  bool get isRepeatEnabled => _isRepeatEnabled;
  bool get isShuffleEnabled => _isShuffleEnabled;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get error => _error;

  // Kaynakları temizleyen dispose metodu
  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _positionTimer?.cancel();
    super.dispose();
  }

  // Hata mesajını temizleyen metod
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
