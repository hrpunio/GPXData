#!/usr/bin/perl
# Zamienia wiele plików GPX na jeden (bez powtórzeń śladu)
# Uwaga1: na przepalatające się segmenty
# Uwaga2: plik GPX musi mieć strukturę <trk><trkseg>...
use Getopt::Long;
use XML::DOM;

GetOptions("name=s" => \$gpx_name, );

my $parser = XML::DOM::Parser->new( ErrorContext => 1 );

for ($f=0; $f<=$#ARGV; $f++) {

  $gpx_file = $ARGV[$f];

  print STDERR "### Parsing $ARGV[$f]...\n";

  my $log = $parser->parsefile("$gpx_file") || die "Cannot parse $gpx_file\n";

  for $t ( $log->getElementsByTagName('trkseg') ) {

    my $trkpt=1; my $gpx_lat; my $gpx_lon ;

    for $f ( $t->getElementsByTagName('trkpt') ) { 
      $gpx_lat = $f->getAttributeNode ("lat")->getValue() ;
      $gpx_lon = $f->getAttributeNode ("lon")->getValue() ;

      my @times = $f->getElementsByTagName("time");
      if (@times > 0) {
	$gpx_time = '';
	my @tmp__ = $times[0]->getChildNodes;
	foreach my $node ( @tmp__ ) { $gpx_time .= $node->getNodeValue } }

      ## zapisz raz
      unless (exists($GPS_META{"start"})) { $GPS_META{"start"} = $gpx_time }
      ## Wysokość
      my @eles = $f->getElementsByTagName("ele");
      if (@eles > 0) {
	$gpx_ele = '';
	my @tmp__ = $eles[0]->getChildNodes;
	foreach my $node ( @tmp__ ) { $gpx_ele .= $node->getNodeValue }
      }

      if ($trkpt == 1 ) { push (@SegmentsStarts, "$gpx_time"); $segment_flag='S'; }
      else { $segment_flag=''; }

      $Points{"$gpx_time"}="$gpx_lat;$gpx_lon;$gpx_ele;$segment_flag;$gpx_file";

      ## zapisz bez powtórzeń (jeżeli się powtarza był w innym segmencie ##
      if ($trkpt == 1 ) {    push (@SegmentsStarts, "$gpx_time"); }
      $trkpt++;
    }
    ## popraw ostatni punkt na koniec segmentu
    $Points{"$gpx_time"}="$gpx_lat;$gpx_lon;$gpx_ele;E";

  }
}

#### ####
# Wypisz połączony ślad
#### ####
unless (defined ($gpx_name)) { $gpx_name = "Track: $GPS_META{start}"; }

print '<?xml version="1.0" encoding="UTF-8"?>'
  . "<gpx version=\"1.1\" creator=\"gpx_merge.pl\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
  . "<metadata><time>$GPS_META{start}</time></metadata>\n"
  . "<trk><name>$gpx_name</name>\n";

my $seg;
my $segmentIn=0;
for $t (sort keys %Points) {
  my ($lat, $lon, $ele, $flag, $file) =  split (/;/, $Points{$t});
  if ($flag eq 'S') {$seg++; 
     if ( $segmentIn == 1) { 
        print "</trkseg>\n<trkseg><!--###-->\n"; ## segments overlap
        print STDERR " finish $t]] (emergency!)\n";
     } else { 
       print "<trkseg>\n";   
     }
     $segmentIn=1; 
     print STDERR "[[ Segment $seg / $file start $t..."
  }

  print "<trkpt lat=\"$lat\" lon=\"$lon\"><ele>$ele</ele><time>$t</time></trkpt>\n";

  if ($flag eq 'E') {
     if ( $segmentIn == 1) { print "</trkseg>\n"; $segmentIn=0; 
     print STDERR " finish $t]]\n"; }
  }
}

print "</trk></gpx>\n";

## ## ##
