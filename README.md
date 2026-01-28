# Aplikasi Kasir Modern (Kasir App)

Aplikasi kasir modern yang dikembangkan dengan Flutter, dirancang untuk mengoptimalkan pengelolaan transaksi penjualan, produk, dan laporan secara efisien. Aplikasi ini mendukung tampilan responsif di berbagai perangkat, dilengkapi dengan fitur manajemen pengguna, pencetakan struk, serta kapabilitas backup dan restore data yang canggih.

## Fitur Utama

*   **Manajemen Produk:** Fasilitas lengkap untuk menambah, mengedit, dan menghapus produk, termasuk dukungan untuk gambar produk.
*   **Transaksi Penjualan:** Memungkinkan proses transaksi yang cepat dengan antarmuka keranjang belanja interaktif, perhitungan total otomatis, dan pengelolaan pembayaran serta kembalian.
    *   **Pencetakan Struk:** Desain struk yang ditingkatkan (mencakup nama toko "MD1", alamat "Jl. Kartini Saribudolok", nomor struk numerik, detail pembayaran & kembalian, tanpa pajak). Struk dapat dicetak ulang dari detail transaksi untuk efisiensi penggunaan kertas.
*   **Laporan Penjualan:** Menyajikan laporan penjualan harian, mingguan, dan bulanan yang komprehensif, mencakup ringkasan pendapatan, jumlah transaksi, identifikasi produk terlaris, dan detail transaksi lengkap. Dilengkapi dengan grafik interaktif (line chart) untuk analisis visual.
*   **Manajemen Pengguna:** Mengelola akun pengguna aplikasi dengan penetapan peran (Admin/Kasir) untuk kontrol akses yang granular.
*   **Pengaturan Printer:** Konfigurasi mudah untuk printer thermal guna pencetakan struk penjualan.
    *   **Otomatisasi Koneksi Printer:** Aplikasi secara cerdas mendeteksi dan secara otomatis terhubung ke printer Bluetooth yang tersimpan saat startup. Notifikasi status koneksi printer akan disajikan setelah login berhasil.
*   **Autentikasi Pengguna:** Sistem login yang aman dan terintegrasi.
    *   **Login Admin Default:** Untuk instalasi baru, aplikasi menyediakan login admin default dengan `username: admin` dan `password: admin` untuk memudahkan setup awal tanpa registrasi manual.
*   **Backup & Restore Data:** Fitur vital untuk menjaga integritas data aplikasi.
    *   **Pencadangan Data:** Membuat salinan database aplikasi ke lokasi penyimpanan lokal yang dapat dipilih pengguna.
    *   **Pemulihan Data:** Mengembalikan kondisi database aplikasi dari file backup `.db` yang ada, dengan konfirmasi pemilihan file dari pengguna.
*   **UI Modern & Responsif:** Antarmuka pengguna yang intuitif, estetis, dan adaptif, memastikan pengalaman yang konsisten di berbagai ukuran layar perangkat.

## Teknologi yang Digunakan

*   **Flutter:** Framework UI terkemuka untuk pengembangan aplikasi multi-platform.
*   **Bloc:** Arsitektur manajemen state yang handal dan prediktif.
*   **SQFlite:** Solusi database SQLite lokal untuk penyimpanan data offline yang efisien.
*   **GoRouter:** Implementasi navigasi deklaratif yang canggih.
*   **GetIt:** Lightweight service locator untuk dependency injection.
*   **fl_chart:** Pustaka visualisasi data untuk grafik yang menarik.
*   **intl:** Utilitas untuk lokalisasi, termasuk pemformatan mata uang dan tanggal/waktu.
*   **uuid:** Pustaka untuk menghasilkan pengenal unik universal (UUID).
*   **crypto:** Pustaka kriptografi untuk hashing password secara aman.
*   **permission_handler:** Untuk manajemen izin akses perangkat secara lintas platform.
*   **path_provider:** Untuk mendapatkan jalur direktori file sistem perangkat.
*   **file_picker:** Memungkinkan pengguna untuk memilih file dari penyimpanan perangkat.
*   **image_picker:** Integrasi untuk memilih gambar dari galeri atau kamera.
*   **flutter_image_compress:** Optimasi untuk kompresi gambar.
*   **print_bluetooth_thermal:** Integrasi untuk pencetakan ke printer thermal melalui Bluetooth.
*   **shared_preferences:** Penyimpanan data kunci-nilai sederhana untuk preferensi pengguna.
*   **device_info_plus:** Menyediakan informasi detail tentang perangkat.
*   **esc_pos_utils_plus, image:** Pustaka pendukung untuk formatting ESC/POS dan pemrosesan gambar cetak.

## Perbaikan dan Peningkatan Terkini

*   **Perbaikan Parsing Jumlah Pembayaran:** Mengatasi masalah di dialog konfirmasi pembayaran yang gagal mengurai input numerik dengan pemisah ribuan (misalnya, "50.000").
*   **Perbaikan Laporan Penjualan:** Menyelesaikan `ReportsBloc` ProviderNotFoundException dan masalah tata letak `RenderFlex overflow` serta `Vertical viewport unbounded height`, memastikan detail transaksi ditampilkan dengan benar sesuai periode laporan.
*   **Perbaikan Restore Data:** Mengatasi `PlatformException` pada fitur restore data dengan menggunakan `FileType.any` dan validasi ekstensi `.db` secara manual, meningkatkan kompatibilitas di berbagai perangkat Android.

## Instalasi dan Setup

Pastikan Anda telah menginstal Flutter SDK.

1.  **Clone Repositori:**
    ```bash
    git clone https://github.com/initialh/kasir_app.git
    cd kasir_app
    ```

2.  **Dapatkan Dependensi:**
    ```bash
    flutter pub get
    ```

3.  **Jalankan Aplikasi:**
    *   **Untuk Debugging (misalnya, di macOS):**
        ```bash
        flutter run -d macos
        ```
        Ganti `macos` dengan `android` atau `emulator-id` sesuai kebutuhan.
    *   **Untuk Membangun Aplikasi Rilis (misalnya, Android APK):**
        ```bash
        flutter build apk --release
        ```
        Untuk platform lain:
        ```bash
        flutter build ios
        flutter build macos
        # dll.
        ```
    *   **Catatan Izin Android:** Untuk fitur Backup/Restore di Android 11 (API 30) ke atas, aplikasi akan meminta izin "Akses semua file". Anda mungkin perlu memberikan izin ini secara manual melalui pengaturan aplikasi (`Pengaturan > Aplikasi > [Nama Aplikasi] > Izin > File dan media`). Untuk Android 10 (API 29) ke bawah, izin penyimpanan standar akan diminta.

## Penggunaan

*   **Login Awal:** Untuk penggunaan pertama, gunakan kredensial admin default: `username: admin`, `password: admin`.
*   **Navigasi:** Gunakan bilah navigasi bawah untuk berpindah antar modul (Kasir, Produk, Laporan, Pengguna, Pengaturan).
*   **Akses Pengaturan Data:** Dari tab "Pengaturan", pilih "Pengaturan Data" untuk mengakses fungsi Backup dan Restore.
    *   **Backup Data:** Tekan "Cadangkan Data" dan pilih folder tujuan penyimpanan file backup.
    *   **Restore Data:** Tekan "Pulihkan Data" dan pilih file backup `.db` dari penyimpanan perangkat Anda.
*   **Transaksi:** Pilih produk dari daftar, tambahkan ke keranjang, tentukan jumlah pembayaran, dan selesaikan transaksi.
*   **Laporan:** Jelajahi laporan harian, mingguan, atau bulanan untuk mendapatkan analisis penjualan yang mendalam.

## Kontribusi

Kontribusi dalam bentuk pelaporan bug, saran fitur, atau pull request sangat kami hargai. Silakan buka issue di repositori ini.

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT. Lihat file `LICENSE` untuk informasi detail.