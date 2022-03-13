# gm_tiles_cutter
Perl script to split image into google map tiles.

## Description

This script allows you quickly split map image into Google map tiles to load into SAS Planet. 
Preferable usecase is first step binding before you will do it carefully with a high accuracy.
Map image should be oriented as your favorite satelite map (North should be upside). Next you need to determine coordinates of the top left corner and top right corner of an image.
Script will determines image resolution in meters per pixel and creates tiles from highest zoom level to lowest specified with -z option or to 0 by default. Directories with tiles will be created in directory of a source image.
It uses Perl ImageMagick.

## Usage
If image is large you should change limits specified for ImageMagick in policy.xml and use it as default configuration.
Example policy.xml included. You can specified it by running:
```
export MAGICK_CONFIGURE_PATH=$HOME/gm_tiles_cutter/

```
Check limits:
```
identify -list resource
```

Options:
```
-i, --image             source image to split into tiles
-z, --minzoom           lowest zoom level
-l, --topleft           coordinates of the top left corner of an image
-r, --topright          coordinates of the top right corner of an image
```

```
./gm_tiles_cutter.pl -l 56.272771 37.098078 -r 56.272772 37.630222 -z 12 -i /var/www/web/test/1.jpg

```

