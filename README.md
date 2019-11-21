# Hugo picture optimization

This tool will first build you website using hugo and then aplly a few optimizations to the pictures that were copied to the output folder. The **original images will NOT be changed**.

Currently JPG and PNG are supported.

- The default optimization level for PNG is 2.
- JPEG images will come out with 250kb or less.
- Pictures with a width bigger than 1400px will be resized to a width of 1400px and a height according to the ratio

## Dependecies
- hugo
- perl-image-exiftool
- jpegoptim
- optipng
- imagemagick
