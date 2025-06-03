#!/bin/bash

# This script updates a JSON file with new doorbell event data.
# It ensures the JSON file only keeps a maximum number of recent items.

# --- Parameters ---
# $1: IMG_PATH_FOR_CARD - Image path for the Lovelace card (e.g., /local/camera_snapshots/snapshot.jpg)
# $2: DESCRIPTION_CLEAN - Cleaned description text from Gemini
# $3: TIMESTAMP_ISO - ISO formatted timestamp (e.g., 2025-06-02T20:36:28.944519+10:00)
# $4: MAX_ITEMS_TO_STORE - (Optional) Maximum number of items to keep in the JSON array. Defaults to 100.

IMG_PATH="$1"
DESCRIPTION="$2"
TIMESTAMP="$3"
MAX_ITEMS_TO_STORE="${4:-100}" # Default to 100 if $4 is empty or unset

JSON_FILE="/config/www/doorbell/doorbell_events.json"
JSON_DIR="/config/www/doorbell"

# --- Input Validation ---
if [ -z "$IMG_PATH" ] || [ -z "$DESCRIPTION" ] || [ -z "$TIMESTAMP" ]; then
    >&2 echo "Error: Missing required parameters."
    >&2 echo "Usage: $0 <img_path> <description> <timestamp> [max_items_to_store]"
    exit 1
fi

# --- Check for jq installation ---
if ! command -v jq &> /dev/null
then
    >&2 echo "Error: 'jq' is not installed. Please install it on your Home Assistant server."
    >&2 echo "For Debian/Ubuntu: sudo apt-get update && sudo apt-get install jq"
    >&2 echo "For Alpine (e.g., some Docker images): apk add jq"
    exit 1
fi

# --- Ensure JSON file directory exists ---
mkdir -p "$JSON_DIR" || { >&2 echo "Error: Could not create directory $JSON_DIR"; exit 1; }

# Set correct permissions for the directory
chmod 755 "$JSON_DIR" || { >&2 echo "Error: Could not set permissions for directory $JSON_DIR"; exit 1; }

# If file doesn't exist OR is not valid JSON, initialize it as an empty array
if [ ! -f "$JSON_FILE" ] || ! jq -e . "$JSON_FILE" >/dev/null 2>&1; then
    echo "[]" > "$JSON_FILE" || { >&2 echo "Error: Could not initialize JSON file $JSON_FILE"; exit 1; }
fi

# Use jq to:
# 1. Prepend the new image, description, and timestamp object to the JSON array.
#    Since you're prepending, the newest item is at index 0.
# 2. Then, slice the array from the beginning (index 0) up to MAX_ITEMS_TO_STORE.
#    This keeps only the 'MAX_ITEMS_TO_STORE' most recent items.
jq --arg new_img "$IMG_PATH" \
   --arg new_desc "$DESCRIPTION" \
   --arg new_ts "$TIMESTAMP" \
   --arg max_items "$MAX_ITEMS_TO_STORE" \
   '. |= ( [ {img: $new_img, desc: $new_desc, time_stamp: $new_ts} ] + . ) | .[0:($max_items | tonumber)]' \
   "$JSON_FILE" > "$JSON_FILE".tmp

# Atomically replace the original file with the updated content
mv "$JSON_FILE".tmp "$JSON_FILE" || { >&2 echo "Error: Could not move temporary file to $JSON_FILE"; exit 1; }

# Set correct permissions for the file
chmod 644 "$JSON_FILE" || { >&2 echo "Error: Could not set permissions for file $JSON_FILE"; exit 1; }

# Optional: Log success/failure to standard error, which Home Assistant typically captures in its logs
if [ $? -eq 0 ]; then
    >&2 echo "SUCCESS: Doorbell event added to $JSON_FILE and trimmed to $MAX_ITEMS_TO_STORE items."
else
    >&2 echo "ERROR: Failed to add doorbell event or set permissions for: Img: $IMG_PATH, Desc: $DESCRIPTION, Timestamp: $TIMESTAMP"
fi