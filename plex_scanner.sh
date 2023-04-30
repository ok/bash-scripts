#!/bin/bash

# Configure your source and target directories here
SOURCE_DIR="/home/oliver/Downloads/complete"
PLEX_MOVIES_DIR="/media/oliver/media/Movies"
PLEX_TVSHOWS_DIR="/media/oliver/media/TV-Series"

# Set DEBUG to 1 to enable debug output, 0 to disable
DEBUG=1
# Set REMOVE_SOURCE to 1 to enable source folder removal, 0 to disable
REMOVE_SOURCE=1

# Debug function to print messages if debug is enabled
debug() {
  if [ $DEBUG -eq 1 ]; then
    echo "$1"
  fi
}

# Function to create a directory if it doesn't exist
create_directory_if_not_exist() {
  if [ ! -d "$1" ]; then
    debug "Creating directory: $1"
    mkdir -p "$1"
  fi
}

# Function to check if the file is a video file
is_video_file() {
  local file_ext=$(echo "${1##*.}" | tr '[:upper:]' '[:lower:]')
  case "$file_ext" in
    mkv|mp4|avi|mov|flv|wmv|m4v)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Loop through files and folders in the source directory
find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r item; do
  folder_name=$(basename "$item")

  # Ignore folders starting with "_UNPACK_"
  if [[ $folder_name == _UNPACK_* ]]; then
    continue
  fi

  # Check if the item is a TV series by looking for season pattern in the name
  if [[ $(basename "$item") =~ [sS][0-9][0-9][eE][0-9][0-9] ]]; then
    # Extract the show name and season number
    show_name=$(basename "$item" | sed -r 's/([sS][0-9][0-9][eE][0-9][0-9]).*/\1/')
    show_name=${show_name%[sS][0-9][0-9][eE][0-9][0-9]}
    show_name=$(echo "$show_name" | sed 's/[[:space:]]*$//') # Remove trailing space characters
    season_number=$(basename "$item" | grep -o -E '[sS][0-9][0-9]')

    # Format the season number to follow the standard folder structure
    season_folder=$(printf "Season %02d" "${season_number//[sS]/}")

    # Create the necessary directories in the TV shows folder
    create_directory_if_not_exist "$PLEX_TVSHOWS_DIR/$show_name"
    create_directory_if_not_exist "$PLEX_TVSHOWS_DIR/$show_name/$season_folder"

    # Move only video files to the Plex TV shows folder and rename them
    find "$item" -type f -not -path "*/Sample/*" | while read -r video_file; do
      if is_video_file "$video_file"; then
        video_ext="${video_file##*.}"
        debug "Moving series: $video_file to $PLEX_TVSHOWS_DIR/$show_name/$season_folder/$folder_name.$video_ext"
        mv "$video_file" "$PLEX_TVSHOWS_DIR/$show_name/$season_folder/$folder_name.$video_ext"
      fi
    done

    # Remove the source folder if REMOVE_SOURCE is set to 1
    if [ $REMOVE_SOURCE -eq 1 ]; then
      debug "Removing source folder: $item"
      rm -rf "$item"
    fi

  else
    # Move only video files to the Plex movies folder and rename them
    movie_name=$(basename "$item")
    find "$item" -type f | while read -r video_file; do
      if is_video_file "$video_file"; then
        video_ext="${video_file##*.}"
        debug "Moving movie: $video_file to $PLEX_MOVIES_DIR/$movie_name/$movie_name.$video_ext"
        mv "$video_file" "$PLEX_MOVIES_DIR/$movie_name/$movie_name.$video_ext"
      fi
    done

  fi
done


