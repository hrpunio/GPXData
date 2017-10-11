#!/usr/bin/perl
# Zmodyfikuj czas w pliku GPX wydrukuj zmodyfikowany
#
use DateTime;
use Getopt::Long;

my $USAGE = "Podaj czas: -s hh:mm:ss [-b] (if substract) PLIK.gpx > NOWYPLIK.gpx\n";
my $timeShift; my $substractYes;

GetOptions( "s=s"  => \$timeShift,
	    "b" => \$substractYes,
            "help|?" => \$showhelp,
);
if ( $showhelp || ! $timeShift ) { die $USAGE  ;  }

my $hrShift = 0; my $minShift = 0 ; my $secShift = 0;
($hrShift, $minShift, $secShift) = (split /:/, $timeShift) ;

while (<> ) {
   chomp();
   ##<time>2017-05-20T14:48:24Z</time>
   if (/<time>/) {
      $time_date = $_; $time_date =~ s/<[^<>]+>|[ \t]//g; 
      $time_date =~ s/[\-TZ]/:/g;
      ($year, $month, $day, $hour, $minute, $second) = split (/:/, $time_date);

   ##print STDERR "*** $year,$month,$day,$hour,$minute,$second ***\n";

   my $dt = DateTime->new( year => $year, month  => $month, day => $day,
     hour => $hour, minute => $minute, second => $second, );

   if ($substractYes) {
     $dt->subtract(hours => $hrShift, minutes => $minShift, seconds => $secShift);
   } else {
     $dt->add(hours => $hrShift, minutes => $minShift, seconds => $secShift);
   }

   $new_time = sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ", $dt->year, $dt->month, $dt->day,
     $dt->hour, $dt->minute, $dt->second;
   print STDERR "*** Converting: $year-$month-${day}T$hour:$minute:${second}Z ==> $new_time ***\n";
   print "<time>$new_time</time>\n";
   } else {
      print "$_\n";
   }
}
