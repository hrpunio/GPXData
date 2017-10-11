#!/usr/bin/perl
# Cadence calculator for GarminEdge tcx files (or converted fits)
# tprzechlewski@gmail.com
use Getopt::Long;

my $prev_Time = -1;
my $parsingTrack ='N';
my $regCadence = 'N';
my $min_speed = -1; # minimum speed
my $trackNo=1;

GetOptions( "s=f"  => \$min_speed, );
$min_speedMS = ($min_speed *1000)/3600.0;

if ($min_speed > 0) {
  print "*** Segments with speed below $min_speed kmh skipped ***\n";
}

while (<>) {
  chomp();

  # Order is importany (first check for <Track>:
  if ( /<Track>/ ) {
    if ( $regCadence eq 'N' ) {
      ## Check if Cadence is registered
      print STDERR "*** No cadence registered! ***\n";
      exit 1;
    } else {
      $parsingTrack = 'Y' ; print STDERR "### Parsing track #$trackNo...\n";
      $trackNo++;
    }
  }

  # Parsing header:
  if ($parsingTrack eq 'N' ) {
    if ( /<TotalTimeSeconds>/) {
      $edge_LapTime = xmlEleValue('TotalTimeSeconds', $_) ; }
    elsif (/<Cadence>/) {
      $edge_LapCadence = xmlEleValue('Cadence', $_) ; $regCadence = 'Y' }
    elsif (/<DistanceMeters>/) {
      $edge_LapDist = xmlEleValue('DistanceMeters', $_) ;  }
    ##print STDERR "## Parsing track info: $_\n";
    next;
  }


  ## start parsing Track now:
  if (/Speed>/)  { $speed = xmlEleValue ('Speed', $_);
  } elsif ($_ =~ /<Time>(.*)T(.*)Z<\/Time>/ ) {
    $time = $2;
    ($h, $m, $s )  = split /:/, $time;
    $current_time = $h * 60 * 60  + $m * 60 + $s ;
    ##print STDERR "$current_time\n";
  } elsif (/<Cadence>/ ) {
    $cadence = xmlEleValue ('Cadence', $_);
  } elsif (/<DistanceMeters>/ ) { 
    $distance = xmlEleValue ('DistanceMeters', $_);
  } elsif ($_ =~ /<\/Trackpoint>/ ) {

    if ( $prevTime > 0 ) {## pomija pierwsze
      $lastTime = $current_time ;
      if ($cadence > 0 && $speed > $min_speedMS ) {
	$timeDiff = $current_time - $prevTime; 

	$total_time_cycled += $timeDiff ;
	$total_cycles += $cadence * $timeDiff / 60; ## 

	$prevTime = $current_time ;
      }
      else {
	$timeDiff = $current_time - $prevTime; 

	$total_time_idle += $timeDiff ;

	$prevTime = $current_time ;
      }

    } else {
     $prevTime = $current_time ;
     $firstTime = $current_time ;
  }

 }

if ( /<\/Track>/ ) {
   $total_Time = $total_time_idle + $total_time_cycled;

   printf "Time = Idle: %d s Spinning: %d s Total: %d s\n", $total_time_idle,
      $total_time_cycled, $total_Time;
   printf "Time = Idle: %.2f%% Spinning: %.2f%% Total: %.2f%%\n",
      $total_time_idle/$total_Time *100,
      $total_time_cycled/$total_Time * 100, $total_Time/$total_Time *100;

   print "Rotations (total) = $total_cycles\n";
   print "Mean cadence (computed) = " . $total_cycles/$total_time_cycled * 60 . "\n";

   $totalTimeTime = $lastTime - $firstTime;

   print "Total time (last - first) = $totalTimeTime s\n";

  print "Registered (header) values: lap time: $edge_LapTime "
    . "cadence: $edge_LapCadence lap distance (m): $edge_LapDist\n";
  
  ## reset values ## ## ## 
  $grand_total_time_idle += $total_time_idle; 
  $grand_total_time_cycled  += $total_time_cycled ;
  $grand_total_cycles += $total_cycles ;
  $grand_total_Dist +=  $edge_LapDist;

  $total_time_idle = $total_time_cycled = $total_cycles = 0 ;
  $prev_Time = -1; 
  $parsingTrack ='N';
  $regCadence = 'N';
}

} ##/while

## Grand Totals:
$trackNo--;
$grand_total_Time = $grand_total_time_idle + $grand_total_time_cycled;

print "====== Totals/means for $trackNo tracks =====\n";
printf "Time = Idle: %d s Spinning: %d s Total: %d s\n", $grand_total_time_idle,
      $grand_total_time_cycled, $grand_total_Time;
   printf "Time = Idle: %.2f%% Spinning: %.2f%% Total: %.2f%%\n",
      $grand_total_time_idle/$grand_total_Time *100,
      $grand_total_time_cycled/$grand_total_Time * 100, 
      $grand_total_Time/$grand_total_Time *100;
print "Rotations (total) = $grand_total_cycles\n";
print "Mean cadence (computed) = " . $grand_total_cycles/$grand_total_time_cycled * 60 . "\n";
print "Total distance (registered): $grand_total_Dist (m)\n";

## ### ### ### ### ###

sub xmlEleValue {
  my $en = shift; # element name
  my $el = shift; # line

  $el =~ /<$en>(.*)<\/$en>/;

  return "$1";

}
