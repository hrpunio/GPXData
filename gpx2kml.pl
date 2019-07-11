#!/usr/bin/perl
use Getopt::Long;
use XML::DOM;
## Zamienia GPX na KML

my $color="ff0000ff";
my $number_w_sign="[\+\-]?[0-9\.]+";
my $quote_sign="[ \t]*[\"'][ \t]*";
my $segment = '';
my @Segments ;

GetOptions(  "gpx=s" => \$gpx_file, "kml=s" => \$kml_file, "name=s"  => \$kml_name, );

unless (defined ($kml_name)) { $kml_name = "$gpx_file"; }
unless (defined ($kml_file)) { $kml_file = "$gpx_file"; 
   $kml_file =~ s/\.([^.]+)$//; $kml_file = "${kml_file}.kml"; }

print STDERR "*** Convering $gpx_file to $kml_file ($kml_name)\n";

my $parser = XML::DOM::Parser->new( ErrorContext => 1 );

my $log = $parser->parsefile("$gpx_file");
my $lon ; my $lat ;
my $total_dist ;

for $t ( $log->getElementsByTagName('trkseg') ) {

  my $segment='';
  my $trkpt=1;
  for $f ( $t->getElementsByTagName('trkpt') ) { 
    my $gpx_lat = $f->getAttributeNode ("lat")->getValue() ;
    my $gpx_lon = $f->getAttributeNode ("lon")->getValue() ;

    my @times = $f->getElementsByTagName("time");
    if (@times > 0) { $gpx_time = '';
      my @tmp__ = $times[0]->getChildNodes;
      foreach my $node ( @tmp__ ) { $gpx_time .= $node->getNodeValue } }
    
    ## Wysokość
    my @eles = $f->getElementsByTagName("ele");
    if (@eles > 0) {
      $gpx_ele = '';
      my @tmp__ = $eles[0]->getChildNodes;
      foreach my $node ( @tmp__ ) { $gpx_ele .= $node->getNodeValue }
    }
    $segment .= "$gpx_lon,$gpx_lat,$gpx_ele ";
    if ($trkpt == 1 ) {    push (@SegmentsStarts, "$gpx_time"); }
    $trkpt++;
  }
  push (@SegmentsEnds, "$gpx_time");
  push (@SegmentsPointsNo, "$trkpt");
  push (@Segments, $segment);
}

#### ####
open (KML, ">${kml_file}") || die "Cannot open ${kml_file}\n";
#### ####

print KML "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
 . "<!-- Converted with gpx2kml.pl by tp -->\n"
 . "<kml xmlns=\"http://www.opengis.net/kml/2.2\" xmlns:gx=\"http://www.google.com/kml/ext/2.2\">\n"
 . "<Document><name>${kml_name}</name> <open>1</open>\n"
 . "<Style id=\"Photo\"><IconStyle><Icon><href>http://maps.google.com/mapfiles/ms/icons/red.png</href></Icon></IconStyle></Style>\n"
 . "<Style id=\"Track\"><LineStyle><color>$color</color><width>4</width></LineStyle><PolyStyle><color>$color</color></PolyStyle></Style>\n";

my $track_no=0;
for $s (@Segments) { 
   printf STDERR "Segment: %03i :: %s--%s (%i)\n", $track_no, $SegmentsStarts[$track_no],
       $SegmentsEnds[$track_no], $SegmentsPointsNo[$track_no];
   start_track ($track_no);
   print KML "$s";
   stop_track();

   $track_no++;
}

print KML "</Document></kml>";

## ## ## ### ### ###
sub start_track {
   my $t = shift;
   my $tlabel = sprintf "%03i", $t;
   print KML "<Placemark><name>Track $tlabel</name><visibility>1</visibility><styleUrl>#Track</styleUrl>"
     . "<LineString><extrude>1</extrude><tessellate>1</tessellate><coordinates>";
}

sub stop_track {
   print KML "</coordinates></LineString></Placemark>\n\n";
}

