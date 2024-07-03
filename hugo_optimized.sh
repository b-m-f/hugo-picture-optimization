#!/bin/bash

MAXIMUM_JPG_SIZE=250
PNG_OPTIMIZATION_LEVEL=2
MAX_WIDTH=1400

# Build the site with Hugo
hugo

# Function to resize images if wider than MAX_WIDTH
resize_image() {
  local image=$1
  local width=$(identify -format "%w" "$image")
  if [ "$width" -gt "$MAX_WIDTH" ]; then
    mogrify -resize "${MAX_WIDTH}>" "$image"
  fi
}

# Remove EXIF data from all images
if hash exiftool 2>/dev/null; then
  exiftool -all= public/images/*
else
  echo "Install perl-image-exiftool to optimize images"
fi

# Optimize JPEG images
if hash jpegoptim 2>/dev/null; then
  find public/images -type f -iregex ".*\.\(jpeg\|jpg\)" -print0 | while IFS= read -r -d '' image; do
    resize_image "$image"
    jpegoptim --strip-all --size="${MAXIMUM_JPG_SIZE}k" "$image"
  done
else
  echo "Install jpegoptim to optimize JPEG images"
fi

# Optimize PNG images
if hash optipng 2>/dev/null; then
  find public/images -type f -iregex ".*\.\(png\)" -print0 | while IFS= read -r -d '' image; do
    resize_image "$image"
    optipng -clobber -strip all -o $PNG_OPTIMIZATION_LEVEL "$image"
  done
else
  echo "Install optipng to optimize PNG images"
fi

# Optimize GIF images while keeping them animated
if hash gifsicle 2>/dev/null; then
  find public/images -type f -iregex ".*\.\(gif\)" -print0 | while IFS= read -r -d '' image; do
    resize_image "$image"
    gifsicle --batch --optimize=3 --resize-fit "${MAX_WIDTH}x" "$image"
  done
else
  echo "Install gifsicle to optimize GIF images"
fi

# Optimize WebP images
if hash cwebp 2>/dev/null; then
  find public/images -type f -iregex ".*\.\(webp\)" -print0 | while IFS= read -r -d '' image; do
    resize_image "$image"
    cwebp -q 80 "$image" -o "$image"
  done
else
  echo "Install cwebp to optimize WebP images"
fi
