#!/bin/bash

# Enable better error handling
set -euo pipefail
shopt -s nullglob dotglob

# Color definitions
declare -A colors=(
    ["red"]="\e[0;91m"
    ["blue"]="\e[0;94m"
    ["green"]="\e[0;92m"
    ["white"]="\e[0;97m"
    ["reset"]="\e[0m"
)

# Configuration
readonly REQUIRED_DIRS=("mp4" "png" "old" "tiktok")
readonly CLEANUP_FILES=("ACIDVIEW.EXE" "ICEVIEW.EXE" "WE-WILL.SUE")
readonly IMAGE_TYPES=("*.jpg" "*.JPG" "*.GIF" "*.gif")
readonly TEXT_TYPES=("*.GRT" "*.BIN" "*.LGO" "*.CIA" "*.WKD" "*.wkd" "*.VIV" "*.viv" 
                    "*.FL" "*.IMP" "*.txt" "*.ans" "*.asc" "*.LGC" "*.ASC" "*.NFO" 
                    "*.ANS" "*.ans" "*.DRK" "*.ICE" "*.LIT" "*.MEM" "*.DIZ" "*.STS" 
                    "*.MEM" "*.GOT" "*.rmx")

# Logging functions
log_info() {
    echo -e "${colors[green]}[INFO] $1${colors[reset]}"
}

log_error() {
    echo -e "${colors[red]}[ERROR] $1${colors[reset]}" >&2
}

# Get output filename from current directory
get_output_filename() {
    local current_dir=$(basename "$(pwd)")
    echo "${current_dir}.mp4"
}

# Check required commands
check_dependencies() {
    local deps=("ffmpeg" "ansilove" "convert" "gif2png")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log_error "Required command not found: $dep"
            exit 1
        fi
    done
}

# Create required directories
setup_directories() {
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done
}

# Create backup of current directory
create_backup() {
    local current_dir=$(basename "$(pwd)")
    local backup_dir="../clean_${current_dir}"
    cp -R "$(pwd)" "$backup_dir"
    log_info "Created backup at: $backup_dir"
}

# Clean filenames by removing special characters
clean_filename() {
    local filename="$1"
    echo "$filename" | tr -d '!^+&% '
}

# Process image files (convert to PNG)
process_images() {
    for type in "${IMAGE_TYPES[@]}"; do
        for file in $type; do
            local clean_name=$(clean_filename "$file")
            [[ "$file" != "$clean_name" ]] && mv "$file" "$clean_name"
            
            if [[ "$clean_name" =~ \.jpg$ || "$clean_name" =~ \.JPG$ ]]; then
                convert "$clean_name" "${clean_name%.*}.png"
                rm "$clean_name"
                log_info "Converted $clean_name to PNG"
            elif [[ "$clean_name" =~ \.gif$ || "$clean_name" =~ \.GIF$ ]]; then
                gif2png -O -d -p "$clean_name"
                rm "$clean_name"
                log_info "Converted $clean_name to PNG"
            fi
        done
    done
}

# Process text files with ansilove
process_text_files() {
    local processed=0
    local total=0
    declare -A seen_files

    for type in "${TEXT_TYPES[@]}"; do
        for file in $type; do
            [[ ${seen_files[$file]} ]] && continue
            seen_files[$file]=1
            ((total++))
            
            local clean_name=$(clean_filename "$file")
            [[ "$file" != "$clean_name" ]] && mv "$file" "$clean_name"
            
            ansilove -q -d -S "$clean_name"
            
            if [[ -f "$clean_name.png" ]]; then
                local filesize=$(identify -format "%h" "$clean_name.png")
                if ((filesize > 480)); then
                    create_scrolling_video "$clean_name.png"
                    rm "$clean_name.png"
                    mv "$clean_name.mp4" mp4/
                else
                    mv "$clean_name.png" png/
                fi
            fi
            
            mv "$clean_name" old/
            ((processed++))
            log_info "Processed $processed/$total: $clean_name"
        done
    done
}

# Create scrolling video effect
create_scrolling_video() {
    local png_file="$1"
    ffmpeg -hide_banner -loglevel panic \
        -f lavfi -i color=s=1920x1080 \
        -loop 1 -t 0.08 -i "$png_file" \
        -filter_complex "[1:v]scale=1920:-2,setpts=if(eq(N\,0)\,0\,1+1/0.02/TB),fps=25[fg]; [0:v][fg]overlay=y=-'t*h*0.02':eof_action=endall[v]" \
        -map "[v]" "${png_file%.*}.mp4" -nostdin
}

# Combine videos with audio
combine_with_audio() {
    local video_file="$1"
    local output_file="$2"
    local duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 "$video_file")
    local fade=5
    
    # Create temporary audio file
    create_random_audio_mix "/tmp/temp_audio.mp3"
    
    ffmpeg -hide_banner -loglevel panic \
        -i "$video_file" -i "/tmp/temp_audio.mp3" \
        -filter_complex "[1:a]afade=t=out:st=$(bc <<< "$duration-$fade"):d=$fade[a]" \
        -map 0:v:0 -map "[a]" -c:v copy -c:a aac -shortest \
        "$output_file"
        
    rm "/tmp/temp_audio.mp3"
}

# Create random audio mix from MP3s
create_random_audio_mix() {
    local output_file="$1"
    local mp3_list="/tmp/mp3_list.txt"
    
    find /tmp/mp3s -name "*.mp3" -type f | shuf > "$mp3_list"
    ffmpeg -hide_banner -loglevel panic -f concat -safe 0 -i "$mp3_list" -c copy "$output_file"
    rm "$mp3_list"
}

# Main execution
main() {
    check_dependencies
    create_backup
    setup_directories
    
    # Get output filename from current directory
    local output_filename=$(get_output_filename)
    log_info "Output filename will be: $output_filename"
    
    # Clean up unnecessary files
    for file in "${CLEANUP_FILES[@]}"; do
        [[ -f "$file" ]] && rm "$file" && log_info "Removed $file"
    done
    
    # Process files
    process_images
    process_text_files
    
    # Create final video
    create_final_video "$output_filename"
    create_tiktok_videos
    
    log_info "Processing complete: $output_filename"
}

# Create final concatenated video
create_final_video() {
    local output_file="$1"
    local concat_list="list.txt"
    
    # Create concat list
    [[ -f "img/intro.mp4" ]] && echo "file 'img/intro.mp4'" > "$concat_list"
    find mp4/ -name "*.mp4" -type f | sort -R | sed 's/^/file '"'"'/;s/$/'\''"/' >> "$concat_list"
    [[ -f "img/outro.mp4" ]] && echo "file 'img/outro.mp4'" >> "$concat_list"
    
    # Create final video
    ffmpeg -hide_banner -loglevel panic -f concat -safe 0 -i "$concat_list" -c copy "temp_final.mp4"
    combine_with_audio "temp_final.mp4" "$output_file"
    
    rm "temp_final.mp4" "$concat_list"
}

# Create TikTok versions
create_tiktok_videos() {
    find mp4/ -name "*.mp4" -type f | while read -r video; do
        local basename=$(basename "$video")
        local tiktok_output="tiktok/${basename}"
        
        # Create video without sound
        ffmpeg -hide_banner -loglevel panic -i "$video" -c copy "temp_nosound.mp4"
        
        # Add random audio
        combine_with_audio "temp_nosound.mp4" "$tiktok_output"
        rm "temp_nosound.mp4"
        
        log_info "Created TikTok version: $tiktok_output"
    done
}

# Execute main function
main
