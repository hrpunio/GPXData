#!/usr/bin/perl
# Analizuje plik GPX | 
# Zapisuje plik uproszczony (z opcją reduce/max)
# Generates simplified GPX file if used

use XML::LibXML;
use Getopt::Long;
use Geo::Distance;
use POSIX;
use File::Basename;
use utf8;

#binmode(S_GPX, ":utf8"); ## after open

my $geo = new Geo::Distance;

my $USAGE = "*** USAGE: $0 -gpx gpx-file [-max integer][ -reduce integer]\n"
  . "*** where:\n*** gpx -- gpx-file to analyze"
  . "*** max -- max number of nodes for each track\n"
  . "*** reduce -- % of nodes to reduce (for each track, 100 - reduce remains)\n"
  . "*** tmpdir -- directory for temporary files, /tmp by default\n";

my $gpxfile;
my $maxTrkPts = -1;
my $reductionCoeff = -1;

my $tmp_file_dir = '/tmp';

GetOptions( "gpx=s"  => \$gpxfile,
	    "max=i" => \$maxTrkPts,
	    "tmpdir=s" => \$tmp_file_dir,
	    "reduce=i" => \$reductionCoeff, ## % reduction
	    "help|h|?" => \$showhelp, );

if ($showhelp ) { print "$USAGE"; exit 1;}

my $gpxfile_basename = basename($gpxfile);

if ( $reductionCoeff > 0 ) { $reductionCoeff = (100 - $reductionCoeff) / 100; }

my $tmp_file_name = "$tmp_file_dir/${gpxfile_basename}.tmp";

if ( -e "$gpxfile" ) {
my $gpxfile = `xmllint -encode UTF-8  $gpxfile`;

##print $gpxfile;
##XML::DOM is nonstandard. You should use XML::LibXML
  
$parser = XML::LibXML->new();

  
### ### ### ### ###
my   $trkpt_trk_no = 0;
### ### ### ### ###

print STDERR "### ### Analysing ###\n";
open TIMELOG, ">/tmp/timelog.txt";

my $log = XML::LibXML->load_xml ( string => (\$gpxfile));

  for $t ( $log->getElementsByTagName('trk') ) {
    $trkpt_trk_no++;
    $trk_dst = 0;
    print "*** NEW track ($trkpt_trk_no)\n";

    $trkPt = $t->toString();
    $TrkPts{$trkpt_trk_no} = $trkPt ;
    
    $trk_total_nodes = 0;
    $trkpt_segment_no = 0 ;
    $segments = '';
    
    for $s ( $t->getElementsByTagName('trkseg') ) {
      $trkpt_current_no = 0;
      $trkpt_segment_no++;
      $segment_dst = 0;
      %Track = ();
      
      for $f ( $s->getElementsByTagName('trkpt') ) {
	$trkpt_current_no++;
	##$trkPt = $f->toString();

	my $gpx_ele = -1000; # dla pewności na depresji
	my $gpx_lat = $f->getAttributeNode ("lat")->getValue() ;
	my $gpx_lon = $f->getAttributeNode ("lon")->getValue() ;

	my @eles = $f->getElementsByTagName("ele");
	if (@eles > 0) { $gpx_ele = $eles[0]->toString(); $gpx_ele =~ s/<[^<>]+>//g; }

	my @times = $f->getElementsByTagName("time");
	$gpx_curr_time = $times[0]->toString();
	$gpx_curr_time =~ s/<[^<>]+>//g;
	##print TIMELOG "$gpx_curr_time\n"; ##
	
	## jeżeli nie ma elementu ele
	if ($gpx_ele < 0 ) {
	  $Track{$gpx_curr_time} =  "$gpx_lon,$gpx_lat,0";
	  ## ## ###
	  ##$TrkPts{$trkpt_trk_no}{$gpx_curr_time} = $trkPt ;
	}
	else {
	  $Track{$gpx_curr_time} =  "$gpx_lon,$gpx_lat,$gpx_ele";
	  ##$TrkPts{$trkpt_trk_no}{$gpx_curr_time} = $trkPt ;
	}

      }

      ## Oblicz dystans
      $lonB = -999; $latB = -999 ; $NN=0;
	
      foreach $tt (sort keys(%Track ) ) {
	($lat, $lon, $ele) = split /,/, $Track{$tt};
	if ( $lonB  > -999 ) {
	  $NN++;
	  $curr_dist = $geo->distance( "meter", $lonB, $latB => $lon, $lat );
	  $segment_dst += $curr_dist;
	  ## print "### $tt ### $curr_dist ::: $lonB, $latB => $lon, $lat ($NN)\n";
	} else { $first_node_timestamp = $tt }
	  
	$lonB = $lon ;
	$latB = $lat ;
	$last_node_timestamp = $tt;
      }

      $trk_total_nodes += $trkpt_current_no;
     
      $trk_dst += $segment_dst;
    	
      $curr_segments = "[$trkpt_segment_no=$trkpt_current_no $segment_dst]" ;
      $all_segments .= $curr_segments;

      print "---> $curr_segments $trk_dst\n";
      ##die;
    }

    $trk_grand_total_nodes += $trk_total_nodes;
    $trk_grand_total_dst += $trk_dst;
    
    print "Total distance ($trkpt_trk_no) $trk_dst | First node $first_node_timestamp"
      . " Last node: $last_node_timestamp\n"; ##
    print "Total number of trk nodes: $trk_total_nodes | \n";
    print "\n"; ## end of track
    $TrkPtsNo{$trkpt_trk_no} = $trk_total_nodes;
    
  }

##}
$trk_grand_total_dst = $trk_grand_total_dst /1000; ## km
print "GRAND TOTALS: $trk_grand_total_nodes (nodes) | $trk_grand_total_dst (distance km) \n";


### #### ### ### ### ### ###
unless ($reductionCoeff > 0 || $maxTrkPts > 0 ) { exit 0 }
### Redukcja

print STDERR "### ### Writing simplified files for each track ###\n";

for my $t (sort keys %TrkPts ) {

  #  for my $p ( keys %{ $TrkPts{ $t } } ) {
  #    print "$t $p $TrkPts{$t}{$p}\n";
  if ( $reductionCoeff > 0 ) {
    $maxTrkPts = floor ($reductionCoeff * $TrkPtsNo{$t}) ;
  }

  ##print "... ### Track no $t ($TrkPtsNo{$t} => $maxTrkPts nodes)\n";
  $out_tmp_file_name = "$tmp_file_name$t";
  
  if ($maxTrkPts > 0 ) {##
    open (TMP, ">$tmp_file_name");
    binmode(TMP, ":utf8");
    
    print TMP "<?xml version='1.0' encoding='UTF-8' standalone='yes'?>\n"
      . "<gpx version='1.1' xmlns='http://www.topografix.com/GPX/1/1'>\n";
    print TMP "$TrkPts{$t}\n";
    print TMP "</gpx>\n";
    close (TMP);
    
    $GPSBABEL = `gpsbabel -i gpx -f $tmp_file_name -x simplify,count=$maxTrkPts -o gpx -F $out_tmp_file_name`;
    push (@gps_files, $out_tmp_file_name);
    print STDERR "    ... Writing track $t TO $out_tmp_file_name ($TrkPtsNo{$t} => $maxTrkPts)\n";
  }

  ###print "$t $TrkPts{$t}\n";
  }
}

## Sklejamy do kupy #############################################################
print STDERR "### ### Writing ${gpxfile_basename}.simplified file ###\n";
open (S_GPX, ">${gpxfile_basename}.simplified");
binmode(S_GPX, ":utf8");

print S_GPX "<?xml version='1.0' encoding='UTF-8' standalone='yes'?>\n"
  . "<gpx version='1.1' xmlns='http://www.topografix.com/GPX/1/1'>\n";

for my $file (sort @gps_files ) {
  print STDERR "    ... Appending $file to ${gpxfile_basename}.simplified file\n";
  my $gpxTmp = $parser->parse_file("$file");

  for $t ( $gpxTmp->getElementsByTagName('trk') ) { $trkPt = $t->toString(); }
  print S_GPX "$trkPt\n";
}

print S_GPX "</gpx>\n";

close (S_GPX);

### koniec ###

