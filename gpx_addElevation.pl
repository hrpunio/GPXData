#!/usr/bin/perl
# Dodaj informację o wysokości z Google
# USAGE: gpx_addElevation.pl plik.gpx > plikpoprawiony.gpx
use XML::DOM;
use LWP::Simple; # from CPAN
use JSON qw( decode_json ); # from CPAN

my $SLEEPTIME = 2;

my $geocodeapi = "https://maps.googleapis.com/maps/api/elevation/json?locations";
my $log_file_name = `date +"%Y%m%d%H%M" | tr -d '\n'` . "_elevation.log";
open (PLG, ">$log_file_name") || die "Cannot open $log_file_name!\n";

### ### ### ###
my $gmttime, $altitude, $distance;
my $parser = new XML::DOM::Parser;
print_gpx_header() ;

for my $file2parse (@ARGV) {
  my $doc = $parser->parsefile ($file2parse);

  for my $t ( $doc->getElementsByTagName ("trk") ) {

       for my $p ( $t->getElementsByTagName ("trkpt") ) {  $nodeNo++;
            
            my $latitude = $p->getAttributeNode ("lat")->getValue() ;
            my $longitude = $p->getAttributeNode ("lon")->getValue() ;
  
            ## te elementy są opcjonalne
            @tmp = $p->getElementsByTagName ("time");
            if ($#tmp >= 0 ) {
	      $gmttime = $p->getElementsByTagName ("time")->item(0)->getFirstChild->getNodeValue(); } 
	    else {$gmttime=''; }
            
            @tmp = $p->getElementsByTagName ("ele");
            if ($#tmp >= 0 ) { 
               $altitude = $p->getElementsByTagName ("ele")->item(0)->getFirstChild->getNodeValue();
            } else { $altitude ='' }

            @tmp = $p->getElementsByTagName ("desc");
            if ($#tmp >= 0 ) { 
               $distance = $p->getElementsByTagName ("desc")->item(0)->getFirstChild->getNodeValue();
            } else { $distance ='';}
            
            ### ###
            my @trueAlt = getElevation($latitude, $longitude); sleep $SLEEPTIME;
            my $trueAltitude = $trueAlt[0]; ## <--- google alt

            print STDERR "*** Processing node $nodeNo [$latitude $longitude] [$gmttime] ***\n";

       	    printf "<trkpt lat=\"%.5f\" lon=\"%.5f\">",  $latitude, $longitude;

            if ($gmttime) { print "<time>$gmttime</time>" }

            print "<ele>$trueAltitude</ele>";

            printf "<desc>DIST=%s;ALT=%.1f</desc>", $distance, $altitude;

            print "</trkpt>\n";
        }
   } 

}

print_gpx_trailer();

### ### ########### ################################################
### Header ########
sub print_gpx_header {
print "<?xml version='1.0' encoding='UTF-8' ?>
<gpx version='1.1' creator='GPXmerger'
     xmlns='http://www.topografix.com/GPX/1/1'
     xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
     xsi:schemaLocation='http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd'>
<author>tomasz przechlewski </author>
<email>tprzechlewski[at]acm.org</email>
<url>http://pinkaccordions.homelinux.org/Geo/gpx/</url>
<trk><name></name><trkseg>\n" }

### ### ###########
### Trailer #######
sub print_gpx_trailer { print "</trkseg></trk></gpx>\n"; }

### ### ###########
### Eleveation ####
sub getElevation($){
    my $lat = shift;
    my $lon = shift;
    my $elevationG = $resolutionG = $latG = $lngG = '';

    ## https://maps.googleapis.com/maps/api/elevation/json?locations=39.7391536,-104.9847034
    ## 
    my $url = $geocodeapi . "=$lat,$lon";
    my $json = get($url);
  
    print PLG ">>>$address ## $url <<<\n$json\n";
    my $d_json = decode_json( $json );
  
    if ( $d_json->{status} eq 'OK' ) {
        $elevationG = $d_json->{results}->[0]->{elevation};
        $resolutionG = $d_json->{results}->[0]->{resolution};
        $latG = $d_json->{results}->[0]->{location}->{lat};
        $lngG = $d_json->{results}->[0]->{location}->{lng};
    }
    return ($elevationG, $resolutionG ,$latG, $lngG);
}                              
