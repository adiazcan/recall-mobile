#!/bin/bash
# Helper script to run Flutter with environment variables from .env files

set -e

# Default to dev environment
ENV="${1:-dev}"
ENV_FILE=".env.${ENV}"

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: Environment file '$ENV_FILE' not found."
    echo ""
    echo "Usage: ./run.sh [dev|staging|prod]"
    echo ""
    echo "Please create the file from the template:"
    echo "  cp .env.example $ENV_FILE"
    echo "  # Edit $ENV_FILE with your configuration"
    exit 1
fi

echo "📱 Running Recall Mobile with $ENV environment..."
echo "   Using config from: $ENV_FILE"
echo ""

# Map environment to entry point
case "$ENV" in
    dev)
        ENTRY_POINT="lib/main_dev.dart"
        ;;
    staging)
        ENTRY_POINT="lib/main_staging.dart"
        ;;
    prod)
        ENTRY_POINT="lib/main_prod.dart"
        ;;
    *)
        echo "❌ Error: Invalid environment '$ENV'. Use dev, staging, or prod."
        exit 1
        ;;
esac

# Read .env file and build --dart-define arguments
DART_DEFINES=()
while IFS= read -r line || [ -n "$line" ]; do
    # Remove CRLF line endings
    line="${line%$'\r'}"
    
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Skip lines starting with 'export'
    [[ "$line" =~ ^[[:space:]]*export[[:space:]]+ ]] && line="${line#*export }"
    
    # Extract key and value, preserving spaces in value
    if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Trim leading/trailing whitespace from key only
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        
        # Strip inline comments (anything after # that's not in quotes)
        # Note: This is a simple approach that doesn't handle # characters
        # inside quoted strings. If you need FOO="bar#baz", avoid inline comments
        # or move the comment to a separate line.
        value="${value%%#*}"
        
        # Trim trailing whitespace from value
        value="${value%"${value##*[![:space:]]}"}"
        
        # Strip surrounding quotes if present (single or double)
        if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
            value="${BASH_REMATCH[1]}"
        fi
        
        # Add to dart defines (value may contain spaces)
        DART_DEFINES+=("--dart-define=${key}=${value}")
    fi
done < "$ENV_FILE"

echo "🚀 Starting Flutter..."
echo ""

# Run flutter with all defines
fvm flutter run -t "$ENTRY_POINT" "${DART_DEFINES[@]}" "${@:2}"
