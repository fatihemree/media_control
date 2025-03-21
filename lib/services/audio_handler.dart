import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

// Arkaplanda müzik çalma ve kontrol işlemlerini yöneten sınıf
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  MediaItem? _mediaItem;
  List<MediaItem> _queue = [];
  int _queueIndex = -1;
  bool _isLoopMode = false;

  AudioPlayerHandler() {
    _initAudioPlayer();
  }

  // Müzik çaları başlatan ve gerekli dinleyicileri ayarlayan metod
  void _initAudioPlayer() {
    // iOS için ses oturumu yapılandırması
    if (Platform.isIOS) {
      _player.setAutomaticallyWaitsToMinimizeStalling(false);
    }

    // Başlangıç tekrar modunu ayarla
    _player.setLoopMode(LoopMode.one);
    _isLoopMode = true;

    // Çalma olaylarını dinle
    _player.playbackEventStream.listen(_broadcastState);

    // Oynatıcı durum değişikliklerini dinle
    _player.playerStateStream.listen((playerState) {
      // Çalma durumunu güncelle
      _broadcastState(_player.playbackEvent);

      // Şarkı tamamlandığında yapılacak işlemler
      if (playerState.processingState == ProcessingState.completed) {
        if (_isLoopMode) {
          // Tekrar modu açıksa şarkıyı başa sar ve tekrar çal
          _player.seek(Duration.zero);
          _player.play();
        } else {
          // Tekrar modu kapalıysa sonraki şarkıya geç
          skipToNext();
        }
      }
    });

    // Süre değişikliklerini dinle
    _player.durationStream.listen((duration) {
      if (duration != null && _mediaItem != null) {
        mediaItem.add(_mediaItem!.copyWith(duration: duration));
      }
    });

    // Pozisyon değişikliklerini dinle
    _player.positionStream.listen((position) {
      _broadcastState(_player.playbackEvent);
    });
  }

  // Çalma durumunu yayınlayan metod
  void _broadcastState(PlaybackEvent event) {
    // İşlem durumunu belirle
    final processingState =
        {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ??
        AudioProcessingState.idle;

    // Pozisyon değerinin süreyi aşmamasını sağla
    final position = _player.position;
    final duration = _player.duration ?? Duration.zero;
    final validPosition = position > duration ? duration : position;

    // Durumu yayınla
    playbackState.add(
      playbackState.value.copyWith(
        // Medya kontrolleri
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
        // Sistem eylemleri
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

  // Tekrar modunu değiştiren metod
  Future<void> toggleLoopMode() async {
    _isLoopMode = !_isLoopMode;
    await _player.setLoopMode(_isLoopMode ? LoopMode.one : LoopMode.off);
    _broadcastState(_player.playbackEvent);
  }

  // Özel eylem işleyicisi
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'loop') {
      await toggleLoopMode();
    }
  }

  // Ses kaynağını ayarlayan metod
  // Bu metod şarkı değiştirildiğinde veya yeni bir şarkı başlatıldığında
  // skipToQueueItem metodu tarafından çağrılır.
  //
  // Parametreler:
  // - song: Çalınacak şarkının bilgilerini içeren Song nesnesi
  //
  // İşlevler:
  // 1. Mevcut çalan şarkıyı durdurur
  // 2. Yeni şarkı için medya bilgilerini hazırlar
  // 3. iOS için gerekli başlıkları ayarlar
  // 4. Ses kaynağını yükler ve tekrar modunu ayarlar
  Future<void> setAudioSource(Song song) async {
    try {
      // Mevcut çalmayı durdur
      await _player.stop();

      // Medya öğesini oluştur
      _mediaItem = MediaItem(
        id: song.id,
        album: '',
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: Uri.parse(song.albumArt),
      );

      mediaItem.add(_mediaItem!);

      // iOS için özel başlıklarla yeni ses kaynağını ayarla
      final audioSource = AudioSource.uri(
        Uri.parse(song.url),
        headers: Platform.isIOS ? {'User-Agent': 'MyApp/1.0'} : null,
      );

      await _player.setAudioSource(audioSource, preload: true);

      // Yeni kaynak için tekrar modunu ayarla
      await _player.setLoopMode(_isLoopMode ? LoopMode.one : LoopMode.off);

      // Başlangıç durumunu yayınla
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Ses kaynağı ayarlanırken hata: $e");
      throw Exception('Ses kaynağı yüklenemedi: $e');
    }
  }

  // Çalma listesini yükleyen metod
  Future<void> loadPlaylist(List<Song> songs, int initialIndex) async {
    try {
      // Şarkıları MediaItem'lara dönüştür
      final mediaItems =
          songs
              .map(
                (song) => MediaItem(
                  id: song.url,
                  album: '',
                  title: song.title,
                  artist: song.artist,
                  duration: song.duration,
                  artUri: Uri.parse(song.albumArt),
                  extras: {'url': song.url}, // URL'yi extras'ta sakla
                ),
              )
              .toList();

      // Sırayı güncelle
      await updateQueue(mediaItems);

      // Başlangıç şarkısını çal
      if (initialIndex >= 0 && initialIndex < songs.length) {
        _queueIndex = initialIndex;
        await skipToQueueItem(initialIndex);
      }
    } catch (e) {
      print("Çalma listesi yüklenirken hata: $e");
      throw Exception('Çalma listesi yüklenemedi: $e');
    }
  }

  // Sırayı güncelleyen metod
  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    try {
      _queue = queue;
      this.queue.add(_queue);
    } catch (e) {
      print("Sıra güncellenirken hata: $e");
      throw Exception('Sıra güncellenemedi: $e');
    }
  }

  // Sıradaki belirli bir öğeye geçen metod
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
      print("Sıradaki öğeye geçilirken hata: $e");
    }
  }

  // Sonraki şarkıya geçen metod
  @override
  Future<void> skipToNext() async {
    if (_isLoopMode) {
      // Tekrar modu açıksa mevcut şarkıyı başa sar
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_queueIndex < _queue.length - 1) {
      await skipToQueueItem(_queueIndex + 1);
    }
  }

  // Önceki şarkıya geçen metod
  @override
  Future<void> skipToPrevious() async {
    if (_isLoopMode) {
      // Tekrar modu açıksa mevcut şarkıyı başa sar
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_player.position > const Duration(seconds: 3)) {
      // 3 saniyeden fazla çalınmışsa şarkıyı başa sar
      await _player.seek(Duration.zero);
    } else if (_queueIndex > 0) {
      // Önceki şarkıya geç
      await skipToQueueItem(_queueIndex - 1);
    }
  }

  // Çalmayı başlatan metod
  @override
  Future<void> play() async {
    try {
      await _player.play();
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Ses çalınırken hata: $e");
      throw Exception('Ses çalınamadı: $e');
    }
  }

  // Çalmayı duraklatma metodu
  @override
  Future<void> pause() async {
    try {
      await _player.pause();
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Ses duraklatılırken hata: $e");
      throw Exception('Ses duraklatılamadı: $e');
    }
  }

  // İleri/geri sarma metodu
  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Ses ileri/geri sarılırken hata: $e");
      throw Exception('Ses ileri/geri sarılamadı: $e');
    }
  }

  // Çalmayı durduran ve kaynakları temizleyen metod
  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.dispose();
      _broadcastState(_player.playbackEvent);
    } catch (e) {
      print("Ses durdurulurken hata: $e");
      throw Exception('Ses durdurulamadı: $e');
    }
  }
}
