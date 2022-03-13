#!/usr/bin/perl

use Image::Magick;
use Getopt::Long;
use Math::Trig;
use File::Path qw(mkpath);
use File::Basename;
use warnings;
use strict;
use POSIX;

my (@top_left, @top_right, $help, $image);
my $minZoom = 0;

Getopt::Long::GetOptions (
  'z=i' => \$minZoom, 'minzoom=i' => \$minZoom,
  'i=s' => \$image, 'image=s' => \$image,
  'l=f{2}' => \@top_left, 'topleft=f{2}' => \@top_left,
  'r=f{2}' => \@top_right, 'topright=f{2}' => \@top_right,
  'help' => sub {print_help()}
) or die "Incorrect usage!\n";

if (!defined($image) || !defined($top_left[0]) || !defined($top_left[1]) || !defined($top_right[0]) || !defined($top_right[1])) {
    print_usage();
    exit 1;
}

my $tileSize = 256;
my $dir = dirname($image);
my $pic = new Image::Magick;
my $x = $pic->Read($image);
print "Used memory: ".$pic->Get('memory')."\n";
my $zoom = getZoomLevel($top_left[0], $top_left[1], $top_right[0], $top_right[1]) - 1;
print "Determined zoom level is $zoom\n";

for (my $z = $zoom; $z >= $minZoom ; $z--){
  print "Creating zoom level $z\n";
  my $width = $pic->Get('width');
  my $height = $pic->Get('height');
  my $x_canvas = $width - ($width % $tileSize) + $tileSize;
  my $y_canvas = $height - ($height % $tileSize) + $tileSize;
  my ($offx, $offy) = getPixelOnTile($top_left[0], $top_left[1], $z);
  if (($x_canvas - $width) < $offx){
    $x_canvas = $x_canvas + $tileSize;
  }
  if (($y_canvas - $height) < $offy){
    $y_canvas = $y_canvas + $tileSize;
  }
  my $map = Image::Magick->new(size=>$x_canvas.'x'.$y_canvas);
  $map->ReadImage('canvas:transparent');
  $map->Composite(image=>$pic,compose=>'over',x=>$offx,y=>$offy);
  $pic->Resize(width=>$width/2,height=>$height/2);
  my $tiles = $map->Transform(crop=>($tileSize).'x'.($tileSize));
  my ($xtile, $ytile) = getTileNumber($top_left[0], $top_left[1], $z);
  my $x = $xtile;
  my $y = $ytile;
  my $in_tile_width = $x_canvas/$tileSize;

  for (my $i = 0; $tiles->[$i]; $i++){
    if($i > 0 && $i % $in_tile_width == 0) {
      $x = $xtile;
      $y++;
    }
    mkpath($dir.'/Z'.$z.'/'.$y);
    imageWrite($tiles->[$i], $x, $y, $z);
    $x++;
  }
#  @$tiles = ();
#  @$map = ();
  undef $map;
  undef $tiles;
}

sub imageWrite {
  my ($tile, $x, $y, $z) = @_;
  my $result = $tile->Write(filename=>$dir.'/'.'Z'.$z.'/'.$y.'/'.$x.'.jpg');
  return;
}

# Determine number of the top left tile
sub getTileNumber {
  my ($lat,$lon,$zoom) = @_;
  my $xtile = int( ($lon+180)/360 * 2**$zoom ) ;
  my $ytile = int( (1 - log(tan(deg2rad($lat)) + sec(deg2rad($lat)))/pi)/2 * 2**$zoom ) ;
  return ($xtile, $ytile);
}

# Determine pixel on tile with specified coordinates
sub getPixelOnTile {
  my ($lat,$lon,$zoom) = @_;
  my $scale = 256 << ($zoom - 1);
  my $xpix = int($scale + ($scale * $lon / 180));
  my $ypix = int($scale - $scale/pi * log((1 + sin($lat * pi /180))/(1 - sin($lat * pi/180)))/2);
  
  return ($xpix % $tileSize, $ypix % $tileSize);
}


# Calculate distance between two points in meters.
sub calcDistance {
  my ($lat1, $lon1, $lat2, $lon2) = @_;
  my $earthRadius = 6371;

  $lat1 = deg2rad($lat1);
  $lon1 = deg2rad($lon1);
  $lat2 = deg2rad($lat2);
  $lon2 = deg2rad($lon2);

  my $dLon = $lon2 - $lon1;
  my $dLat = $lat2 - $lat1;

  my $ans = pow(sin($dLat/2),2) + cos($lat1) * cos($lat2) * pow(sin($dLon/2),2);
  $ans = 2 * asin(sqrt($ans));
  $ans = $ans * $earthRadius;

  return $ans*1000;
}

# Determine zoom level by meters per pixel value
sub zoomLevel {
  my ($pixInMeters) = @_;
  my $zoom = 3;
  my $res = 19658;
  while($pixInMeters < $res) {
    $res = $res / 2;
    $zoom++;
  }
  return $zoom
}

sub getZoomLevel {
  my $width = $pic->Get('width');
  my ($lat1, $lon1, $lat2, $lon2) = @_;

  my $zoom = zoomLevel(calcDistance($lat1, $lon1, $lat2, $lon2) / $width);
  return $zoom;
}

sub print_usage {
    print "Usage: gm_tiles_cutter.pl -z <zoom> -l <latitude longitude> -r <latitude longtitude> -i <path/to/image>\n";
}

sub print_help {
    print "PERL script to split image into Google Maps tiles\n
";

print_usage();

print "
Options:
-h, --help              print help
-i, --image             source image to split into tiles
-z, --minzoom           lowest zoom level
-l, --topleft           coordinates of the top left corner of an image
-r, --topright          coordinates of the top left corner of an image
";
}
