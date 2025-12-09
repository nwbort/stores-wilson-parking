#!/usr/bin/env bash
#
# download - Simple downloader for Wilson Parking API
# Usage: ./download.sh URL

set -e

# Function to detect MIME type and return appropriate extension
get_file_extension() {
  local file_path="$1"
  local mime_type=$(file --mime-type -b "$file_path")
  local extension=""
  
  case "$mime_type" in
    text/html)                extension=".html" ;;
    application/json)         extension=".json" ;;
    text/plain)               extension=".txt" ;;
    application/javascript)   extension=".js" ;;
    application/xml|text/xml) extension=".xml" ;;
    application/pdf)          extension=".pdf" ;;
    image/jpeg)               extension=".jpg" ;;
    image/png)                extension=".png" ;;
    image/gif)                extension=".gif" ;;
    image/svg+xml)            extension=".svg" ;;
    application/zip)          extension=".zip" ;;
    application/gzip)         extension=".gz" ;;
    application/x-tar)        extension=".tar" ;;
    application/x-bzip2)      extension=".bz2" ;;
    *)                        extension=".html" ;;
  esac
  
  echo "$extension"
}

if [ $# -ne 1 ]; then
  echo "Usage: $0 URL"
  exit 1
fi

URL="$1"

if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Error: URL must start with http:// or https://"
  exit 1
fi

TEMP_FILE=$(mktemp)

# Query parameters
PARAMS="latitude=-33.8688197&longitude=151.2092955&sort=undefined&distance=5000000"

# Full URL with params
FULL_URL="${URL}?${PARAMS}"

echo "Downloading $FULL_URL"
curl -s -L "$FULL_URL" -o "$TEMP_FILE" \
  -H "authority: www.wilsonparking.com.au" \
  -H "accept: */*" \
  -H "accept-language: en-AU,en-NZ;q=0.9,en-GB;q=0.8,en-US;q=0.7,en;q=0.6" \
  -H "referer: https://www.wilsonparking.com.au/" \
  -H "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  || {
    echo "Error: Failed to download"
    rm -f "$TEMP_FILE"
    exit 1
  }

EXTENSION=$(get_file_extension "$TEMP_FILE")
FILENAME=$(echo "$URL" | sed -E 's|^https?://||' | sed -E 's|^www\.||' | sed 's|/$||' | sed 's|/|-|g')
FILENAME="${FILENAME}${EXTENSION}"

if [ "$FILENAME" = "${EXTENSION}" ]; then
  FILENAME="index${EXTENSION}"
fi

CURRENT_DIR="$(pwd)"
FULL_PATH="${CURRENT_DIR}/${FILENAME}"

if [ "$EXTENSION" = ".json" ]; then
  PRETTY_TEMP=$(mktemp)
  if command -v jq &> /dev/null; then
    if jq . "$TEMP_FILE" > "$PRETTY_TEMP" 2>/dev/null; then
      mv "$PRETTY_TEMP" "$TEMP_FILE"
    else
      rm -f "$PRETTY_TEMP"
    fi
  else
    rm -f "$PRETTY_TEMP"
  fi
fi

mv "$TEMP_FILE" "$FULL_PATH"
echo "Saved to $FULL_PATH"
