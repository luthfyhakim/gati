# 🏃 Gati — Outdoor Sports & Running Tracker

<p align="center">
  <b>A modern, minimalist, and reliable GPS running tracker mobile application built with Flutter & GetX.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/State%20Management-GetX-8A2BE2" alt="GetX">
  <img src="https://img.shields.io/badge/Backend%20Database-Supabase-3ECF8E?logo=supabase&logoColor=white" alt="Supabase">
  <img src="https://img.shields.io/badge/Maps-Flutter%20Map%20(OSM)-226F6C" alt="Flutter Map">
</p>

---

## 📖 Daftar Isi
- [🏃 Gati — Outdoor Sports \& Running Tracker](#-gati--outdoor-sports--running-tracker)
  - [📖 Daftar Isi](#-daftar-isi)
  - [🌟 Tentang Proyek](#-tentang-proyek)
  - [⚡ Fitur Utama](#-fitur-utama)
    - [1. Autentikasi \& Keamanan Pengguna](#1-autentikasi--keamanan-pengguna)
    - [2. Pelacakan Aktivitas Lari Real-Time (Real-Time GPS Tracking)](#2-pelacakan-aktivitas-lari-real-time-real-time-gps-tracking)
    - [3. Peta \& Visualisasi Interaktif](#3-peta--visualisasi-interaktif)
    - [4. Manajemen \& Riwayat Aktivitas](#4-manajemen--riwayat-aktivitas)
    - [5. Rekomendasi Perlengkapan Olahraga (Sport Gear)](#5-rekomendasi-perlengkapan-olahraga-sport-gear)
  - [🏗 Arsitektur \& Konsep Desain](#-arsitektur--konsep-desain)
  - [📡 Implementasi GPS Tracking \& Algoritma](#-implementasi-gps-tracking--algoritma)
    - [1. Alur Manajemen Izin (Permission Handling)](#1-alur-manajemen-izin-permission-handling)
    - [2. Background Tracking \& Foreground Service](#2-background-tracking--foreground-service)
    - [3. Perhitungan Jarak: Formula Haversine](#3-perhitungan-jarak-formula-haversine)
    - [4. Perhitungan Metrik Lari](#4-perhitungan-metrik-lari)
  - [📁 Struktur Proyek](#-struktur-proyek)
  - [🧩 Penjelasan Komponen Kunci](#-penjelasan-komponen-kunci)
    - [1. `TrackingService` (`lib/app/data/services/tracking_service.dart`)](#1-trackingservice-libappdataservicestracking_servicedart)
    - [2. `AuthService` \& `AuthRepository` (`lib/app/data/services/auth_service.dart`)](#2-authservice--authrepository-libappdataservicesauth_servicedart)
    - [3. `StorageService` (`lib/app/data/services/storage_service.dart`)](#3-storageservice-libappdataservicesstorage_servicedart)
    - [4. `SportGearService` (`lib/app/data/services/sport_gear_service.dart`)](#4-sportgearservice-libappdataservicessport_gear_servicedart)
    - [5. `TrackingView` \& `TrackingController` (`lib/app/modules/tracking/`)](#5-trackingview--trackingcontroller-libappmodulestracking)
  - [🛠 Tech Stack \& Dependensi](#-tech-stack--dependensi)
  - [🚀 Panduan Instalasi \& Menjalankan Aplikasi](#-panduan-instalasi--menjalankan-aplikasi)
    - [Prasyarat](#prasyarat)
    - [Konfigurasi Lingkungan (.env)](#konfigurasi-lingkungan-env)
    - [Struktur Database Supabase](#struktur-database-supabase)
    - [Langkah Instalasi](#langkah-instalasi)
  - [⚠️ Batasan Proyek (Constraints)](#️-batasan-proyek-constraints)

---

## 🌟 Tentang Proyek

**Gati** adalah aplikasi *mobile activity tracker* yang dirancang khusus untuk aktivitas lari di luar ruangan (*outdoor running*). Terinspirasi dari esensi aplikasi kebugaran terkemuka seperti Strava, Gati menyederhanakan fungsionalitas dengan berfokus penuh pada **keakuratan pelacakan GPS**, **kalkulasi metrik performa lari yang presisi**, **visualisasi rute interaktif**, serta **rekomendasi perlengkapan olahraga (*sport gear*)** yang terintegrasi langsung dengan Supabase Database.

Aplikasi ini dikembangkan dengan mematuhi prinsip *clean architecture*, pemisahan tanggung jawab (*separation of concerns*), penanganan *lifecycle* pelacakan yang tangguh di latar belakang (*background & foreground service*), serta penyimpanan data lokal yang aman.

---

## ⚡ Fitur Utama

### 1. Autentikasi & Keamanan Pengguna
* **Registrasi & Login**: Autentikasi pengguna berbasis email dan kata sandi.
* **Token-Based Authentication**: Penerbitan sesi token terenkripsi.
* **Penyimpanan Kredensial Aman**: Integrasi `flutter_secure_storage` dengan enkripsi Keychain (iOS) & Keystore (Android) untuk menyimpan token sesi, serta `get_storage` untuk data profil pengguna dan data aktivitas offline.
* **Auto Session Resume**: Mendeteksi sesi pengguna yang masih aktif saat aplikasi pertama kali dibuka (*splash screen transition*).

### 2. Pelacakan Aktivitas Lari Real-Time (Real-Time GPS Tracking)
* **Kontrol Tracking Penuh**: Memulai (*Start*), Menjeda (*Pause*), Melanjutkan (*Resume*), Menyelesaikan (*Finish*), atau Membatalkan (*Cancel*) sesi aktivitas.
* **Pelacakan Posisi Akurat**: Menggunakan sensor GPS perangkat dengan tingkat akurasi tinggi (`LocationAccuracy.best`) dan interval pembacaan 1 detik.
* **Pembedaan Waktu Aktif**: Memisahkan secara akurat antara **Moving Time** (durasi aktual berlari) dan **Elapsed Time** (durasi total termasuk saat dijeda).
* **Kalkulasi Metrik Real-Time**:
  * Jarak tempuh total (meter dan kilometer).
  * Kecepatan saat ini dan kecepatan rata-rata (km/jam).
  * Rata-rata Pace (menit:detik per km).
  * Split Pace per 1 kilometer secara dinamis.
  * Elevasi ketinggian (*Elevation Gain* dan *Max Elevation*).
* **Visualisasi Splits**: Diagram batang interaktif pada panel bawah yang menampilkan kecepatan (*pace*) pada setiap kilometer yang telah diselesaikan.

### 3. Peta & Visualisasi Interaktif
* **Peta Berbasis OpenStreetMap / Tile Layer**: Menggunakan plugin `flutter_map` dan koordinat `latlong2`.
* **Dynamic Polyline Route**: Menggambar rute lari secara real-time langsung di atas peta saat pengguna bergerak.
* **Titik Marker Informatif**: Menandai titik awal lari (*start marker* hijau) dan posisi terkini pelari (*current position marker* beranimasi).
* **Smooth Camera Re-center**: Tombol re-center kamera peta untuk langsung mengarahkan tampilan kembali ke posisi pengguna terkini dengan animasi halus.

### 4. Manajemen & Riwayat Aktivitas
* **Dashboard Statistik Beranda**: Ringkasan total jarak, total durasi, total sesi lari, serta akumulasi aktivitas minggu ini.
* **Halaman Riwayat (History)**: Daftar riwayat lari per pengguna yang disusun kronologis dari yang terbaru.
* **Halaman Detail Aktivitas**:
  * Tampilan rute lari lengkap pada peta yang otomatis disesuaikan ukurannya (*auto-fit bounds*).
  * Statistik komprehensif: Moving Time, Elapsed Time, Jarak, Elevasi, Kecepatan Rata-rata, Pace, serta rincian Splits per km.
  * Fitur penyuntingan judul dan catatan aktivitas lari (*Edit title & description*).
  * Fitur penghapusan catatan aktivitas (*Delete activity*).

### 5. Rekomendasi Perlengkapan Olahraga (Sport Gear)
* **Katalog Cloud via Supabase**: Menampilkan katalog perlengkapan lari langsung dari Supabase Database (*Shoes, Apparel, Smart Watch, Accessories*).
* **Filter Multi-Level**: Filter berdasarkan kategori utama serta subkategori khusus sepatu lari (*Daily Trainer, Race Day, Stability, Trail*).
* **Pencarian Cepat**: Pencarian produk berdasarkan brand, nama, atau tipe lari.
* **Detail Produk**: Informasi lengkap mengenai spesifikasi perlengkapan, estimasi harga, deskripsi fungsional, dan foto produk.

---

## 🏗 Arsitektur & Konsep Desain

Proyek ini menggunakan struktur modular berbasis **GetX Pattern** (yang kompatibel dengan Get CLI) dengan menerapkan prinsip **Separation of Concerns (SoC)**:

```
┌────────────────────────────────────────────────────────┐
│                      UI / VIEW                         │
│  (Widgets, Reactive Obx, FlutterMap, Visualizations)   │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│                     CONTROLLER                         │
│  (State Management, Business Logic, Navigation)        │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│                     REPOSITORY                         │
│  (Data Abstraction Layer, Aggregator)                  │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│                   SERVICE / PROVIDER                   │
│  (TrackingService, AuthService, Storage, Supabase)     │
└────────────────────────────────────────────────────────┘
```

1. **Presentation Layer (Views)**: Bertanggung jawab murni merender antarmuka pengguna secara reaktif (`Obx`), bebas dari logika bisnis.
2. **Controller Layer**: Mengelola state menggunakan reaktivitas GetX (`Rx`, `.obs`), mendengarkan input aksi pengguna, dan berinteraksi dengan repository atau service.
3. **Repository Layer**: Lapisan abstraksi data yang menghubungkan controller dengan data sources (local cache atau cloud database).
4. **Service Layer**:
   * `TrackingService`: Mengelola sensor GPS, streams koordinat, timer, dan status pelacakan.
   * `AuthService`: Mengatur proses login, registrasi, enkripsi token, dan sesi pengguna.
   * `StorageService`: Mengatur penyimpanan lokal terenkripsi (`flutter_secure_storage`) dan key-value box (`get_storage`).
   * `SportGearService`: Mengelola koneksi dan query data ke Supabase API.

---

## 📡 Implementasi GPS Tracking & Algoritma

Pelacakan GPS merupakan inti teknis utama dari aplikasi Gati. Bagian ini merinci bagaimana subsistem GPS diimplementasikan secara komprehensif dan dapat dipertanggungjawabkan secara akademis.

### 1. Alur Manajemen Izin (Permission Handling)
Sebelum pelacakan dimulai, `TrackingService._ensurePermissions()` melakukan validasi berlapis guna memastikan keandalan akses sensor:
1. **Pengecekan Status GPS Service**: Memastikan GPS hardware/layanan lokasi pada perangkat dalam kondisi aktif via `Geolocator.isLocationServiceEnabled()`. Jika tidak aktif, memunculkan `PermissionException`.
2. **Izin Notifikasi (Android 13+ / API 33+)**: Mengirim permintaan runtime `Permission.notification` untuk memenuhi syarat pelacakan foreground service.
3. **Izin Lokasi Presisi (Find Location)**: Memeriksa dan meminta runtime permission `LocationPermission.whileInUse` atau `LocationPermission.always`.
4. **Penanganan Kasus Penolakan Permanen**: Jika izin ditolak permanen (`deniedForever`), pengguna diarahkan ke pengaturan sistem perangkat.

### 2. Background Tracking & Foreground Service
Agar pelacakan tidak dimatikan oleh sistem operasi (Android Doze Mode atau iOS background suspend) ketika pengguna mematikan layar atau beralih ke aplikasi lain:
* **Android**: Dikonfigurasikan menggunakan `AndroidSettings` dengan `ForegroundNotificationConfig`:
  ```dart
  AndroidSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 0,
    intervalDuration: const Duration(seconds: 1),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: "Tracking Active",
      notificationText: "Gati is tracking your activity.",
      enableWakeLock: true,
    ),
  );
  ```
  Pada file `AndroidManifest.xml`, dideklarasikan service bertipe `foregroundServiceType="location"` dan izin `ACCESS_BACKGROUND_LOCATION` serta `WAKE_LOCK`.
* **iOS**: Dikonfigurasikan menggunakan `AppleSettings` dengan `activityType: ActivityType.fitness`, `showBackgroundLocationIndicator: true`, dan mode latar belakang `location` pada `Info.plist`.

### 3. Perhitungan Jarak: Formula Haversine
Untuk menghitung jarak antara dua titik koordinat geografis (titik awal $(\phi_1, \lambda_1)$ dan titik akhir $(\phi_2, \lambda_2)$) pada permukaan bola bumi, digunakan **Formula Haversine** (`GeoUtils.haversineDistanceMeters`):

$$\Delta\phi = \phi_2 - \phi_1 \quad (\text{selisih lintang dalam radian})$$

$$\Delta\lambda = \lambda_2 - \lambda_1 \quad (\text{selisih bujur dalam radian})$$

$$a = \sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1) \cdot \cos(\phi_2) \cdot \sin^2\left(\frac{\Delta\lambda}{2}\right)$$

$$c = 2 \cdot \operatorname{atan2}\left(\sqrt{a}, \sqrt{1 - a}\right)$$

$$d = R \cdot c$$

Di mana:
* $R = 6.371.000\text{ meter}$ (rata-rata jari-jari bumi).
* $d$ adalah jarak lingkaran besar (*orthodromic distance*) dalam satuan meter.

> **Catatan**: Formula Haversine dipilih karena memberikan akurasi matematis yang sangat tinggi untuk jarak pendek hingga menengah (di bawah $100\text{ km}$) tanpa beban komputasi yang berat dari formula ellipsoid Vincenty.

### 4. Perhitungan Metrik Lari

| Metrik                                     | Formula / Logika                                                              | Penjelasan                                                                                                  |
| :----------------------------------------- | :---------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------- |
| **Moving Time ($T_{\text{moving}}$)**      | $T_{\text{moving}} = T_{\text{elapsed}} - T_{\text{paused}}$                  | Menghitung waktu bersih di mana pelari aktif bergerak tanpa menghitung waktu saat status dijeda (*paused*). |
| **Elapsed Time ($T_{\text{elapsed}}$)**    | $T_{\text{elapsed}} = t_{\text{sekarang}} - t_{\text{mulai}}$                 | Durasi total sesi sejak tombol start ditekan hingga selesai.                                                |
| **Kecepatan Rata-rata ($v_{\text{avg}}$)** | $v_{\text{avg}} = \frac{d_{\text{km}}}{T_{\text{moving, jam}}}$               | Kecepatan lari rata-rata dalam satuan kilometer per jam ($\text{km/h}$).                                    |
| **Average Pace ($P_{\text{avg}}$)**        | $P_{\text{avg}} = \frac{T_{\text{moving, detik}}}{d_{\text{km}}}$             | Waktu yang dibutuhkan untuk menempuh 1 kilometer (dikonversi ke format `menit:detik /km`).                  |
| **Kilometer Splits**                       | Saat $\Delta d \ge 1.000\text{ m}$, simpan interval waktu $t_{\text{split}}$. | Merekam performa tempo pada setiap interval kilometer ke-$1, 2, 3, \dots, n$.                               |
| **Elevation Gain ($\Delta H$)**            | $\Delta H = \sum \max(0, h_i - h_{i-1})$                                      | Akumulasi pertambahan elevasi ketinggian positif dari sensor altimeter GPS.                                 |

---

## 📁 Struktur Proyek

```
gati/
├── android/                   # Konfigurasi native Android (Manifest, Gradle)
├── ios/                       # Konfigurasi native iOS (Info.plist, Podfile)
├── assets/
│   └── logo/                  # Asset ikon & logo aplikasi
├── lib/
│   ├── app/
│   │   ├── core/              # Komponen inti, utilitas matematika, konstanta
│   │   │   ├── constants/
│   │   │   │   └── storage_keys.dart    # Kunci penyimpanan lokal
│   │   │   ├── exceptions/
│   │   │   │   └── app_exception.dart   # Penanganan exception custom
│   │   │   └── utils/
│   │   │       └── geo_utils.dart       # Implementasi rumus Haversine
│   │   ├── data/              # Lapisan data (Models, Services, Repositories)
│   │   │   ├── models/
│   │   │   │   ├── activity_model.dart  # Data model sesi aktivitas & statistik
│   │   │   │   ├── activity_point.dart  # Model koordinat lat, lng, altitude, waktu
│   │   │   │   ├── activity_type.dart   # Enum tipe aktivitas (Running)
│   │   │   │   ├── category_model.dart  # Model kategori & subkategori gear
│   │   │   │   ├── sport_gear_model.dart# Model produk sport gear
│   │   │   │   └── user_model.dart      # Model data pengguna
│   │   │   ├── repositories/
│   │   │   │   ├── activity_repository.dart # Abstraksi akses data aktivitas
│   │   │   │   └── auth_repository.dart     # Abstraksi akses otentikasi
│   │   │   └── services/
│   │   │       ├── activity_service.dart    # Service manipulasi data aktivitas
│   │   │       ├── auth_service.dart        # Service registrasi, login, token
│   │   │       ├── sport_gear_service.dart  # Service koneksi database Supabase
│   │   │       ├── storage_service.dart     # Service secure storage & GetStorage
│   │   │       └── tracking_service.dart    # Service pelacakan GPS & sensor
│   │   ├── modules/           # Modul fitur UI (GetX: Binding, Controller, View)
│   │   │   ├── activity_detail/ # Halaman detail & edit riwayat aktivitas
│   │   │   ├── home/            # Dashboard beranda, riwayat, katalog gear, profil
│   │   │   ├── login/           # Halaman masuk akun
│   │   │   ├── onboarding/      # Halaman pengenalan fitur
│   │   │   ├── register/        # Halaman pendaftaran pengguna
│   │   │   ├── sport_gear_detail/ # Halaman detail spesifikasi gear
│   │   │   ├── tracking/        # Halaman pelacakan GPS & peta live
│   │   │   └── welcome/         # Halaman pembuka / splash gate
│   │   └── routes/
│   │       ├── app_pages.dart   # Definisi rute GetPage & Binding injeksi
│   │       └── app_routes.dart  # Konstanta nama rute navigasi
│   └── main.dart              # Entry point aplikasi & inisialisasi dependensi
├── .env.example               # Contoh template variabel lingkungan
├── pubspec.yaml               # Deklarasi paket & dependensi Flutter
└── README.md                  # Dokumentasi proyek
```

---

## 🧩 Penjelasan Komponen Kunci

### 1. `TrackingService` (`lib/app/data/services/tracking_service.dart`)
* Merupakan jantung sistem pelacakan GPS yang diinisialisasi sebagai singleton `permanent: true`.
* Mengelola stream posisi koordinat (`Geolocator.getPositionStream`), timer 1 detik untuk menghitung durasi, deteksi pause/resume, penambahan titik rute (`ActivityPoint`), penambahan akumulasi jarak via `GeoUtils`, dan deteksi split setiap penambahan jarak $1\text{ km}$.
* Menghasilkan objek `Activity` yang lengkap saat fungsi `stop()` dipanggil.

### 2. `AuthService` & `AuthRepository` (`lib/app/data/services/auth_service.dart`)
* Menangani proses pendaftaran akun baru dengan validasi keunikan email.
* Melakukan proses verifikasi kata sandi saat login dan menerbitkan representasi token sesi.
* Menyimpan token sesi ke dalam secure storage agar pengguna tidak perlu melakukan login ulang setiap kali membuka aplikasi.

### 3. `StorageService` (`lib/app/data/services/storage_service.dart`)
* Mengombinasikan `FlutterSecureStorage` (untuk data sensitif seperti token otentikasi) dan `GetStorage` (untuk persistensi data lokal terstruktur seperti user records dan riwayat aktivitas).

### 4. `SportGearService` (`lib/app/data/services/sport_gear_service.dart`)
* Berkomunikasi langsung dengan Supabase Client untuk mengambil data kategori (`gear_categories`), subkategori (`gear_subcategories`), dan produk (`sport_gear`).

### 5. `TrackingView` & `TrackingController` (`lib/app/modules/tracking/`)
* Menampilkan peta layar penuh dengan OpenStreetMap Tile Layer.
* Panel bawah yang dapat digeser (*swipeable*) untuk melihat rincian live stats dan bar chart splits per kilometer.
* Kontrol interaktif satu sentuhan untuk jeda, lanjut lari, dan simpan rute.

---

## 🛠 Tech Stack & Dependensi

| Paket / Library              | Versi     | Fungsi / Peran                                                                             |
| :--------------------------- | :-------- | :----------------------------------------------------------------------------------------- |
| **`flutter`**                | SDK       | Kerangka kerja utama pengembangan UI mobile cross-platform.                                |
| **`get`**                    | `^4.7.3`  | Manajemen state reaktif, dependency injection, dan sistem routing deklaratif.              |
| **`geolocator`**             | `^14.0.2` | Mengakses sensor GPS, koordinat posisi real-time, dan konfigurasi foreground notification. |
| **`flutter_map`**            | `^8.3.0`  | Menampilkan peta interaktif berbasis ubin (*tiles*) OpenStreetMap.                         |
| **`latlong2`**               | `^0.9.1`  | Representasi objek koordinat lintang (*latitude*) dan bujur (*longitude*).                 |
| **`supabase_flutter`**       | `^2.12.4` | Klien resmi Supabase untuk mengambil data katalog perlengkapan olahraga.                   |
| **`flutter_secure_storage`** | `^10.0.0` | Penyimpanan token terenkripsi pada Keychain (iOS) dan Keystore (Android).                  |
| **`get_storage`**            | `^2.1.1`  | Penyimpanan lokal cepat (*key-value storage*) untuk data aktivitas dan pengguna.           |
| **`flutter_dotenv`**         | `^6.0.1`  | Membaca variabel rahasia lingkungan (URL dan Anon Key Supabase) dari file `.env`.          |
| **`permission_handler`**     | `^11.4.0` | Meminta dan memeriksa izin sistem (Notifikasi dan Lokasi).                                 |
| **`intl`**                   | `^0.20.2` | Pemformatan tanggal, waktu, dan mata uang Rupiah (`Rp`).                                   |
| **`flutter_native_splash`**  | `^2.4.7`  | Mengelola tampilan layar pembuka (*native splash screen*) yang mulus.                      |

---

## 🚀 Panduan Instalasi & Menjalankan Aplikasi

### Prasyarat
* **Flutter SDK**: Versi 3.x ke atas.
* **Dart SDK**: Versi 3.x ke atas.
* **Android Studio / Xcode**: Terkonfigurasi untuk emulator atau perangkat fisik (disarankan menggunakan perangkat fisik untuk pengujian GPS outdoor yang akurat).
* **Akun Supabase**: Proyek Supabase aktif untuk memuat data katalog Sport Gear.

### Konfigurasi Lingkungan (.env)
Buat file bernama `.env` pada direktori root proyek (salin dari `.env.example`):

```bash
cp .env.example .env
```

Buka file `.env` dan isi kredensial proyek Supabase Anda:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### Struktur Database Supabase
Pastikan tabel berikut tersedia pada database Supabase Anda untuk mendukung fitur katalog Sport Gear:

```sql
-- 1. Tabel Kategori Utama
CREATE TABLE gear_categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    display_order INT DEFAULT 0
);

-- 2. Tabel Subkategori Sepatu
CREATE TABLE gear_subcategories (
    id BIGSERIAL PRIMARY KEY,
    category_name TEXT NOT NULL,
    name TEXT NOT NULL,
    display_order INT DEFAULT 0
);

-- 3. Tabel Produk Sport Gear
CREATE TABLE sport_gear (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT,
    price NUMERIC NOT NULL,
    image_url TEXT NOT NULL,
    description TEXT,
    run_type TEXT
);
```

### Langkah Instalasi

1. **Clone repositori**:
   ```bash
   git clone https://github.com/luthfyhakim/gati.git
   cd gati
   ```

2. **Unduh seluruh dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**:
   * Untuk Android:
     ```bash
     flutter run
     ```
   * Untuk iOS (pastikan pod telah terpasang):
     ```bash
     cd ios && pod install && cd ..
     flutter run
     ```

---

## ⚠️ Batasan Proyek (Constraints)

Sesuai dengan ruang lingkup dan batasan fungsionalitas MVP yang ditetapkan:
* **Tidak Ada Fitur Sosial**: Aplikasi ini sengaja tidak mengimplementasikan fitur jejaring sosial seperti followers, likes, feed komunitas, atau komentar antar-pengguna.
* **Fokus Aktivitas Tunggal**: Pelacakan aktivitas dioptimalkan secara spesifik untuk olahraga **Lari (Running)** di luar ruangan.
* **Penyimpanan Aktivitas**: Data riwayat aktivitas disimpan secara lokal pada perangkat pengguna (*local storage*) dengan indeks per email pengguna, sedangkan Supabase difokuskan untuk katalog produk dan gear olahraga.

---

<p align="center">
  Cheers 🍻
</p>
