#!/usr/bin/perl
#
# C+2GPX
#
use Geo::Coordinates::DecimalDegrees;
#
#710
#00:11:49,000 --> 00:11:50,000
#$GPRMC,061217.00,A,5412.67912,N,01906.59706,E,12.982,253.48,240917,,,A*56      ## Position, velocity, and time
#                                              ^^^^^^        ^^^^^^
#                                              speed         date
#$GPGGA,061217.00,5412.67912,N,01906.59706,E,1,05,1.37,24.9,M,32.4,M,,*6F       ## Time, position, and fix related data
#       ^^^       ^^           ^^            ^^^^
#       time      lat          lon           Q S
#
#
my $yearBase = 2000;
my $knots2mps = 0.514444 ;

## Garmin Virb needs 1.1 version of GPX
print "<?xml version='1.0' encoding='UTF-8'?>
<gpx version='1.1' creator='Perl' xmlns='http://www.topografix.com/GPX/1/1'><trk><trkseg>\n";

while (<>) {
    chomp($_); $_ =~ s/\015//g; ## remove DOS e-o-ls

    if ($_ =~ m/^[0-9]+$/ ) { $recordNo="$_"; }
    elsif ($_ =~ /GPRMC/) { @gprmc = split (/,/, $_ ); $speed = $gprmc[7] * $knots2mps; 
        $date = nmeaDate2date($gprmc[9]) ;  
    }
    elsif ($_ =~ /GPGGA/) { @gpgga = split (/,/, $_ ); 
        $time = nmeaTime2time($gpgga[1]); 

        $quality = $gpgga[6];
        ##print STDERR "Q: $quality<\n";
        if ( $quality == 1) { $lat = dm2dec($gpgga[2], $gpgga[3], 2) }
        if ( $quality == 1) { $lon = dm2dec($gpgga[4], $gpgga[5], 3) }

        $satelites = $gpgga[7];
        $ele = $gpgga[9]; ## eleveation meters

        ##print "$recordNo lat: $lat lon: $lon speed: $speed time: $time date: $date ($timeFrs)\n";
        if ($quality != 0 ) {
         printf "<trkpt lat=\"%f\" lon=\"%f\"><ele>%f</ele><time>%s%s</time><speed>%f</speed><cmt>$recordNo $timeFrs</cmt></trkpt>\n",
            $lat, $lon, $ele, $date, $time, $speed;
         $gpxpoints++;
        }
    }
    elsif ($_ =~ /-->/)   { $timeFrs = "$_"; }
}


print "</trkseg></trk><!-- $gpxpoints --></gpx>\n";

### 
sub dm2dec {
  my $c = shift;
  my $sign = shift;
  my $l = shift;

  my $d = substr ($c, 0, $l);
  my $m = substr ($c, $l);

  if ($sign eq 'W' || $sign eq 'S') { $sign = -1 }
  elsif ( $sign eq 'E' || $sign eq 'N' ) { $sign = 1 }
  else {   die "*** Wrong geocoordinate format: $c, $sign"; }

  ##print STDERR ">>> $d $m ($c)\n";
  return ( $sign * dm2decimal($d, $m));
} 

sub nmeaTime2time {
  my $nt = shift;
  
  my $h = substr ($nt, 0, 2);
  my $m = substr ($nt, 2, 2);
  my $s = substr ($nt, 4, 2);

  return ( "$h:$m:${s}Z" );
}

sub nmeaDate2date {
  my $nd = shift;
  
  my $d = substr ($nd, 0, 2); my $m = substr ($nd, 2, 2);
  my $y = substr ($nd, 4, 4) + $yearBase;

  return ( "$y-$m-${d}T" );
}
