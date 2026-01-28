# KasirApp: Solusi Aplikasi Kasir Multi-Platform Modern

[![Flutter](https://img.shields.io/badge/Flutter-2.0.0+-blue?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0.0+-blue?style=flat-square&logo=dart)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Ringkasan Proyek

KasirApp adalah aplikasi kasir (Point-of-Sale) yang dirancang untuk memberikan solusi manajemen penjualan yang efisien dan andal bagi berbagai jenis bisnis. Dibangun menggunakan **Flutter**, aplikasi ini menawarkan pengalaman pengguna yang intuitif dan responsif di berbagai platform, termasuk Android, iOS (potensial), macOS, Windows, Linux, dan Web. Fokus utama proyek ini adalah pada kemudahan penggunaan, keandalan data, serta integrasi fitur-fitur penting untuk operasional kasir modern.

## Fitur Unggulan

KasirApp dilengkapi dengan serangkaian fitur canggih yang dirancang untuk mendukung operasional bisnis Anda:

*   **Manajemen Produk Komprehensif:**
    *   Sistem CRUD (Create, Read, Update, Delete) yang lengkap untuk produk.
    *   Dukungan pengelolaan stok dan harga jual/modal.
    *   Kemampuan menyertakan gambar produk untuk identifikasi visual yang mudah.
*   **Proses Transaksi Cepat & Akurat:**
    *   Antarmuka kasir interaktif dengan keranjang belanja dinamis.
    *   Perhitungan total otomatis, pengelolaan pembayaran, dan kalkulasi kembalian.
    *   **Pencetakan Struk Canggih:** Desain struk yang profesional dan informatif (Nama Toko, Alamat, ID Transaksi unik, detail pembayaran, kembalian). Mendukung pencetakan ulang struk dari riwayat transaksi.
*   **Analisis Laporan Penjualan Mendalam:**
    *   Generasi laporan penjualan harian, mingguan, dan bulanan.
    *   Ringkasan pendapatan, jumlah transaksi, dan identifikasi produk terlaris.
    *   Visualisasi data interaktif menggunakan grafik (line charts) untuk analisis tren yang lebih baik.
*   **Manajemen Pengguna Fleksibel:**
    *   Sistem manajemen peran berbasis akses (Admin/Kasir) untuk kontrol operasional yang aman.
    *   **Login Admin Default:** Untuk kemudahan setup awal pada instalasi baru, aplikasi menyediakan kredensial admin default (`username: admin`, `password: admin`).
*   **Infrastruktur Data Andal:**
    *   **Pencadangan Data (Backup):** Fitur esensial untuk membuat salinan database lokal ke lokasi yang dapat dipilih pengguna, menjamin keamanan data.
    *   **Pemulihan Data (Restore):** Memungkinkan pemulihan database aplikasi dari file backup `.db` yang dipilih, memastikan kelangsungan operasional.
*   **Integrasi Printer Thermal:**
    *   Konfigurasi mudah dengan printer thermal Bluetooth untuk pencetakan struk instan.
    *   **Otomatisasi Koneksi:** Aplikasi secara otomatis mendeteksi dan terhubung ke printer yang tersimpan saat startup, dengan notifikasi status koneksi yang jelas.
*   **Pengalaman Pengguna Superior:**
    *   **Antarmuka Pengguna Modern & Responsif (UI/UX):** Desain yang intuitif, estetis, dan adaptif, memastikan konsistensi dan kemudahan penggunaan di berbagai ukuran layar dan orientasi perangkat.
    *   **Autentikasi Aman:** Implementasi sistem login yang menjaga keamanan data pengguna.

## Tumpukan Teknologi (Tech Stack)

Proyek ini dibangun di atas tumpukan teknologi modern yang memastikan performa tinggi, skalabilitas, dan kemudahan pemeliharaan:

*   **Framework UI:** `Flutter` (memungkinkan pengembangan lintas platform dari satu basis kode).
*   **Manajemen State:** `Bloc` (untuk manajemen state yang reaktif, prediktif, dan teruji).
*   **Database Lokal:** `SQFlite` (implementasi SQLite yang efisien untuk penyimpanan data offline).
*   **Navigasi:** `GoRouter` (solusi routing deklaratif yang kuat).
*   **Injeksi Dependensi:** `GetIt` (service locator ringan untuk manajemen dependensi yang bersih).
*   **Visualisasi Data:** `fl_chart` (untuk grafik interaktif pada laporan penjualan).
*   **Utilitas Sistem:** `permission_handler`, `path_provider`, `file_picker`, `device_info_plus` (untuk interaksi mendalam dengan sistem operasi dan penyimpanan perangkat).
*   **Pengolahan Data & Media:** `intl`, `uuid`, `crypto`, `image_picker`, `flutter_image_compress`, `esc_pos_utils_plus`, `image` (untuk lokalisasi, generasi ID, keamanan data, pemilihan/kompresi gambar, dan formatting cetak).
*   **Integrasi Hardware:** `print_bluetooth_thermal` (untuk konektivitas printer thermal).

## Panduan Instalasi & Penggunaan (Developer)

Untuk menjalankan dan mengembangkan KasirApp di lingkungan lokal Anda:

1.  **Persyaratan:** Pastikan Anda memiliki Flutter SDK terinstal (versi 3.8.1 atau lebih baru direkomendasikan).

2.  **Kloning Repositori:**
    ```bash
    git clone https://github.com/initialh/kasir_app.git
    cd kasir_app
    ```

3.  **Instal Dependensi:**
    ```bash
    flutter pub get
    ```

4.  **Menjalankan Aplikasi:**
    *   **Mode Debug:** Untuk pengembangan dan pengujian cepat.
        ```bash
        flutter run -d <target_device_id>
        # Contoh: flutter run -d macos
        # Contoh: flutter run -d 21051182G (ID perangkat Android fisik)
        ```
    *   **Membangun Rilis Produksi:** Untuk distribusi aplikasi.
        ```bash
        flutter build apk --release       # Android APK
        flutter build ios                 # iOS App Bundle
        flutter build macos               # macOS Desktop App
        # ... dan platform lainnya
        ```

5.  **Catatan Penting untuk Android (Izin Penyimpanan):**
    *   Untuk fungsionalitas Backup/Restore di Android 11 (API 30) ke atas, aplikasi memerlukan izin "Akses semua file" (`MANAGE_EXTERNAL_STORAGE`). Anda mungkin perlu memberikan izin ini secara manual melalui pengaturan aplikasi (`Pengaturan > Aplikasi > [Nama Aplikasi] > Izin > File dan media`).
    *   Untuk Android 10 (API 29) ke bawah, izin penyimpanan standar akan diminta secara otomatis oleh aplikasi.

### Penggunaan Fitur Utama

*   **Login Awal:** Gunakan kredensial admin default (`username: admin`, `password: admin`) untuk instalasi baru.
*   **Navigasi:** Antarmuka navigasi bawah menyediakan akses cepat ke modul utama: Kasir, Produk, Laporan, Pengguna, dan Pengaturan.
*   **Manajemen Data (Backup/Restore):** Akses fitur ini melalui tab "Pengaturan" > "Pengaturan Data".
    *   **Backup:** Pilih "Cadangkan Data" dan tentukan folder tujuan penyimpanan file backup `.db`.
    *   **Restore:** Pilih "Pulihkan Data" dan navigasikan ke file backup `.db` Anda.

## Kontribusi

Kami menyambut kontribusi dari komunitas developer! Jika Anda memiliki ide untuk peningkatan, menemukan bug, atau ingin menambahkan fitur baru, silakan:
1.  Buka [Issue](https://github.com/initialh/kasir_app/issues) baru untuk diskusi.
2.  Ajukan [Pull Request](https://github.com/initialh/kasir_app/pulls) dengan perubahan yang diusulkan.

## Lisensi

Proyek ini didistribusikan di bawah Lisensi MIT. Detail lengkap dapat ditemukan dalam file `LICENSE` di repositori ini.

---

**[initialH](https://github.com/initialh)** – Kontak melalui [hidayatfauzi6@gmail.com](mailto:hidayatfauzi6@gmail.com)
