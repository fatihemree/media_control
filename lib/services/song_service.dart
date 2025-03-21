import '../models/song.dart';

class SongService {
  List<Song> getSampleSongs() {
    return [
      Song(
        id: '1',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        albumArt: 'https://picsum.photos/400/400?random=1',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: const Duration(minutes: 3, seconds: 54),
      ),
      Song(
        id: '2',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        albumArt: 'https://picsum.photos/400/400?random=2',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: const Duration(minutes: 3, seconds: 20),
      ),
      Song(
        id: '3',
        title: 'Dance Monkey',
        artist: 'Tones and I',
        albumArt: 'https://picsum.photos/400/400?random=3',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        duration: const Duration(minutes: 3, seconds: 29),
      ),
    ];
  }
}
