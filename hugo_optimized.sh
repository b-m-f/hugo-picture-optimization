#!/bin/bash

MAXIMUM_JPG_SIZE=250
PNG_OPTIMIZATION_LEVEL=2
MAX_WIDTH=1400
NUM_PARALLEL_JOBS=8 # Number of parallel jobs for processing

# Build the site with Hugo
build_site() {
  hugo
}

# Function to resize images if wider than MAX_WIDTH
resize_image() {
  local image=$1
  local width=$(identify -format "%w" "$image")
  if [ "$width" -gt "$MAX_WIDTH" ]; then
    mogrify -resize "${MAX_WIDTH}>" "$image"
  fi
}

export -f resize_image

# Function to remove EXIF data from an image
process_exif() {
  local image=$1
  exiftool -all= "$image"
}

export -f process_exif

# Function to optimize JPEG images
optimize_jpeg() {
  local image=$1
  resize_image "$image"
  jpegoptim --strip-all --size=${MAXIMUM_JPG_SIZE}k "$image" &
}

export -f optimize_jpeg

# Function to optimize PNG images
optimize_png() {
  local image=$1
  resize_image "$image"
  pngcrush -ow -rem allb -reduce "$image" &
  wait
  optipng -clobber -strip all -o $PNG_OPTIMIZATION_LEVEL "$image" &
}

export -f optimize_png

# Function to optimize GIF images
optimize_gif() {
  local image=$1
  resize_image "$image"
  gifsicle --batch --optimize=3 --resize-fit "${MAX_WIDTH}x" --colors 256 "$image" &
}

export -f optimize_gif

# Function to optimize WebP images
optimize_webp() {
  local image=$1
  resize_image "$image"
  cwebp -q 80 "$image" -o "$image" &
}

export -f optimize_webp

# Main script execution
main() {
  build_site

  # Remove EXIF data from JPEG and PNG images
  if hash exiftool 2>/dev/null; then
    find public -type f -iregex ".*\.\(jpeg\|jpg\|png\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'process_exif "$0"'
  else
    echo "Install perl-image-exiftool to optimize images"
  fi

  # Optimize JPEG images
  if hash jpegoptim 2>/dev/null; then
    find public -type f -iregex ".*\.\(jpeg\|jpg\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_jpeg "$0"'
  else
    echo "Install jpegoptim to optimize JPEG images"
  fi

  # Optimize PNG images
  if hash optipng 2>/dev/null && hash pngcrush 2>/dev/null; then
    find public -type f -iregex ".*\.\(png\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_png "$0"'
  else
    echo "Install optipng and pngcrush to optimize PNG images"
  fi

  # Optimize GIF images while keeping them animated
  if hash gifsicle 2>/dev/null; then
    find public -type f -iregex ".*\.\(gif\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_gif "$0"'
  else
    echo "Install gifsicle to optimize GIF images"
  fi

  # Optimize WebP images
  if hash cwebp 2>/dev/null; then
    find public -type f -iregex ".*\.\(webp\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_webp "$0"'
  else
    echo "Install cwebp to optimize WebP images"
  fi

  # Wait for all background jobs to finish
  wait

  # Check for errors and exit if any are encountered
  if [ $? -ne 0 ]; then
    echo "Error encountered during image optimization"
    exit 1
  else
    echo "Image optimization completed successfully"
  fi
}

main
