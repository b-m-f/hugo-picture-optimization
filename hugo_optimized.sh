name: Branch Build Hugo - EN_alt

on:
  workflow_dispatch:
  push:
    branches:
      - master
    paths:
      - "!contents/**" # Exclude the contents folder
      - "!github/**" # Exclude the .github folder
      - "!git/**" # Exclude the .git folder
      - "config/**"
      - "static/**"
      - "layouts/**"
      - "i18n/**"
      - "themes/**"
      - "contents/**/*.en.md"
      - "index.en.md"
      - "**/index.en.md" # Include only *.en.md files within the content folder
      - "index.en.html"
      - "**/index.en.html"
      - "bump.md"

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v2

      - name: Set up Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: "0.122.0"
          extended: true

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y imagemagick perl libimage-exiftool-perl jpegoptim optipng gifsicle pngcrush webp

      - name: Build Hugo site
        uses: actions/cache@v3
        with:
          path: /tmp/hugo_cache
          key: ${{ runner.os }}-hugomod-en
          restore-keys: |
            ${{ runner.os }}-hugomod-en

      - name: Build Hugo site
        run: hugo --cleanDestinationDir -D -E -F  --minify --enableGitInfo --cacheDir /tmp/hugo_cache --config /home/runner/work/simeononsecurity.ch/simeononsecurity.ch/config/language/en/config_alt.toml

      - name: Optimize images
        run: |
          MAXIMUM_JPG_SIZE=250
          PNG_OPTIMIZATION_LEVEL=2
          MAX_WIDTH=1400
          NUM_PARALLEL_JOBS=8 # Number of parallel jobs for processing
          PUBLIC_DIR="/home/runner/work/simeononsecurity.ch/simeononsecurity.ch/public"

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
            # Remove EXIF data from JPEG and PNG images
            if hash exiftool 2>/dev/null; then
              find ${PUBLIC_DIR} -type f -iregex ".*\.\(jpeg\|jpg\|png\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'process_exif "$0"'
            else
              echo "Install perl-image-exiftool to optimize images"
            fi

            # Optimize JPEG images
            if hash jpegoptim 2>/dev/null; then
              find ${PUBLIC_DIR} -type f -iregex ".*\.\(jpeg\|jpg\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_jpeg "$0"'
            else
              echo "Install jpegoptim to optimize JPEG images"
            fi

            # Optimize PNG images
            if hash optipng 2>/dev/null && hash pngcrush 2>/dev/null; then
              find ${PUBLIC_DIR} -type f -iregex ".*\.\(png\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_png "$0"'
            else
              echo "Install optipng and pngcrush to optimize PNG images"
            fi

            # Optimize GIF images while keeping them animated
            if hash gifsicle 2>/dev/null; then
              find ${PUBLIC_DIR} -type f -iregex ".*\.\(gif\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_gif "$0"'
            else
              echo "Install gifsicle to optimize GIF images"
            fi

            # Optimize WebP images
            if hash cwebp 2>/dev/null; then
              find ${PUBLIC_DIR} -type f -iregex ".*\.\(webp\)" -print0 | xargs -0 -n1 -P$NUM_PARALLEL_JOBS bash -c 'optimize_webp "$0"'
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

      - name: Delete non-public folders and files
        run: |
          find . -mindepth 1 -type d ! -path './public*' ! -path './.git*' ! -path './.github*' -print0 | xargs -0 rm -rf
          find . -maxdepth 1 -type f -not -name 'netlify.toml' -print0 | xargs -0 rm -f
      
      - name: Move files to root
        run: |
          mv ./public/* .
          rm -r ./public

      - name: Commit and push changes
        run: |
          git config user.name "${{ secrets.USERNAME }}"
          git config user.email "${{ secrets.EMAIL }}"
          git add .
          git commit -m "Update website-en-alt branch"
          git push --force --quiet origin HEAD:refs/heads/website-en-alt
        env:
          PERSONAL_ACCESS_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
