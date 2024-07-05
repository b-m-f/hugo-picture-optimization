# Hugo Picture Optimization

This tool will first build your website using Hugo and then apply a few optimizations to the pictures that were copied to the output folder. The **original images will NOT be changed**.

Currently JPG, PNG, GIF, and WebP are supported.

- The default optimization level for PNG is 2.
- JPEG images will come out with 250kb or less.
- Pictures with a width bigger than 1400px will be resized to a width of 1400px and a height according to the ratio.
- GIF images will be optimized while keeping them animated.
- WebP images will be resized to a width of 1400px if larger and then optimized.

## How to Use

Download the script and execute it inside the root of your Hugo repository from the command line.

You might have to make it executable with `chmod +x hugo_optimized.sh`.

## Dependencies

- Linux, BSD, or MacOS
- hugo
- perl-image-exiftool
- jpegoptim
- optipng
- imagemagick
- gifsicle
- webp
