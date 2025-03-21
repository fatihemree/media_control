import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'services/audio_handler.dart';
import 'viewmodels/audio_player_viewmodel.dart';
import 'views/home_view.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear the image cache to prevent database locks
  await DefaultCacheManager().emptyCache();

  // Initialize AudioService with platform-specific configuration
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.example.media_control.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: !Platform.isIOS,
      androidStopForegroundOnPause: Platform.isAndroid,
      fastForwardInterval: const Duration(seconds: 10),
      rewindInterval: const Duration(seconds: 10),
      androidNotificationIcon: 'mipmap/ic_launcher',
      notificationColor: Colors.grey[900],
    ),
  );

  // Register services
  getIt.registerSingleton<AudioPlayerHandler>(audioHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AudioPlayerViewModel(getIt<AudioPlayerHandler>()),
      child: MaterialApp(
        title: 'Spotify Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.black,
          sliderTheme: const SliderThemeData(trackHeight: 2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6)),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
        ),
        home: const HomeView(),
      ),
    );
  }
}
