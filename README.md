# Kasir App

Aplikasi kasir modern yang dibangun dengan Flutter, dirancang untuk membantu pengelolaan transaksi penjualan, produk, dan laporan secara efisien. Aplikasi ini mendukung tampilan responsif untuk perangkat mobile dan desktop, serta dilengkapi dengan fitur manajemen pengguna dan pencetakan struk.

## Fitur Utama

*   **Manajemen Produk:** Tambah, edit, dan hapus produk dengan mudah, termasuk gambar produk.
*   **Transaksi Penjualan:** Proses transaksi cepat dengan keranjang belanja interaktif, perhitungan total, pembayaran, dan kembalian otomatis.
    *   **Peningkatan Cetak Struk:** Desain struk lebih baik (nama toko "MD1", alamat "Jl.kartini Saribudolok", nomor struk numerik, detail pembayaran & kembalian, tanpa pajak). Penggunaan kertas lebih efisien. Struk dapat dicetak ulang dari detail transaksi.
*   **Laporan Penjualan:** Lihat laporan penjualan harian, mingguan, dan bulanan dengan ringkasan pendapatan, jumlah transaksi, produk terlaris, dan detail transaksi. Dilengkapi dengan grafik interaktif (line chart) yang dapat disembunyikan/ditampilkan.
*   **Manajemen Pengguna:** Kelola pengguna aplikasi dengan peran (admin/kasir).
*   **Pengaturan Printer:** Konfigurasi printer thermal untuk pencetakan struk.
    *   **Otomatisasi Printer:** Aplikasi akan mencoba mendeteksi dan menyambung secara otomatis ke printer Bluetooth yang tersimpan saat startup. Notifikasi status koneksi printer akan ditampilkan setelah login berhasil.
*   **Autentikasi:** Sistem login yang aman.
*   **UI Modern & Responsif:** Antarmuka pengguna yang segar dan adaptif untuk berbagai ukuran layar.

## Teknologi yang Digunakan

*   **Flutter:** Framework UI untuk membangun aplikasi multi-platform.
*   **Bloc:** Untuk manajemen state yang prediktif dan teruji.
*   **SQFlite:** Database lokal untuk penyimpanan data offline.
*   **GoRouter:** Untuk navigasi yang deklaratif.
*   **GetIt:** Untuk dependency injection.
*   **fl_chart:** Untuk visualisasi data grafik.
*   **intl:** Untuk pemformatan mata uang dan tanggal/waktu.
*   **image_picker:** Untuk memilih gambar dari galeri.
*   **flutter_image_compress:** Untuk kompresi gambar.
*   **blue_thermal_printer:** Untuk integrasi printer thermal.
*   **shared_preferences:** Untuk penyimpanan data sederhana (misalnya, status login).
*   **uuid:** Untuk menghasilkan ID unik.
*   **crypto:** Untuk hashing password.

## Perbaikan dan Peningkatan

*   **Perbaikan Parsing Jumlah Pembayaran:** Mengatasi masalah di dialog konfirmasi pembayaran di mana input numerik dengan pemisah ribuan (misalnya, "50.000") tidak diurai dengan benar.
*   **Perbaikan Laporan Penjualan:** Menyelesaikan kesalahan terkait `ReportsBloc` ProviderNotFoundException dan masalah tata letak `RenderFlex overflow` serta `Vertical viewport unbounded height`, memastikan semua detail transaksi ditampilkan dan dapat digulir sesuai periode laporan yang dipilih.

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
    *   **Untuk Debugging:**
        ```bash
        flutter run
        ```
    *   **Untuk Membangun Aplikasi (contoh Android):**
        ```bash
        flutter build apk --release
        ```
        Atau untuk platform lain:
        ```bash
        flutter build ios
        flutter build macos
        flutter build web
        flutter build linux
        flutter build windows
        ```

## Penggunaan

*   **Login:** Gunakan kredensial default (jika ada) atau daftar pengguna baru melalui manajemen pengguna (jika sudah login sebagai admin).
*   **Navigasi:** Gunakan bilah navigasi atau tombol di `AppBar` untuk berpindah antar halaman (Kasir, Produk, Pengguna, Laporan, Pengaturan Printer).
*   **Transaksi:** Pilih produk dari daftar, tambahkan ke keranjang, masukkan jumlah pembayaran, dan proses transaksi.
*   **Laporan:** Pilih jenis laporan (Harian, Mingguan, Bulanan) untuk melihat ringkasan penjualan dan grafik.

## Kontribusi

Kontribusi sangat dihargai! Jika Anda menemukan bug atau memiliki saran fitur, silakan buka issue atau kirim pull request.

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT. Lihat file `LICENSE` untuk detail lebih lanjut.
