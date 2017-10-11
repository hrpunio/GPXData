#!/usr/bin/perl 
# Compute various statistics of GPX track 
#
use Geo::Distance; 
use Getopt::Long;
my $geo = new Geo::Distance;

my $qchars = "\042\047"; # znaki cytowania pojedynczy i podwojny
my $skip_hdr="Y" ;
my $lap_min_limit = -1; # no limit
my $lap_max_slope_limit = 0.0; ## 
my $lap_max_slope = -99;

print "*** USAGE: ???";
print "*** =====\n";

GetOptions( 'l=s' => \$lap_min_limit, 's=f' => \$lap_max_slope_limit,  );
my $time = '';
my $pointCNo = 0;

while (<>) {
     if ( /<trk>/ ) { $skip_hdr = "N" }
     elsif ( /<\/trk>/ ) { $skip_hdr = "Y" }

     if ($skip_hdr eq "Y") { next ; }

     if (/lat\s*=\s*[$qchars]([^$qchars]+)[$qchars]/) { $lat = $1; }
     if (/lon\s*=\s*[$qchars]([^$qchars]+)[$qchars]/) { $lon = $1 ; }

     ## time is optional
     if ( /<time>([^<>]+)<\/time>/ )                 { $time = $1; } else { $time = '' }
     if ( /<ele>([^<>]+)<\/ele>/ )                   { $elevation = $1; } else { $elevation = '' }

     if ( /<\/trkpt/ ) {
        $pointCNo++; 
        if ($time) { $TimeStamps{$time} = "$lat:$lon:$elevation"; } else 
        { $pointCNoTxt = sprintf "%05.5s", $pointCNo;
          $TimeStamps{$pointCNoTxt} = "$lat:$lon:$elevation"; }

        if ($verbatim) { print ">> $pointCNoTxt = $lat:$lon\n"; }
     }

}

my $lonP = $latP = $eleP = -999; ## previous values
my $lap_distance = 0;

my $left_keys = keys %TimeStamps;

printf "no;lat;lon;dist;tdist;alt;slope\n";

foreach $t ( sort  keys( %TimeStamps ) ) {
	$left_keys-- ;

	unless ($lonP == -999 ) {
          ($lat, $lon, $ele) = split (/:/, $TimeStamps{$t} );
          $dist = $geo->distance( "meter", $lonP, $latP => $lon, $lat );
          ##$lap_elevation = $ele - $eleP;
          $lap_distance += $dist;
          $total_distance += $dist;
          if (($lap_distance < $lap_min_limit) && ($left_keys > 0) ) { ; }
	  else { 
                  ## pierwszy odcinek
                  unless ($lonPl) {  $lonPl = $lonP ; $latPl = $latP; $elePl = $eleP }
                  $ldist = $geo->distance( "meter", $lonPl, $latPl => $lon, $lat );

                  ## jeżeli $lap_min_limit = 0 to lap_distance może == 0
                  if ($lap_distance > 0) {
                      $lap_elevation = $ele - $elePl;
                      $lap_slope = $lap_elevation / $lap_distance * 100 ;


                      if ($lap_slope > $lap_max_slope && $lap_distance > 25 ) { 
                         $lap_max_slope = $lap_slope  ;
                         print STDERR " ^^LMS SET^^ $lap_slope > $lap_max_slope (max) $lap_elevation / $lap_distance  => $lat:$lon\n"; 
                      }
		      else {  
                         ##print STDERR " ^^^^ $lap_slope > $lap_max_slope \n"; 
                      }
                      if ($lap_slope > $lap_max_slope_limit ) { 
                        $total_laps_over_limit += $lap_distance; 
                      }

                  } else { $lap_slope = 0 }

       		  printf "%s;%f;%f;%.3f;%.2f;%.1f;%.1f\n", $t, $lat, $lon, 
	              $lap_distance, $total_distance, $lap_elevation, $lap_slope ;
                  ##print STDERR "########### $latPl:$lonPl => $lat:$lon ############\n";

                  $total_lap_distance += $ldist;
                  $lap_distance = 0 ;
                  $lonPl = $lon ; $latPl = $lat ; $elePl = $ele
          }
	}
          $lonP = $lon ; 
	  $latP = $lat ;
          $eleP = $ele ;

          ##print STDERR "########### $left_keys -> $t ***********\n";
}

###

print "Distance computed: $total_distance / $total_lap_distance ($pointCNo)\n";
print "Max slope: $lap_max_slope\n";
if ($lap_max_slope_limit > 0 ) { 
  "Distance with min slope $lap_max_slope_limit : $total_laps_over_limit\n"; } 
