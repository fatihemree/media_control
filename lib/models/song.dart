class Song {
  final String id;
  final String title;
  final String artist;
  final String albumArt;
  final String url;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArt,
    required this.url,
    required this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumArt: json['albumArt'] as String,
      url: json['url'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArt': albumArt,
      'url': url,
      'duration': duration.inMilliseconds,
    };
  }
}
