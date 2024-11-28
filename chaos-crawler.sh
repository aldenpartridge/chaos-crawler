#!/bin/bash
cat << "EOF"

           __                                                                     __              
  _____   / /_   ____ _  ____    _____         _____   _____  ____ _ _      __   / /  ___    _____
 / ___/  / __ \ / __ `/ / __ \  / ___/ ______ / ___/  / ___/ / __ `/| | /| / /  / /  / _ \  / ___/
/ /__   / / / // /_/ / / /_/ / (__  ) /_____// /__   / /    / /_/ / | |/ |/ /  / /  /  __/ / /    
\___/  /_/ /_/ \__,_/  \____/ /____/         \___/  /_/     \__,_/  |__/|__/  /_/   \___/ /_/     

EOF

BASE_DIR="$HOME/subdomains"

FILTER_BOUNTY=false
FILTER_PLATFORMS=()

show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -d DIRECTORY            Specify the base directory for downloads (default: $HOME/subdomains)"
    echo "  -b, --bounty            Include only programs that offer bounties"
    echo "  -p, --platform PLATFORMS Specify comma-separated platforms to include (e.g., hackerone,bugcrowd)"
    echo "  -h, --help              Display this help message"
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

if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install it and retry."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it and retry."
    exit 1
fi

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

    program_dir="$BASE_DIR/$sanitized_platform/$bounty_dir/$sanitized_name"
    mkdir -p "$program_dir"

    zip_file="$program_dir/${sanitized_name}.zip"
    echo "Downloading $program_name..."
    curl -s "$program_url" -o "$zip_file"

    if [ ! -s "$zip_file" ]; then
        echo "Error: Failed to download data for $program_name."
    fi
done

# Clean up
rm index.json

echo "All programs downloaded successfully to $BASE_DIR."
