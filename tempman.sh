#!/bin/bash

# Temporary File Manager
# Script untuk mengelola file/folder sementara dengan auto-delete

# Konfigurasi
REGISTRY_FILE="$HOME/.temp_file_registry"
SCRIPT_NAME="tempman"

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fungsi untuk menampilkan bantuan
show_help() {
    echo -e "${BLUE}Temporary File Manager${NC}"
    echo "Kelola file/folder sementara dengan auto-delete"
    echo
    echo "Penggunaan:"
    echo "  $SCRIPT_NAME add <path> <days>     - Daftarkan file/folder untuk dihapus dalam <days> hari"
    echo "  $SCRIPT_NAME add <path> <date>     - Daftarkan file/folder untuk dihapus pada tanggal tertentu (YYYY-MM-DD)"
    echo "  $SCRIPT_NAME list                  - Tampilkan daftar file yang terdaftar"
    echo "  $SCRIPT_NAME cleanup               - Hapus file yang sudah expired"
    echo "  $SCRIPT_NAME remove <path>         - Hapus file dari registry (tanpa menghapus file)"
    echo "  $SCRIPT_NAME status                - Tampilkan status file yang akan expired hari ini"
    echo "  $SCRIPT_NAME install               - Install auto-cleanup cron job"
    echo "  $SCRIPT_NAME help                  - Tampilkan bantuan ini"
    echo
    echo "Contoh:"
    echo "  $SCRIPT_NAME add \"/home/user/project temp\" 7"
    echo "  $SCRIPT_NAME add \"/home/user/data.zip\" 2024-12-31"
    echo
    echo "Catatan:"
    echo "  - Gunakan tanda kutip (\") untuk path yang mengandung spasi"
    echo "  - Script akan membuat backup registry otomatis"
}

# Fungsi untuk menambahkan file ke registry
add_file() {
    # Handle multiple arguments for path with spaces
    local args=("$@")
    local time_spec="${args[-1]}"  # Last argument is time
    local file_path=""
    
    # Build file path from all arguments except the last one
    for (( i=0; i<${#args[@]}-1; i++ )); do
        if [[ $i -eq 0 ]]; then
            file_path="${args[i]}"
        else
            file_path="$file_path ${args[i]}"
        fi
    done
    
    if [[ -z "$file_path" || -z "$time_spec" ]]; then
        echo -e "${RED}Error: Path dan waktu harus diisi${NC}"
        echo "Gunakan: $SCRIPT_NAME add <path> <days|YYYY-MM-DD>"
        echo "Untuk path dengan spasi, gunakan tanda kutip: \"path with spaces\""
        return 1
    fi
    
    # Konversi path ke absolute path
    file_path=$(realpath "$file_path" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Path tidak valid: $1${NC}"
        return 1
    fi
    
    # Cek apakah file/folder ada
    if [[ ! -e "$file_path" ]]; then
        echo -e "${YELLOW}Warning: File/folder tidak ditemukan: $file_path${NC}"
        read -p "Tetap daftarkan? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Parse time specification
    local delete_date
    # Cek apakah input adalah angka (hari)
    if [[ "$time_spec" =~ ^[0-9]+$ ]] && [[ "$time_spec" -gt 0 ]]; then
        # Jika input adalah angka (hari)
        delete_date=$(date -d "+${time_spec} days" +%Y-%m-%d)
        echo -e "${BLUE}Info: File akan dihapus dalam $time_spec hari (tanggal: $delete_date)${NC}"
    # Cek apakah input adalah tanggal YYYY-MM-DD
    elif [[ "$time_spec" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Jika input adalah tanggal (YYYY-MM-DD)
        delete_date="$time_spec"
        # Validasi tanggal
        if ! date -d "$delete_date" >/dev/null 2>&1; then
            echo -e "${RED}Error: Format tanggal tidak valid: $delete_date${NC}"
            return 1
        fi
        local days_diff=$(( ($(date -d "$delete_date" +%s) - $(date +%s)) / 86400 ))
        echo -e "${BLUE}Info: File akan dihapus pada $delete_date ($days_diff hari dari sekarang)${NC}"
    else
        echo -e "${RED}Error: Format waktu tidak valid!${NC}"
        echo "Gunakan:"
        echo "  - Angka untuk hari (contoh: 1, 7, 30)"
        echo "  - Tanggal format YYYY-MM-DD (contoh: 2024-12-31)"
        echo "Input yang diterima: '$time_spec'"
        return 1
    fi
    
    # Cek apakah sudah ada di registry
    if grep -q "^$file_path|" "$REGISTRY_FILE" 2>/dev/null; then
        echo -e "${YELLOW}File sudah terdaftar. Update tanggal hapus...${NC}"
        # Hapus entry lama
        grep -v "^$file_path|" "$REGISTRY_FILE" > "$REGISTRY_FILE.tmp" 2>/dev/null
        mv "$REGISTRY_FILE.tmp" "$REGISTRY_FILE" 2>/dev/null
    fi
    
    # Tambahkan ke registry
    echo "$file_path|$delete_date|$(date +%Y-%m-%d)" >> "$REGISTRY_FILE"
    echo -e "${GREEN}✓ File terdaftar: $file_path${NC}"
    echo -e "${GREEN}  Akan dihapus pada: $delete_date${NC}"
}

# Fungsi untuk menampilkan daftar file
list_files() {
    if [[ ! -f "$REGISTRY_FILE" || ! -s "$REGISTRY_FILE" ]]; then
        echo -e "${YELLOW}Tidak ada file yang terdaftar${NC}"
        return 0
    fi
    
    echo -e "${BLUE}=== Daftar File Temporary ===${NC}"
    echo
    
    local current_date=$(date +%Y-%m-%d)
    local count=0
    
    while IFS='|' read -r file_path delete_date register_date; do
        [[ -z "$file_path" ]] && continue
        count=$((count + 1))
        
        # Hitung hari tersisa
        local days_left=$(( ($(date -d "$delete_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))
        
        # Warna berdasarkan status
        local color="$GREEN"
        local status="OK"
        if [[ $days_left -lt 0 ]]; then
            color="$RED"
            status="EXPIRED"
        elif [[ $days_left -le 3 ]]; then
            color="$YELLOW"
            status="SOON"
        fi
        
        # Cek apakah file masih ada
        local exists="✓"
        if [[ ! -e "$file_path" ]]; then
            exists="✗"
        fi
        
        echo -e "${color}$count. [$exists] $file_path${NC}"
        echo -e "   Hapus: $delete_date ($days_left hari) - Status: $status"
        echo -e "   Didaftar: $register_date"
        echo
    done < "$REGISTRY_FILE"
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}Tidak ada file yang terdaftar${NC}"
    fi
}

# Fungsi untuk cleanup file yang expired
cleanup_files() {
    if [[ ! -f "$REGISTRY_FILE" || ! -s "$REGISTRY_FILE" ]]; then
        echo -e "${YELLOW}Tidak ada file untuk di-cleanup${NC}"
        return 0
    fi
    
    local current_date=$(date +%Y-%m-%d)
    local temp_file=$(mktemp)
    local deleted_count=0
    local error_count=0
    
    echo -e "${BLUE}=== Cleanup File Expired ===${NC}"
    echo "Tanggal saat ini: $current_date"
    echo
    
    while IFS='|' read -r file_path delete_date register_date; do
        [[ -z "$file_path" ]] && continue
        
        if [[ "$delete_date" < "$current_date" || "$delete_date" == "$current_date" ]]; then
            echo -e "${YELLOW}Menghapus: $file_path${NC}"
            
            if [[ -e "$file_path" ]]; then
                if rm -rf "$file_path" 2>/dev/null; then
                    echo -e "${GREEN}  ✓ Berhasil dihapus${NC}"
                    deleted_count=$((deleted_count + 1))
                else
                    echo -e "${RED}  ✗ Gagal menghapus${NC}"
                    error_count=$((error_count + 1))
                    # Simpan entry yang gagal dihapus
                    echo "$file_path|$delete_date|$register_date" >> "$temp_file"
                fi
            else
                echo -e "${BLUE}  ~ File tidak ditemukan (sudah dihapus manual)${NC}"
                deleted_count=$((deleted_count + 1))
            fi
        else
            # Simpan entry yang belum expired
            echo "$file_path|$delete_date|$register_date" >> "$temp_file"
        fi
    done < "$REGISTRY_FILE"
    
    # Update registry file
    mv "$temp_file" "$REGISTRY_FILE" 2>/dev/null
    
    echo
    echo -e "${GREEN}Cleanup selesai:${NC}"
    echo -e "  File terhapus: $deleted_count"
    if [[ $error_count -gt 0 ]]; then
        echo -e "  ${RED}Error: $error_count${NC}"
    fi
}

# Fungsi untuk menghapus entry dari registry
remove_entry() {
    local file_path="$1"
    
    if [[ -z "$file_path" ]]; then
        echo -e "${RED}Error: Path harus diisi${NC}"
        return 1
    fi
    
    file_path=$(realpath "$file_path" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        file_path="$1"  # Gunakan path asli jika realpath gagal
    fi
    
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        echo -e "${RED}Registry file tidak ditemukan${NC}"
        return 1
    fi
    
    if grep -q "^$file_path|" "$REGISTRY_FILE"; then
        grep -v "^$file_path|" "$REGISTRY_FILE" > "$REGISTRY_FILE.tmp"
        mv "$REGISTRY_FILE.tmp" "$REGISTRY_FILE"
        echo -e "${GREEN}✓ Entry dihapus dari registry: $file_path${NC}"
    else
        echo -e "${YELLOW}Entry tidak ditemukan di registry${NC}"
    fi
}

# Fungsi untuk menampilkan status file yang akan expired hari ini
show_status() {
    if [[ ! -f "$REGISTRY_FILE" || ! -s "$REGISTRY_FILE" ]]; then
        echo -e "${YELLOW}Tidak ada file yang terdaftar${NC}"
        return 0
    fi
    
    local current_date=$(date +%Y-%m-%d)
    local today_count=0
    local soon_count=0
    
    echo -e "${BLUE}=== Status File Temporary ===${NC}"
    echo "Tanggal: $current_date"
    echo
    
    while IFS='|' read -r file_path delete_date register_date; do
        [[ -z "$file_path" ]] && continue
        
        local days_left=$(( ($(date -d "$delete_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))
        
        if [[ $days_left -eq 0 ]]; then
            today_count=$((today_count + 1))
            echo -e "${RED}HARI INI: $file_path${NC}"
        elif [[ $days_left -le 3 && $days_left -gt 0 ]]; then
            soon_count=$((soon_count + 1))
            echo -e "${YELLOW}${days_left} HARI LAGI: $file_path${NC}"
        fi
    done < "$REGISTRY_FILE"
    
    echo
    echo -e "${BLUE}Ringkasan:${NC}"
    echo -e "  File expired hari ini: $today_count"
    echo -e "  File akan expired 1-3 hari: $soon_count"
    
    if [[ $today_count -gt 0 ]]; then
        echo
        echo -e "${YELLOW}Jalankan '$SCRIPT_NAME cleanup' untuk menghapus file yang expired${NC}"
    fi
}

# Fungsi untuk install cron job
install_cron() {
    local script_path=$(realpath "$0")
    local cron_entry="0 9 * * * $script_path cleanup >/dev/null 2>&1"
    
    # Cek apakah cron job sudah ada
    if crontab -l 2>/dev/null | grep -q "$script_path cleanup"; then
        echo -e "${YELLOW}Cron job sudah terinstall${NC}"
        return 0
    fi
    
    # Tambahkan cron job
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Auto-cleanup cron job berhasil diinstall${NC}"
        echo -e "${GREEN}  Cleanup otomatis akan jalan setiap hari jam 09:00${NC}"
    else
        echo -e "${RED}✗ Gagal menginstall cron job${NC}"
        return 1
    fi
}

# Main script
case "$1" in
    add)
        shift  # Remove 'add' from arguments
        add_file "$@"  # Pass all remaining arguments
        ;;
    list|ls)
        list_files
        ;;
    cleanup|clean)
        cleanup_files
        ;;
    remove|rm)
        remove_entry "$2"
        ;;
    status|st)
        show_status
        ;;
    install)
        install_cron
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Perintah tidak dikenal: $1${NC}"
        echo "Gunakan '$SCRIPT_NAME help' untuk melihat bantuan"
        exit 1
        ;;
esac