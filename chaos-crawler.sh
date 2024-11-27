#!/bin/bash

# chaos-crawler.sh
# A script to download subdomain zip files for programs from Project Discovery's Chaos dataset,
# with options to filter by bounty status and platform, and organized directory structure.

# Usage: ./chaos-crawler.sh [-d DIRECTORY] [-b] [-p PLATFORM[,PLATFORM...]]

# Display the banner
cat << "EOF"

           __                                                                     __              
  _____   / /_   ____ _  ____    _____         _____   _____  ____ _ _      __   / /  ___    _____
 / ___/  / __ \ / __ `/ / __ \  / ___/ ______ / ___/  / ___/ / __ `/| | /| / /  / /  / _ \  / ___/
/ /__   / / / // /_/ / / /_/ / (__  ) /_____// /__   / /    / /_/ / | |/ |/ /  / /  /  __/ / /    
\___/  /_/ /_/ \__,_/  \____/ /____/         \___/  /_/     \__,_/  |__/|__/  /_/   \___/ /_/     

EOF

# Default base directory
BASE_DIR="$HOME/subdomains"

# Initialize filters
FILTER_BOUNTY=false
FILTER_PLATFORMS=()

# Function to display help
show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -d DIRECTORY            Specify the base directory for downloads (default: $HOME/subdomains)"
    echo "  -b, --bounty            Include only programs that offer bounties"
    echo "  -p, --platform PLATFORMS Specify comma-separated platforms to include (e.g., hackerone,bugcrowd)"
    echo "  -h, --help              Display this help message"
}

# Parse command-line arguments
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

# Check for dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install it and retry."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it and retry."
    exit 1
fi

# Create the base directory if it doesn't exist
mkdir -p "$BASE_DIR"

# Download the index.json file
echo "Downloading index.json..."
curl -s https://chaos-data.projectdiscovery.io/index.json -o index.json

if [ ! -s index.json ]; then
    echo "Error: Failed to download index.json or file is empty."
    exit 1
fi

# Prepare the jq filter based on user inputs
jq_filter='.'

if $FILTER_BOUNTY; then
    jq_filter+=' | select(.bounty == true)'
fi

if [ ${#FILTER_PLATFORMS[@]} -gt 0 ]; then
    # Build the platform filter
    platforms_pattern=$(printf "\"%s\" " "${FILTER_PLATFORMS[@]}")
    jq_filter+=" | select(.platform as \$p | [${platforms_pattern}] | index(\$p))"
fi

# Iterate over each program in the index.json with filtering
echo "Processing programs..."
jq -c ".[] | $jq_filter" index.json | while read -r program; do
    # Extract the program details
    program_name=$(echo "$program" | jq -r '.name')
    program_url=$(echo "$program" | jq -r '.URL')
    program_platform=$(echo "$program" | jq -r '.platform')
    program_bounty=$(echo "$program" | jq -r '.bounty')

    # Sanitize the program name and platform to remove any illegal characters for directory names
    sanitized_name=$(echo "$program_name" | tr -cd '[:alnum:]_-')
    sanitized_platform=$(echo "$program_platform" | tr -cd '[:alnum:]_-')

    # Handle empty platform names
    if [ -z "$sanitized_platform" ]; then
        sanitized_platform="unknown_platform"
    fi

    # Determine bounty status directory
    if [ "$program_bounty" = "true" ]; then
        bounty_dir="bounty"
    else
        bounty_dir="no_bounty"
    fi

    # Create the directory structure: BASE_DIR/platform/bounty_status/program/
    program_dir="$BASE_DIR/$sanitized_platform/$bounty_dir/$sanitized_name"
    mkdir -p "$program_dir"

    # Download the zip file into the program directory
    zip_file="$program_dir/${sanitized_name}.zip"
    echo "Downloading $program_name..."
    curl -s "$program_url" -o "$zip_file"

    # Check if the download was successful
    if [ ! -s "$zip_file" ]; then
        echo "Error: Failed to download data for $program_name."
    fi
done

# Clean up
rm index.json

echo "All programs downloaded successfully to $BASE_DIR."
