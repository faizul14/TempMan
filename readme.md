# TempMan - Temporary File Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

**TempMan** adalah sistem CLI (Command Line Interface) untuk mengelola file dan folder sementara dengan fitur auto-delete berdasarkan tanggal yang ditentukan. Sangat cocok untuk developer dan pengguna yang sering membuat file/folder sementara dan lupa menghapusnya.

## 🌟 Fitur Utama

- ✅ **Auto-delete berdasarkan tanggal** - Set file untuk dihapus otomatis
- ✅ **Fleksibel input waktu** - Gunakan hari (7) atau tanggal spesifik (2024-12-31)
- ✅ **Path dengan spasi** - Mendukung path yang mengandung spasi tanpa tanda kutip
- ✅ **Visual status** - Warna-warna untuk status yang berbeda
- ✅ **Auto-cleanup cron job** - Pembersihan otomatis harian
- ✅ **Safety checks** - Konfirmasi untuk operasi berbahaya
- ✅ **Fuzzy matching** - Pencarian file yang fleksibel
- ✅ **Registry backup** - Data tersimpan aman

## 📋 Requirements

- **OS**: Linux (Ubuntu, Debian, Linux Mint, dll.)
- **Shell**: Bash 4.0+
- **Tools**: `date`, `grep`, `crontab` (biasanya sudah terinstall)
- **Permissions**: User dengan akses crontab untuk auto-cleanup

## 🚀 Instalasi

### Metode 1: Install Global (Recommended)

```bash
# Download script
curl -o tempman.sh https://raw.githubusercontent.com/faizul14/TempMan/master/tempman.sh

# Atau jika sudah download, copy ke system path
sudo cp tempman.sh /usr/local/bin/tempman
sudo chmod +x /usr/local/bin/tempman

# Test instalasi
tempman help
```

### Metode 2: Install User Local

```bash
# Copy ke home directory
cp tempman.sh ~/tempman.sh
chmod +x ~/tempman.sh

# Buat alias di .bashrc
echo 'alias tempman="~/tempman.sh"' >> ~/.bashrc
source ~/.bashrc

# Test instalasi
tempman help
```

### Metode 3: Run Langsung

```bash
chmod +x tempman.sh
./tempman.sh help
```

## 📖 Cara Penggunaan

### Perintah Dasar

```bash
tempman help                    # Tampilkan bantuan
tempman add <path> <time>       # Daftarkan file/folder
tempman list                    # Lihat daftar file terdaftar
tempman cleanup                 # Hapus file yang expired
tempman status                  # Lihat status file hari ini
tempman remove <path>           # Hapus dari registry
tempman install                 # Install auto-cleanup cron
```

### 1. Mendaftarkan File/Folder

#### Dengan Input Hari:
```bash
# File akan dihapus dalam 7 hari
tempman add /home/user/project_temp 7

# Folder downloads akan dihapus dalam 1 hari
tempman add ~/Downloads/temp_data 1

# Path dengan spasi (tanpa perlu tanda kutip)
tempman add /home/user/My Project Folder 30
```

#### Dengan Tanggal Spesifik:
```bash
# Dihapus pada tanggal tertentu
tempman add /home/user/meeting_notes.pdf 2024-12-31

# Backup yang akan dihapus akhir tahun
tempman add /backup/old_files 2024-12-25
```

### 2. Melihat Daftar File

```bash
tempman list
# atau
tempman ls
```

**Output contoh:**
```
=== Daftar File Temporary ===

1. [✓] /home/user/project_temp
   Hapus: 2025-09-01 (7 hari) - Status: OK
   Didaftar: 2025-08-25

2. [✗] /home/user/old_backup
   Hapus: 2025-08-26 (1 hari) - Status: SOON
   Didaftar: 2025-08-25
```

**Legend:**
- `✓` = File/folder ada
- `✗` = File/folder tidak ditemukan
- **OK** = Masih aman (>3 hari)
- **SOON** = Akan expired 1-3 hari
- **EXPIRED** = Sudah lewat tanggal

### 3. Cleanup Manual

```bash
tempman cleanup
```

**Output contoh:**
```
=== Cleanup File Expired ===
Tanggal saat ini: 2025-08-26

Menghapus: /home/user/temp_project
  ✓ Berhasil dihapus

Cleanup selesai:
  File terhapus: 1
```

### 4. Cek Status Harian

```bash
tempman status
```

**Output contoh:**
```
=== Status File Temporary ===
Tanggal: 2025-08-26

HARI INI: /home/user/backup_old
2 HARI LAGI: /home/user/temp_download

Ringkasan:
  File expired hari ini: 1
  File akan expired 1-3 hari: 1
```

### 5. Menghapus dari Registry

```bash
# Hapus entry tanpa menghapus file fisik
tempman remove /home/user/project_temp

# Dengan path yang mengandung spasi
tempman remove /home/user/My Project Folder
```

### 6. Install Auto-Cleanup

```bash
tempman install
```

Ini akan menambahkan cron job yang menjalankan cleanup setiap hari jam 09:00.

## 🗂️ File Registry

Data tersimpan di `~/.temp_file_registry` dengan format:
```
/absolute/path/to/file|2025-12-31|2025-08-25
```

Format: `path|delete_date|register_date`

## ⚙️ Konfigurasi

### Mengubah Waktu Auto-Cleanup

Edit cron job secara manual:
```bash
crontab -e
```

Ubah waktu sesuai kebutuhan:
```bash
# Cleanup setiap hari jam 02:00
0 2 * * * /usr/local/bin/tempman cleanup >/dev/null 2>&1

# Cleanup setiap 6 jam
0 */6 * * * /usr/local/bin/tempman cleanup >/dev/null 2>&1
```

### Backup dan Restore Registry

```bash
# Backup registry
cp ~/.temp_file_registry ~/.temp_file_registry.backup

# Restore registry
cp ~/.temp_file_registry.backup ~/.temp_file_registry
```

## 💡 Tips dan Tricks

### 1. Workflow Development Project

```bash
# Saat mulai project baru
mkdir ~/projects/temp_client_work
tempman add ~/projects/temp_client_work 14

# File download sementara
tempman add ~/Downloads/client_assets.zip 3

# Test data
tempman add ~/test_data 1
```

### 2. Pembersihan Berkala

```bash
# Cek status setiap pagi
tempman status

# Cleanup manual jika perlu
tempman cleanup

# Lihat daftar lengkap
tempman list
```

### 3. Batch Operations

```bash
# Daftarkan beberapa folder sekaligus
for dir in ~/Downloads/temp_*; do
    tempman add "$dir" 7
done
```

## 🐛 Troubleshooting

### File Tidak Ditemukan saat Add

```bash
Warning: File/folder tidak ditemukan: /path/to/file
Tetap daftarkan? (y/N):
```

**Solusi**: 
- Pilih `y` jika file akan dibuat nanti
- Periksa path spelling
- Gunakan tab completion

### Entry Tidak Ditemukan saat Remove

```bash
Entry tidak ditemukan di registry
```

**Solusi**:
- Script akan menampilkan debug info dan daftar path
- Gunakan fuzzy matching
- Copy exact path dari `tempman list`

### Permission Denied saat Cleanup

**Solusi**:
```bash
# Periksa permission file
ls -la /path/to/file

# Ubah permission jika diperlukan
chmod -R u+w /path/to/file
```

### Cron Job Tidak Jalan

**Solusi**:
```bash
# Cek cron job aktif
crontab -l

# Cek log cron (Ubuntu/Debian)
grep CRON /var/log/syslog | tail -10

# Test manual
tempman cleanup
```

## 🔧 Advanced Usage

### Custom Registry Location

Edit script dan ubah variabel:
```bash
REGISTRY_FILE="$HOME/custom/.temp_registry"
```

### Integration dengan Git Hooks

**Pre-commit hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit
tempman status
```

### Integration dengan IDE

**VS Code Task (.vscode/tasks.json):**
```json
{
    "label": "Register Temp Folder",
    "type": "shell",
    "command": "tempman",
    "args": ["add", "${workspaceFolder}/temp", "7"]
}
```

## 📊 Status Codes

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | File not found |
| 4 | Permission denied |

## 🤝 Contributing

1. Fork repository
2. Buat feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -am 'Add amazing feature'`
4. Push branch: `git push origin feature/amazing-feature`
5. Submit Pull Request

## 📝 Changelog

### v1.0.0 (2025-08-25)
- ✨ Initial release
- ✨ Basic add/remove/list functionality
- ✨ Auto-cleanup dengan cron
- ✨ Path dengan spasi support
- ✨ Fuzzy matching untuk remove
- ✨ Visual status indicators

### Planned Features
- 📋 Export/import registry
- 🔄 Undo delete functionality
- 📊 Statistics dan reporting
- 🏷️ Tag system untuk kategorisasi
- 📱 Desktop notifications

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Created with ❤️ by [Faezol MP](https://github.com/faizul14)

## 🙏 Acknowledgments

- Inspired by Unix `at` command
- Thanks to the Bash community for scripting best practices
- Linux Mint community for testing feedback

---

**⭐ Jika script ini berguna, jangan lupa star repository ini!**

**🐛 Found a bug? [Report it here](https://github.com/faizul14/TempMan/issues)**

**💡 Have suggestions? [Start a discussion](https://github.com/faizul14/TempMan/discussions)**