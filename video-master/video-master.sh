#!/bin/bash

# ============================================================
# VIDEO MASTER
# Video Download & Segment Extraction Toolkit
# ============================================================

# Interactive scripts should generally avoid set -e to prevent menu crashes
# However, we can use set -u to catch unbound variables
set -u

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.yt_clip_config"
DEFAULT_FALLBACK="$HOME/Downloads"

# Ensure we have our default vars
DEFAULT_DIR=""
DEFAULT_VIDEO_FORMAT=""
DEFAULT_AUDIO_FORMAT=""
USER_DIR=""
OUTPUT_DIR=""

pause() {
    echo -e "\n${YELLOW}Druk op Enter om door te gaan...${NC}"
    read -r
}

check_dependencies() {
    local missing=0

    if ! command -v yt-dlp &> /dev/null; then
        echo -e "${RED}Fout: yt-dlp is niet geïnstalleerd.${NC}"
        missing=1
    fi

    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}Fout: ffmpeg is niet geïnstalleerd.${NC}"
        missing=1
    fi

    if ! command -v ffprobe &> /dev/null; then
        echo -e "${RED}Fout: ffprobe is niet geïnstalleerd.${NC}"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        echo -e "\n${YELLOW}Installeer alstublieft de ontbrekende afhankelijkheden:${NC}"
        echo -e "${CYAN}Mac (Homebrew):${NC}"
        echo "brew install yt-dlp ffmpeg"
        echo -e "\n${CYAN}Linux (APT):${NC}"
        echo "sudo apt install yt-dlp ffmpeg"
        echo -e "\n${CYAN}Python (pip):${NC}"
        echo "pip install yt-dlp"
        echo "ffmpeg en ffprobe moeten via de pakketbeheerder van het systeem worden geïnstalleerd."

        echo -e "\nDruk op Enter om terug te keren naar het hoofdmenu..."
        read -r
        return 1
    fi
    return 0
}

# --- CONFIGURATION MANAGEMENT ---
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

save_config() {
    echo "DEFAULT_DIR=\"$OUTPUT_DIR\"" > "$CONFIG_FILE"
    echo "DEFAULT_VIDEO_FORMAT=\"$DEFAULT_VIDEO_FORMAT\"" >> "$CONFIG_FILE"
    echo "DEFAULT_AUDIO_FORMAT=\"$DEFAULT_AUDIO_FORMAT\"" >> "$CONFIG_FILE"
}

configure_output_dir() {
    load_config

    if [ -n "${DEFAULT_DIR:-}" ]; then
        BASE_DIR="$DEFAULT_DIR"
    else
        BASE_DIR="$DEFAULT_FALLBACK"
    fi

    echo -e "${CYAN}Huidige standaard directory: ${BASE_DIR}${NC}"
    read -p "Geef target directory (ENTER = $BASE_DIR): " USER_DIR

    if [ -z "$USER_DIR" ]; then
        USER_DIR="$BASE_DIR"
    fi

    mkdir -p "$USER_DIR"
    OUTPUT_DIR="$USER_DIR"
    save_config

    echo -e "📁 Output directory: ${GREEN}$OUTPUT_DIR${NC}"
}

get_url() {
    echo ""
    read -p "Geef de video URL: " URL
    if [ -z "$URL" ]; then
        echo -e "${RED}❌ Geen URL ingegeven. Terug naar menu.${NC}"
        return 1
    fi
    return 0
}

# --- HELPER FUNCTIONS ---
choose_video_format() {
    # Since this function is called inside a subshell like $(choose_video_format)
    # we must redirect all UI output to stderr (>&2) so it doesn't get captured in the variable.
    local fallback="mp4"
    local default_fmt="${DEFAULT_VIDEO_FORMAT:-$fallback}"

    echo -e "\n${CYAN}Kies videocontainerformaat (mp4, mkv, webm)${NC}" >&2
    read -p "Formaat [ENTER=${default_fmt}]: " chosen_fmt < /dev/tty

    if [ -z "$chosen_fmt" ]; then
        chosen_fmt="$default_fmt"
    fi

    # Validatie
    case "$chosen_fmt" in
        mp4|mkv|webm) ;;
        *) chosen_fmt="$fallback" ; echo -e "${YELLOW}Ongeldig formaat, teruggevallen op ${chosen_fmt}${NC}" >&2 ;;
    esac

    # In a subshell, modifying a global var doesn't stick to the parent shell.
    # However, saving it to disk allows the next step to read the updated config.
    DEFAULT_VIDEO_FORMAT="$chosen_fmt"
    save_config
    echo "$chosen_fmt"
}

choose_audio_format() {
    local fallback="mp3"
    local default_fmt="${DEFAULT_AUDIO_FORMAT:-$fallback}"

    echo -e "\n${CYAN}Kies audioformaat (mp3, aac, flac, wav, m4a)${NC}" >&2
    read -p "Formaat [ENTER=${default_fmt}]: " chosen_fmt < /dev/tty

    if [ -z "$chosen_fmt" ]; then
        chosen_fmt="$default_fmt"
    fi

    # Validatie
    case "$chosen_fmt" in
        mp3|aac|flac|wav|m4a) ;;
        *) chosen_fmt="$fallback" ; echo -e "${YELLOW}Ongeldig formaat, teruggevallen op ${chosen_fmt}${NC}" >&2 ;;
    esac

    DEFAULT_AUDIO_FORMAT="$chosen_fmt"
    save_config
    echo "$chosen_fmt"
}

# --- DOWNLOAD FUNCTIONS ---
download_standard() {
    configure_output_dir
    get_url || return
    local archive_args=("--download-archive" "$OUTPUT_DIR/download_archive.txt")

    echo -e "\n${CYAN}⬇️ Video downloaden...${NC}"
    yt-dlp "${archive_args[@]}" -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Klaar!${NC}"
    pause
}

download_best() {
    configure_output_dir
    get_url || return
    local vid_format=$(choose_video_format)
    local archive_args=("--download-archive" "$OUTPUT_DIR/download_archive.txt")

    echo -e "\n${CYAN}⬇️ Beste kwaliteit (video+audio) downloaden als ${vid_format}...${NC}"
    yt-dlp "${archive_args[@]}" -f "bestvideo+bestaudio/best" --merge-output-format "$vid_format" -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Klaar!${NC}"
    pause
}

download_audio() {
    configure_output_dir
    get_url || return
    local aud_format=$(choose_audio_format)
    local archive_args=("--download-archive" "$OUTPUT_DIR/download_archive.txt")

    echo -e "\n${CYAN}🎵 Alleen audio (${aud_format}) downloaden...${NC}"
    yt-dlp "${archive_args[@]}" -x --audio-format "$aud_format" -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Klaar!${NC}"
    pause
}

list_formats() {
    get_url || return
    echo -e "\n${CYAN}📋 Beschikbare formaten ophalen...${NC}"
    yt-dlp -F "$URL"
    pause
}

download_clip() {
    configure_output_dir
    get_url || return
    local vid_format=$(choose_video_format)

    read -p "Geef begintijd (bv 00:01:30) of laat leeg: " START
    read -p "Geef eindtijd (bv 00:03:45) of laat leeg: " END

    echo ""

    # Archive doesn't make sense for partial clips usually, but we could add it
    # We will exclude it for clips to ensure they always process if requested

    if [ -n "$START" ] && [ -n "$END" ]; then
        echo -e "🎬 ${CYAN}Download segment van $START tot $END als ${vid_format}...${NC}"

        yt-dlp \
            --download-sections "*${START}-${END}" \
            -f "bestvideo+bestaudio/best" \
            --merge-output-format "$vid_format" \
            -o "$OUTPUT_DIR/%(title)s_clip.%(ext)s" \
            "$URL"

    else
        echo -e "⬇️ ${CYAN}Geen geldige tijden. Volledige video downloaden...${NC}"
        local archive_args=("--download-archive" "$OUTPUT_DIR/download_archive.txt")

        yt-dlp "${archive_args[@]}" \
            -f "bestvideo+bestaudio/best" \
            --merge-output-format "$vid_format" \
            -o "$OUTPUT_DIR/%(title)s.%(ext)s" \
            "$URL"
    fi

    echo -e "\n${GREEN}✅ Klaar!${NC}"
    pause
}

download_batch() {
    configure_output_dir
    local archive_args=("--download-archive" "$OUTPUT_DIR/download_archive.txt")

    echo -e "\n${CYAN}Kies een batch tekstbestand (één URL per regel)${NC}"
    read -p "Bestandspad: " BATCH_FILE

    if [ ! -f "$BATCH_FILE" ]; then
        echo -e "${RED}❌ Bestand niet gevonden: $BATCH_FILE${NC}"
        pause
        return
    fi

    echo -e "\n${CYAN}Kies formaat voor alle video's in batch:${NC}"
    echo "1) Beste kwaliteit Video (standaard)"
    echo "2) Alleen Audio"
    read -p "Keuze: " batch_choice

    if [ "$batch_choice" = "2" ]; then
        local aud_format=$(choose_audio_format)
        echo -e "\n${CYAN}⬇️ Batch Audio downloaden gestart...${NC}"
        yt-dlp "${archive_args[@]}" -x --audio-format "$aud_format" -o "$OUTPUT_DIR/%(title)s.%(ext)s" -a "$BATCH_FILE"
    else
        local vid_format=$(choose_video_format)
        echo -e "\n${CYAN}⬇️ Batch Video downloaden gestart...${NC}"
        yt-dlp "${archive_args[@]}" -f "bestvideo+bestaudio/best" --merge-output-format "$vid_format" -o "$OUTPUT_DIR/%(title)s.%(ext)s" -a "$BATCH_FILE"
    fi

    echo -e "\n${GREEN}✅ Klaar!${NC}"
    pause
}

download_thumbnail() {
    configure_output_dir
    get_url || return

    echo -e "\n${CYAN}🖼️ Thumbnail downloaden...${NC}"
    yt-dlp --write-thumbnail --skip-download -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Klaar!${NC}"
    pause
}

download_with_subtitles() {
    configure_output_dir
    get_url || return
    local vid_format=$(choose_video_format)
    local archive_args=("--download-archive" "$OUTPUT_DIR/download_archive.txt")

    echo -e "\n${CYAN}Kies ondertiteling taal (bijv. nl, en, of 'all' voor alles)${NC}"
    read -p "Taalcode [ENTER=nl]: " sub_lang
    if [ -z "$sub_lang" ]; then
        sub_lang="nl"
    fi

    echo -e "\n${CYAN}⬇️ Video met ondertitels downloaden...${NC}"
    yt-dlp "${archive_args[@]}" -f "bestvideo+bestaudio/best" --merge-output-format "$vid_format" --write-subs --sub-langs "$sub_lang" -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Klaar!${NC}"
    pause
}

# --- LOCAL MEDIA FUNCTIONS ---
trim_local_file() {
    echo -e "\n${CYAN}Kies een lokaal mediabestand om te knippen${NC}"
    read -p "Bestandspad: " input_file

    if [ ! -f "$input_file" ]; then
        echo -e "${RED}❌ Bestand niet gevonden: $input_file${NC}"
        pause
        return
    fi

    read -p "Geef begintijd (bv 00:01:30): " start_time
    read -p "Geef eindtijd (bv 00:03:45) of duur (+00:02:15): " end_time
    read -p "Geef uitvoer bestandspad (bv output.mp4): " output_file

    if [ -z "$start_time" ] || [ -z "$end_time" ] || [ -z "$output_file" ]; then
        echo -e "${RED}❌ Ontbrekende gegevens.${NC}"
        pause
        return
    fi

    echo -e "\n${CYAN}✂️ Bestand knippen...${NC}"
    ffmpeg -i "$input_file" -ss "$start_time" -to "$end_time" -c copy "$output_file"
    echo -e "\n${GREEN}✅ Klaar! Opgeslagen als $output_file${NC}"
    pause
}

convert_local_file() {
    echo -e "\n${CYAN}Kies een lokaal mediabestand om te converteren${NC}"
    read -p "Invoer bestand: " input_file

    if [ ! -f "$input_file" ]; then
        echo -e "${RED}❌ Bestand niet gevonden: $input_file${NC}"
        pause
        return
    fi

    read -p "Geef gewenst uitvoer bestand (bv output.mkv): " output_file
    if [ -z "$output_file" ]; then
        echo -e "${RED}❌ Geen uitvoer bestand gegeven.${NC}"
        pause
        return
    fi

    echo -e "\n${CYAN}🔄 Bestand converteren...${NC}"
    ffmpeg -i "$input_file" -c copy "$output_file"
    echo -e "\n${GREEN}✅ Klaar! Opgeslagen als $output_file${NC}"
    pause
}

media_info() {
    echo -e "\n${CYAN}Kies een lokaal mediabestand voor metadata (Media Info)${NC}"
    read -p "Bestandspad: " input_file

    if [ ! -f "$input_file" ]; then
        echo -e "${RED}❌ Bestand niet gevonden: $input_file${NC}"
        pause
        return
    fi

    echo -e "\n${CYAN}ℹ️ Media Informatie:${NC}"
    ffprobe -hide_banner "$input_file"
    pause
}

# --- MAIN MENU ---
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}VIDEO MASTER CONTROL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo -e "${YELLOW}Online Downloads:${NC}"
    echo "1) Standaard Download (Auto)"
    echo "2) Beste Kwaliteit Download (Kies Videoformaat)"
    echo "3) Audio Download (Kies Audioformaat)"
    echo "4) Beschikbare Kwaliteiten / Formaten Weergeven"
    echo "5) Specifiek Video Segment Knippen (Clip)"
    echo "6) Batch Downloaden (URL lijst)"
    echo "7) Thumbnail Afbeelding Downloaden"
    echo "8) Video Downloaden met Ondertiteling"
    echo -e "${YELLOW}Lokale Media (Bestanden):${NC}"
    echo "9) Lokaal Mediabestand Knippen (Trim)"
    echo "10) Lokaal Mediabestand Converteren"
    echo "11) Media Informatie Weergeven (Metadata)"
    echo -e "-----------------------------------"
    echo "X) Afsluiten"
    echo ""

    read -p "Maak uw keuze: " choice
    case ${choice:-} in
        1) check_dependencies && download_standard ;;
        2) check_dependencies && download_best ;;
        3) check_dependencies && download_audio ;;
        4) check_dependencies && list_formats ;;
        5) check_dependencies && download_clip ;;
        6) check_dependencies && download_batch ;;
        7) check_dependencies && download_thumbnail ;;
        8) check_dependencies && download_with_subtitles ;;
        9) check_dependencies && trim_local_file ;;
        10) check_dependencies && convert_local_file ;;
        11) check_dependencies && media_info ;;
        [xX]) exit 0 ;;
        *) echo -e "${RED}Ongeldige keuze.${NC}" ; pause ;;
    esac
done
