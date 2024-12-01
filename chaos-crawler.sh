#!/bin/bash

cat << "EOF"

       _                                                   _           
   ___| |__   __ _  ___  ___        ___ _ __ __ ___      _| | ___ _ __ 
  / __| '_ \ / _` |/ _ \/ __|_____ / __| '__/ _` \ \ /\ / / |/ _ \ '__|
 | (__| | | | (_| | (_) \__ \_____| (__| | | (_| |\ V  V /| |  __/ |   
  \___|_| |_|\__,_|\___/|___/      \___|_|  \__,_| \_/\_/ |_|\___|_|   
                                                                       
EOF

BASE_DIR="$HOME/subdomains"
FILTER_BOUNTY=false
FILTER_PLATFORMS=()

show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -d DIRECTORY              Specify the base directory for downloads (default: $HOME/subdomains)"
    echo "  -b, --bounty              Include only programs that offer bounties"
    echo "  -p, --platform PLATFORMS   Specify comma-separated platforms to include (e.g., hackerone,bugcrowd)"
    echo "  -h, --help                Display this help message"
}

validate_url() {
    local url="$1"
    local url_regex="^(https?:\/\/)?(([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\.)+[a-zA-Z]{2,6}(:[0-9]{1,5})?(\/.*)?$"

    if [[ "$url" =~ $url_regex ]]; then
        return 0
    else
        return 1
    fi
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--directory)
            BASE_DIR="$2"
            shift 2
            ;;
        -b|--bounty)
            FILTER_BOUNTY=true
            shift
            ;;
        -p|--platform)
            IFS=',' read -ra FILTER_PLATFORMS <<< "$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            show_help
            exit 1
            ;;
    esac
done

for cmd in curl jq unzip; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed. Please install it and retry."
        exit 1
    fi
done

mkdir -p "$BASE_DIR"

echo "Downloading index.json..."
curl -s https://chaos-data.projectdiscovery.io/index.json -o index.json

if [ ! -s index.json ]; then
    echo "Error: Failed to download index.json or file is empty."
    exit 1
fi

jq_filter='.'

if $FILTER_BOUNTY; then
    jq_filter+=' | select(.bounty == true)'
fi

if [ ${#FILTER_PLATFORMS[@]} -gt 0 ]; then
    platforms_pattern=$(printf "\"%s\" " "${FILTER_PLATFORMS[@]}")
    jq_filter+=" | select(.platform as \$p | [${platforms_pattern}] | index(\$p))"
fi

echo "Processing programs..."
jq -c ".[] | $jq_filter" index.json | while read -r program; do
    program_name=$(echo "$program" | jq -r '.name')
    program_url=$(echo "$program" | jq -r '.URL')
    program_platform=$(echo "$program" | jq -r '.platform')
    program_bounty=$(echo "$program" | jq -r '.bounty')

    sanitized_name=$(echo "$program_name" | tr -cd '[:alnum:]_-')
    sanitized_platform=$(echo "$program_platform" | tr -cd '[:alnum:]_-')

    if [ -z "$sanitized_platform" ]; then
        sanitized_platform="unknown_platform"
    fi

    if [ "$program_bounty" = "true" ]; then
        bounty_dir="bounty"
    else
        bounty_dir="no_bounty"
    fi

    if validate_url "$program_url"; then
        echo "Valid URL for $program_name: $program_url"
    else
        echo "Invalid URL for $program_name: $program_url"
        echo "Skipping download for $program_name due to invalid URL."
        continue
    fi

    program_dir="$BASE_DIR/$sanitized_platform/$bounty_dir/$sanitized_name"
    mkdir -p "$program_dir"

    zip_file="$program_dir/${sanitized_name}.zip"

    echo "Downloading $program_name..."
    curl -s "$program_url" -o "$zip_file"

    if [ ! -s "$zip_file" ]; then
        echo "Error: Failed to download data for $program_name."
        continue
    fi

    echo "Unzipping $program_name.zip..."
    unzip -o "$zip_file" -d "$program_dir" >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Error: Failed to unzip $zip_file."
        continue
    fi

    echo "Concatenating .txt files for $program_name..."
    cat "$program_dir"/*.txt > "$program_dir/placeholder.txt" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "Warning: No .txt files found for $program_name to concatenate."
    fi

    if [ -f "$program_dir/placeholder.txt" ]; then
        echo "Processing placeholder.txt for $program_name..."
        if command -v chars &> /dev/null; then
            chars "$program_dir/placeholder.txt" > "$program_dir/$sanitized_name"
        else
            echo "'chars' command not found. Using 'wc -m' as a placeholder."
            wc -m < "$program_dir/placeholder.txt" > "$program_dir/$sanitized_name"
        fi
        rm "$program_dir/placeholder.txt"
    fi

    echo "Completed processing for $program_name."

done

rm index.json

echo "All programs downloaded and processed successfully to $BASE_DIR."
