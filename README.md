# REQ ID COR (Clarity Over Resonance) — APK

APK Flutter buat request lagu, request banner, lihat history, dan chat tiket CS —
nyambung ke `api/index.js` di project utama. Tema warnanya disamain persis
sama website (`public/index.html`): ungu `#7c3aed`, cyan `#06b6d4`,
background gelap `#03050d`.

**Project ini SEKARANG SUDAH LENGKAP** — bukan cuma `lib/` doang lagi.
Folder `android/` (Gradle, Kotlin DSL, AndroidManifest, MainActivity, icon
launcher di semua density) sudah saya siapin manual, cocok buat build lewat
bot ZIP-ke-APK (Web2Apk atau sejenisnya) tanpa perlu install Flutter SDK di
laptop kamu sama sekali.

## Isi project ini

```
android/                    -> project Android native, LENGKAP
  app/
    build.gradle.kts        -> config app (applicationId: id.wanz.reqidcor)
    src/main/AndroidManifest.xml   -> embedding v2, label "REQ ID COR"
    src/main/kotlin/.../MainActivity.kt
    src/main/res/mipmap-*/ic_launcher.png  -> icon dari foto kamu (5 density)
  gradle/wrapper/gradle-wrapper.properties -> Gradle 8.11.1 (cocok AGP 8.11.1)
  gradlew, gradlew.bat, build.gradle.kts, settings.gradle.kts, gradle.properties
assets/icon/app_icon.png    -> icon app (dari foto yang kamu kasih, di-crop 1:1)
lib/                        -> source Dart (5 halaman + service API)
pubspec.yaml
```

## ✅ Project ini sudah 100% lengkap & siap kirim ke bot

`gradle-wrapper.jar` sudah ada di `android/gradle/wrapper/` — gak perlu langkah
tambahan apa-apa lagi. Ada 2 bug yang sempat bikin build gagal, keduanya
sudah diperbaiki:

1. **"deleted Android v1 embedding"** — folder `android/` sebelumnya belum
   ada sama sekali, jadi bot pakai template lawas. Sekarang sudah saya
   siapin lengkap dengan embedding v2 (`flutterEmbedding = 2` di
   `AndroidManifest.xml` + `MainActivity` pakai `FlutterActivity` modern).
2. **"Could not find or load main class org.gradle.wrapper.GradleWrapperMain"**
   — ada backslash nyasar di baris `CLASSPATH` file `android/gradlew`, jadi
   variabel `$APP_HOME` gak ke-substitusi dan Java nyari jar di path yang
   salah. Sudah diperbaiki.

Versi yang dipakai (disamain persis sama yang divalidasi bot kamu):
Gradle `8.14`, AGP `8.11.1`, Kotlin `2.2.20`, `google_fonts ^8.1.0`,
`intl ^0.20.3`, `flutter_lints ^6.0.0`.

## Yang WAJIB kamu ganti sebelum build

1. **Domain API** — buka `lib/services/api_service.dart` baris atas:
   ```dart
   const String kApiBaseUrl = 'https://api.pteronet.my.id';
   ```
   Ganti ke domain/IP `api/` kamu yang sebenarnya (`api/config.js` -> `DOMAIN`).
   Kalau API-nya masih HTTP biasa (bukan HTTPS), izin cleartext buat mode
   debug udah saya siapin di `android/app/src/debug/AndroidManifest.xml`,
   tapi buat build **release** kamu perlu nambahin manual
   `android:usesCleartextTraffic="true"` di `android/app/src/main/AndroidManifest.xml`
   pada tag `<application>` juga.

2. **applicationId** (opsional) — default saya set `id.wanz.reqidcor` di
   `android/app/build.gradle.kts`. Kalau kamu udah pernah publish APK versi
   lain dengan ID beda, samain biar update-nya nyambung (Android nolak install
   APK baru kalau applicationId beda dianggap app lain).

## Kalau mau build sendiri pakai Flutter SDK (bukan lewat bot)

```bash
flutter pub get
flutter build apk --release
```
Hasilnya di `build/app/outputs/flutter-apk/app-release.apk`. Ini otomatis
generate `gradle-wrapper.jar` sendiri kalau Flutter SDK kamu lengkap, jadi
kalau kamu punya laptop yang bisa install Flutter, ini rutenya paling simpel
— gak perlu ribet Gitpod/Codespaces sama sekali.

## Catatan penting soal fitur

- **Request lagu** bisa lewat upload file (MP3/WAV/OGG/FLAC/M4A/AAC, maks 20MB),
  cari YouTube, atau link manual — persis 3 cara di website.
- **Full access `WanzzGantengBanget`** dan **role VVIP/admin/owner**: udah
  dihandle otomatis di sisi server (`lib/roles.js`, `routes/api-mobile.js`),
  APK gak perlu logic khusus.
- **Tiket CS**: 1 akun cuma nyimpen 1 tiket aktif di HP (`SharedPreferences`).
  Kalau tiket ditutup admin, buka tab Tiket lagi otomatis balik ke form buka
  tiket baru.
- Belum ada halaman Admin — kalau nanti mau ditambah, tinggal bikin
  `admin_page.dart` baru dan cek `ApiService.instance.role`.

## Kalau masih error pas build

Kirim error log-nya ke saya (kayak yang kemarin), saya bantu fix. Info versi
yang dipakai project ini: AGP `8.11.1`, Kotlin `2.2.20`, Gradle `8.11.1`,
Java/Kotlin target `17`, `compileSdk`/`minSdk`/`targetSdk` ikut default
Flutter SDK yang dipakai bot-nya.
