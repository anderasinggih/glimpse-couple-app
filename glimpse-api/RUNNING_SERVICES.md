# Panduan Menjalankan Layanan di Screen VPS (Glimpse API)

Dokumen ini menjelaskan cara mengelola dan menjalankan kembali layanan **Laravel Octane (Roadrunner)**, **Queue Worker**, dan **Laravel Reverb (Websockets)** menggunakan utilitas `screen` di server VPS agar terus berjalan di latar belakang (background).

---

## 1. Bersihkan Screen yang Mati (Dead Screens)

Jika Anda melihat pesan `(Dead ???)` pada output `screen -ls`, bersihkan terlebih dahulu socket screen yang sudah mati dengan menjalankan perintah:

```bash
screen -wipe
```

---

## 2. Menjalankan Layanan

Selalu jalankan setiap layanan di dalam session `screen` yang terpisah agar tetap berjalan setelah Anda keluar dari SSH.

### A. Laravel Octane (Port 8001)

Layanan server utama menggunakan Octane + Roadrunner di port 8001.

1. **Buat screen session baru:**
   ```bash
   screen -S octane-8001
   ```
2. **Pindah ke folder project Anda (PENTING!):**
   ```bash
   cd /path/to/your/project-directory
   ```
   *(Ganti `/path/to/your/project-directory` dengan lokasi folder project Anda di VPS, misalnya `cd ~/glimpse-api` atau tempat Anda menaruh project).*
3. **Jalankan Laravel Octane:**
   ```bash
   php artisan octane:start --server=roadrunner --host=127.0.0.1 --port=8001 --workers=1
   ```
4. **Detach dari screen (Keluar tanpa mematikan proses):**
   * Tekan tombol **`Ctrl` + `A`**, lalu lepas dan tekan tombol **`D`**.

untuk reload
pkill -9 -f rr
   pkill -9 -f roadrunner
   

   screen -ls | grep octane-8001 | cut -d. -f1 | awk '{print $1}' | xargs kill
screen -wipe

---

### B. Laravel Queue Worker

Layanan untuk memproses job antrean (queue) di latar belakang.

1. **Buat screen session baru:**
   ```bash
   screen -S queue-worker
   ```
2. **Pindah ke folder project Anda (PENTING!):**
   ```bash
   cd /path/to/your/project-directory
   ```
3. **Jalankan Queue Worker:**
   ```bash
   php artisan queue:work
   ```
   *(Atau gunakan `php artisan queue:listen` jika sedang dalam tahap development aktif).*
4. **Detach dari screen:**
   * Tekan tombol **`Ctrl` + `A`**, lalu lepas dan tekan tombol **`D`**.

---

### C. Laravel Reverb (WebSockets Server)

Layanan untuk mengelola koneksi real-time / WebSocket.

1. **Buat screen session baru:**
   ```bash
   screen -S reverb
   ```

2. **Pindah ke folder project Anda (PENTING!):**
   ```bash
   cd /path/to/your/project-directory
   ```
3. **Jalankan Reverb Server:**
   ```bash
   php artisan reverb:start --host=0.0.0.0 --port=8080

   ```
4. **Detach dari screen:**
   * Tekan tombol **`Ctrl` + `A`**, lalu lepas dan tekan tombol **`D`**.

---

## 3. Manajemen & Perintah Bermanfaat Screen

Berikut adalah cheatsheet untuk memantau dan mengelola session `screen`:

| Perintah | Deskripsi |
| :--- | :--- |
| `screen -ls` | Melihat daftar semua screen session yang sedang berjalan. |
| `screen -r <nama_screen>` | Masuk kembali (re-attach) ke screen tertentu (Contoh: `screen -r octane-8001`). |
| **`Ctrl` + `A`**, lalu **`D`** | Keluar dari screen tanpa mematikan proses (Detach). |
| `exit` | Hentikan dan tutup session screen secara permanen (dijalankan saat berada di dalam screen). |
| `screen -XS <nama_screen> quit` | Mematikan screen tertentu dari luar secara paksa. |
| `screen -wipe` | Membersihkan screen-screen yang sudah mati/terputus. |

---

## 4. Cara Melakukan Update Kode (Deployment Ringkas)

Jika Anda melakukan pull kode terbaru dari Git, biasanya Anda perlu me-restart layanan-layanan di atas agar perubahan kode PHP langsung diterapkan oleh Octane dan Queue Worker:

1. Masuk ke screen masing-masing (misal: `screen -r octane-8001`).
2. Matikan dengan **`Ctrl` + `C`**.
3. Jalankan kembali perintah start-nya.
4. Detach kembali dengan **`Ctrl` + `A`** lalu **`D`**.
