#!/bin/bash
# Pi-Linux Download Organizer
# Automatically sorts downloaded files into categorized folders
# Uses inotifywait for real-time monitoring

set -euo pipefail

DOWNLOADS_DIR="${HOME}/Descargas"
LOG_FILE="${HOME}/.local/share/pi-linux/download-organizer.log"

# Ensure downloads directory exists
mkdir -p "$DOWNLOADS_DIR"

# Create category folders
mkdir -p "$DOWNLOADS_DIR/Documentos"
mkdir -p "$DOWNLOADS_DIR/Imagenes"
mkdir -p "$DOWNLOADS_DIR/Videos"
mkdir -p "$DOWNLOADS_DIR/Musica"
mkdir -p "$DOWNLOADS_DIR/Comprimidos"
mkdir -p "$DOWNLOADS_DIR/Aplicaciones"
mkdir -p "$DOWNLOADS_DIR/Otros"

# Logging helper
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

log_msg "=== Pi-Linux Download Organizer started ==="
log_msg "Watching: $DOWNLOADS_DIR"

# Function to determine target folder based on extension
get_target_folder() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # lowercase

    case "$ext" in
        pdf|doc|docx|odt|txt|rtf|epub|mobi|azw|azw3|tex|md|csv|xls|xlsx|ods|ppt|pptx|odp)
            echo "Documentos"
            ;;
        jpg|jpeg|png|gif|webp|svg|bmp|tiff|tif|ico|raw|cr2|nef|heic|avif)
            echo "Imagenes"
            ;;
        mp4|mkv|avi|mov|wmv|flv|webm|m4v|mpg|mpeg|3gp|ts)
            echo "Videos"
            ;;
        mp3|flac|ogg|wav|aac|m4a|wma|opus|aiff|alac)
            echo "Musica"
            ;;
        zip|tar|gz|tgz|bz2|tbz|xz|txz|7z|rar|lz|lzma|zst)
            echo "Comprimidos"
            ;;
        appimage|deb|rpm|pkg|exe|msi|dmg|jar|app)
            echo "Aplicaciones"
            ;;
        *)
            echo "Otros"
            ;;
    esac
}

# Function to safely move a file
organize_file() {
    local file="$1"
    local basename
    basename="$(basename "$file")"

    # Skip if file no longer exists
    [[ -f "$file" ]] || return 0

    # Skip if it's a directory
    [[ -d "$file" ]] && return 0

    # Skip files in subdirectories (only organize files directly in Downloads)
    [[ "$(dirname "$file")" != "$DOWNLOADS_DIR" ]] && return 0

    # Skip hidden files and our own category folders
    [[ "$basename" == .* ]] && return 0
    [[ "$basename" =~ ^(Documentos|Imagenes|Videos|Musica|Comprimidos|Aplicaciones|Otros)$ ]] && return 0

    # Wait a moment to ensure download is complete (check if file is still being written)
    local initial_size
    initial_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    sleep 2
    local final_size
    final_size=$(stat -c%s "$file" 2>/dev/null || echo 0)

    if [[ "$initial_size" != "$final_size" ]]; then
        log_msg "File still downloading, skipping: $basename"
        return 0
    fi

    # Skip if file was removed during wait
    [[ -f "$file" ]] || return 0

    local folder
    folder="$(get_target_folder "$basename")"
    local target="$DOWNLOADS_DIR/$folder/$basename"

    # Handle name collisions
    if [[ -f "$target" ]]; then
        local name="${basename%.*}"
        local ext="${basename##*.}"
        local counter=1
        if [[ "$name" == "$basename" ]]; then
            # No extension
            while [[ -f "$DOWNLOADS_DIR/$folder/${name}_${counter}" ]]; do
                ((counter++))
            done
            target="$DOWNLOADS_DIR/$folder/${name}_${counter}"
        else
            while [[ -f "$DOWNLOADS_DIR/$folder/${name}_${counter}.${ext}" ]]; do
                ((counter++))
            done
            target="$DOWNLOADS_DIR/$folder/${name}_${counter}.${ext}"
        fi
    fi

    if mv -n "$file" "$target" 2>/dev/null; then
        log_msg "Moved: $basename → $folder/"
    else
        log_msg "Failed to move: $basename"
    fi
}

# Organize existing files on startup
log_msg "Organizing existing files..."
for file in "$DOWNLOADS_DIR"/*; do
    [[ -f "$file" ]] && organize_file "$file"
done
log_msg "Existing files organized. Waiting for new downloads..."

# Watch for new files using inotifywait
if ! command -v inotifywait &>/dev/null; then
    log_msg "ERROR: inotifywait not found. Install inotify-tools."
    exit 1
fi

inotifywait -m "$DOWNLOADS_DIR" -e create -e moved_to --format '%w%f' |
while read -r file; do
    # Wait for download to complete
    sleep 3
    organize_file "$file"
done
