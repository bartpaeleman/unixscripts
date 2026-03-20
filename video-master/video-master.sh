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
    local dir_to_save="${OUTPUT_DIR:-$DEFAULT_DIR}"
    echo "DEFAULT_DIR=\"$dir_to_save\"" > "$CONFIG_FILE"
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

list_formats() {
    get_url || return
    echo -e "\n${CYAN}📋 Beschikbare formaten ophalen...${NC}"
    yt-dlp -F "$URL"
    pause
}

execute_download() {
    local target_type="$1"  # "url" of "batch"
    local target="$2"       # De URL of het bestandspad
    local media_type="$3"   # "video", "audio", of "thumbnail"
    local format="$4"       # "mp4", "mp3", etc
    local clip_start="$5"   # leeg of "00:01:00"
    local clip_end="$6"     # leeg of "00:02:00"
    local subtitles="$7"    # leeg of "nl", "en", etc

    configure_output_dir

    local args=()
    local archive_args=("--download-archive" "$OUTPUT_DIR/download_archive.txt")

    # Bepaal Media Type & Formaat arguments
    if [ "$media_type" = "thumbnail" ]; then
        args+=("--write-thumbnail" "--skip-download")
        echo -e "\n${CYAN}🖼️ Thumbnail downloaden...${NC}"
    elif [ "$media_type" = "audio" ]; then
        args+=("-x" "--audio-format" "$format")
        echo -e "\n${CYAN}🎵 Audio ($format) downloaden...${NC}"
    else
        # Default is video
        args+=("-f" "bestvideo+bestaudio/best" "--merge-output-format" "$format")
        echo -e "\n${CYAN}⬇️ Video ($format) downloaden...${NC}"
    fi

    # Subtitles (alleen nuttig voor video, maar we laten yt-dlp beslissen indien gevraagd)
    if [ -n "$subtitles" ]; then
        args+=("--write-subs" "--sub-langs" "$subtitles")
        echo -e "💬 Ondertitels ingeschakeld: $subtitles"
    fi

    # Fragment / Clip (Download Sections)
    if [ -n "$clip_start" ] && [ -n "$clip_end" ]; then
        args+=("--download-sections" "*${clip_start}-${clip_end}")
        echo -e "✂️ Fragment geselecteerd: $clip_start tot $clip_end"
    else
        # Als er geen clip sectie is, voegen we het archive argument toe om dubbele volledige downloads te voorkomen.
        # (Archive werkt slecht samen met section downloads)
        args+=("${archive_args[@]}")
    fi

    # Bepaal Target (URL of Batch) en Output template
    if [ "$target_type" = "batch" ]; then
        args+=("-o" "$OUTPUT_DIR/%(title)s.%(ext)s" "-a" "$target")
        echo -e "📦 Batch modus geactiveerd voor: $target"
    else
        if [ -n "$clip_start" ]; then
            args+=("-o" "$OUTPUT_DIR/%(title)s_clip.%(ext)s" "$target")
        else
            args+=("-o" "$OUTPUT_DIR/%(title)s.%(ext)s" "$target")
        fi
    fi

    echo -e "-----------------------------------\n"
    yt-dlp "${args[@]}"

    echo -e "\n${GREEN}✅ Download proces voltooid!${NC}"
    pause
}

# --- DOWNLOAD CONFIGURATOR MENU ---
download_menu() {
    load_config

    local m_target_type="url"
    local m_target=""
    local m_media_type="video"
    local m_format="${DEFAULT_VIDEO_FORMAT:-mp4}"
    local m_clip_start=""
    local m_clip_end=""
    local m_subtitles=""

    while true; do
        clear
        echo -e "${CYAN}===================================${NC}"
        echo -e "      ${CYAN}DOWNLOAD CONFIGURATOR${NC}"
        echo -e "${CYAN}===================================${NC}"

        # Display current config
        echo -e "${YELLOW}Huidige Instellingen:${NC}"
        if [ "$m_target_type" = "url" ]; then
            echo -e " 1) Bron URL    : ${GREEN}${m_target:-[Niet Ingesteld]}${NC}"
        else
            echo -e " 1) Bron Batch  : ${GREEN}${m_target:-[Geen Bestand]}${NC}"
        fi

        echo -e " 2) Media Type  : ${GREEN}${m_media_type}${NC}"
        if [ "$m_media_type" != "thumbnail" ]; then
            echo -e " 3) Formaat     : ${GREEN}${m_format}${NC}"
        else
            echo -e " 3) Formaat     : ${YELLOW}N.v.t. (afbeelding)${NC}"
        fi

        if [ "$m_target_type" = "url" ]; then
            if [ -n "$m_clip_start" ]; then
                echo -e " 4) Fragment    : ${GREEN}$m_clip_start - $m_clip_end${NC}"
            else
                echo -e " 4) Fragment    : ${YELLOW}Nee (Volledige video)${NC}"
            fi
        else
            echo -e " 4) Fragment    : ${YELLOW}N.v.t. (batch modus)${NC}"
        fi

        if [ "$m_media_type" = "video" ]; then
            if [ -n "$m_subtitles" ]; then
                echo -e " 5) Ondertitels : ${GREEN}$m_subtitles${NC}"
            else
                echo -e " 5) Ondertitels : ${YELLOW}Nee${NC}"
            fi
        else
             echo -e " 5) Ondertitels : ${YELLOW}N.v.t. ($m_media_type)${NC}"
        fi

        echo -e "-----------------------------------"
        echo -e " ${GREEN}S) START DOWNLOAD${NC}"
        echo -e " B) Terug naar hoofdmenu"
        echo ""

        read -p "Kies een optie om aan te passen of (S)tart: " choice

        case ${choice:-} in
            1)
                read -p "Type (U)RL of (B)atch bestand? [U/B]: " t_choice
                if [ "$t_choice" = "b" ] || [ "$t_choice" = "B" ]; then
                    m_target_type="batch"
                    read -p "Geef bestandspad: " m_target
                    m_clip_start="" # Fragments in batch is usually bad idea
                    m_clip_end=""
                else
                    m_target_type="url"
                    read -p "Geef de video URL: " m_target
                fi
                ;;
            2)
                echo -e "Kies Type: 1) Video, 2) Audio, 3) Thumbnail"
                read -p "Keuze [1-3]: " type_choice
                case $type_choice in
                    2) m_media_type="audio" ; m_format=$(choose_audio_format) ;;
                    3) m_media_type="thumbnail" ; m_format="jpg" ;;
                    *) m_media_type="video" ; m_format=$(choose_video_format) ;;
                esac
                ;;
            3)
                if [ "$m_media_type" = "video" ]; then
                    m_format=$(choose_video_format)
                elif [ "$m_media_type" = "audio" ]; then
                    m_format=$(choose_audio_format)
                fi
                ;;
            4)
                if [ "$m_target_type" = "url" ]; then
                    read -p "Geef begintijd (bv 00:01:30) of laat leeg om te wissen: " c_start
                    if [ -z "$c_start" ]; then
                        m_clip_start=""
                        m_clip_end=""
                    else
                        read -p "Geef eindtijd (bv 00:03:45): " c_end
                        m_clip_start="$c_start"
                        m_clip_end="$c_end"
                    fi
                else
                    echo "Fragment instellen wordt niet ondersteund in batch modus." ; sleep 2
                fi
                ;;
            5)
                if [ "$m_media_type" = "video" ]; then
                    read -p "Geef taalcode (bv 'nl', 'en') of laat leeg om uit te schakelen: " s_lang
                    m_subtitles="$s_lang"
                else
                    echo "Ondertitels zijn alleen beschikbaar voor video downloads." ; sleep 2
                fi
                ;;
            [sS])
                if [ -z "$m_target" ]; then
                    echo -e "${RED}❌ Geen bron URL of bestand opgegeven!${NC}" ; sleep 2
                else
                    execute_download "$m_target_type" "$m_target" "$m_media_type" "$m_format" "$m_clip_start" "$m_clip_end" "$m_subtitles"
                fi
                ;;
            [bB])
                break
                ;;
            *)
                echo -e "${RED}Ongeldige keuze.${NC}" ; sleep 1
                ;;
        esac
    done
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
    echo -e "${YELLOW}Online Media (yt-dlp):${NC}"
    echo "1) Download Media (Configuratiemenu)"
    echo "2) Beschikbare Kwaliteiten / Formaten Weergeven (URL)"
    echo -e "${YELLOW}Lokale Media (ffmpeg/ffprobe):${NC}"
    echo "3) Lokaal Mediabestand Knippen (Trim)"
    echo "4) Lokaal Mediabestand Converteren (Format/Container)"
    echo "5) Media Informatie Weergeven (Metadata)"
    echo -e "-----------------------------------"
    echo "X) Afsluiten"
    echo ""

    read -p "Maak uw keuze: " choice
    case ${choice:-} in
        1) check_dependencies && download_menu ;;
        2) check_dependencies && list_formats ;;
        3) check_dependencies && trim_local_file ;;
        4) check_dependencies && convert_local_file ;;
        5) check_dependencies && media_info ;;
        [xX]) exit 0 ;;
        *) echo -e "${RED}Ongeldige keuze.${NC}" ; pause ;;
    esac
done
