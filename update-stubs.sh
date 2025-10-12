#!/bin/bash

set -e

echo "Updating MongoDB stubs from JetBrains/phpstorm-stubs..."

# Remove existing MongoDB directory
if [ -d "MongoDB" ]; then
    echo "Removing existing MongoDB directory..."
    rm -rf MongoDB
fi

# Create MongoDB directory
mkdir -p MongoDB

# Function to download directory contents recursively
download_directory() {
    local api_url="$1"
    local local_path="$2"
    
    echo "Fetching contents from $api_url..."
    local response=$(curl -s -H "User-Agent: MongoDB-Stubs-Updater" "$api_url")
    
    # Create directory if it doesn't exist
    mkdir -p "$local_path"
    
    # Process each item in the JSON array
    echo "$response" | sed 's/},{/\n/g' | sed 's/^\[{//' | sed 's/}\]$//' | while IFS= read -r item; do
        name=$(echo "$item" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"$//g')
        type=$(echo "$item" | grep -o '"type":"[^"]*"' | sed 's/"type":"//g' | sed 's/"$//g')
        
        if [[ "$type" == "file" && "$name" == *.php ]]; then
            download_url=$(echo "$item" | grep -o '"download_url":"[^"]*"' | sed 's/"download_url":"//g' | sed 's/"$//g')
            echo "Downloading file: $name to $local_path..."
            curl -s -L "$download_url" -o "$local_path/$name"
        elif [[ "$type" == "dir" ]]; then
            echo "Found directory: $name"
            # Construct new API URL for subdirectory
            subdir_url=$(echo "$api_url" | sed "s|mongodb$|mongodb/$name|")
            download_directory "$subdir_url" "$local_path/$name"
        fi
    done
}

# Start downloading from the mongodb directory
download_directory "https://api.github.com/repos/JetBrains/phpstorm-stubs/contents/mongodb" "MongoDB"

echo "MongoDB stubs updated successfully!"