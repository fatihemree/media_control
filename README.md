# Flutter Arkaplan Müzik Çalar

Bu proje, Flutter uygulamalarında arkaplanda müzik çalma özelliği sunan bir kütüphanedir. iOS ve Android platformlarında bildirim merkezi kontrollerini, arkaplan çalma özelliğini ve medya oturumu yönetimini destekler.

## Özellikler

- ✅ Arkaplanda müzik çalma
- ✅ Bildirim merkezi medya kontrolleri
- ✅ iOS Control Center entegrasyonu
- ✅ Android medya bildirimi
- ✅ Çalma listesi yönetimi
- ✅ Tekrar modu
- ✅ Karıştırma modu
- ✅ Şarkı ileri/geri sarma
- ✅ Otomatik sonraki şarkıya geçiş

## Kurulum

### 1. Bağımlılıklar

`pubspec.yaml` dosyanıza aşağıdaki bağımlılıkları ekleyin:

```yaml
dependencies:
  just_audio: ^0.9.34
  audio_service: ^0.18.12
  audio_session: ^0.1.16
  cached_network_image: ^3.3.0
```

### 2. Android Yapılandırması

#### Android Manifest Ayarları

`android/app/src/main/AndroidManifest.xml` dosyasına aşağıdaki izinleri ekleyin:

```xml
<manifest ...>
    <!-- İnternet izni -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- Arkaplan servisi izni -->
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

    <application ...>
        <!-- Arkaplan servisi tanımı -->
        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>

        <!-- Broadcast Receiver tanımı -->
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### 3. iOS Yapılandırması

#### Info.plist Ayarları

`ios/Runner/Info.plist` dosyasına aşağıdaki ayarları ekleyin:

```xml
<dict>
    <!-- Arkaplan müzik çalma özelliği -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>processing</string>
    </array>

    <!-- Ağ izinleri (HTTP istekleri için) -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
```

### 4. Proje Dosyalarının Kopyalanması

1. `lib/services` klasörü altına:
   - `audio_handler.dart`
   - `song_service.dart`

2. `lib/models` klasörü altına:
   - `song.dart`

3. `lib/viewmodels` klasörü altına:
   - `audio_player_viewmodel.dart`

4. `lib/views` klasörü altına:
   - `player_view.dart`
   - `home_view.dart`

### 5. Main.dart Yapılandırması

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AudioService'i başlat
  await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.myapp.audio',
      androidNotificationChannelName: 'Audio Service',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const MyApp());
}
```

## Kullanım

### 1. AudioPlayerHandler'ı Başlatma

```dart
final audioHandler = await AudioService.init(
  builder: () => AudioPlayerHandler(),
  config: const AudioServiceConfig(
    androidNotificationChannelId: 'com.myapp.audio',
    androidNotificationChannelName: 'Audio Service',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  ),
);
```

### 2. ViewModel'i Provider ile Kaydetme

```dart
void main() async {
  // ... AudioService init

  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioPlayerViewModel(audioHandler),
      child: const MyApp(),
    ),
  );
}
```

### 3. Şarkı Çalma

```dart
final viewModel = context.read<AudioPlayerViewModel>();
await viewModel.playSong(song);
```

## Önemli Notlar

### Android

1. MinSDK versiyonu en az 21 olmalıdır:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

2. Kotlin versiyonu 1.5.31 veya üzeri olmalıdır:
```gradle
buildscript {
    ext.kotlin_version = '1.5.31'
}
```

### iOS

1. Ses oturumu yönetimi için:
```dart
if (Platform.isIOS) {
  await _player.setAutomaticallyWaitsToMinimizeStalling(false);
}
```

2. HTTP istekleri için ATS ayarları Info.plist'te yapılandırılmalıdır.

## Hata Ayıklama

### Sık Karşılaşılan Hatalar

1. **Android Bildirim Görünmüyor**
   - AndroidManifest.xml'de izinlerin doğru tanımlandığından emin olun
   - Notification Channel ID'nin doğru olduğunu kontrol edin

2. **iOS Arkaplan Çalma Sorunu**
   - Info.plist'te UIBackgroundModes ayarlarını kontrol edin
   - AVAudioSession kategorisinin doğru ayarlandığından emin olun

3. **Medya Kontrolleri Çalışmıyor**
   - AudioService.init() çağrısının uygulama başlatılırken yapıldığından emin olun
   - Android için MediaButtonReceiver'ın manifest'te tanımlı olduğunu kontrol edin

## Katkıda Bulunma

1. Bu depoyu fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Bir Pull Request oluşturun

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.
