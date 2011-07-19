#!/usr/bin/perl -w
use strict;

my $interface            = "wlan0";
my $desiredNetwork       = "beehive";
my $scanCmd              = "iwlist $interface scan";
my $channelCmd           = "iwlist $interface channel";

#my $interface            = "wlan0";
#my $desiredNetwork       = "SpeedTouch360CE3";
#my $scanCmd              = "iwlist $interface scan";
#my $channelCmd           = "iwlist $interface channel";

my $printScan            = 1;
my $printScanParsing     = 1;
my $printScanDebug       = 1;

my $printChannels        = 0;
my $printChannelsParsing = 0;

my $scan     = &scan();
my $channels = &channels();
&printScan($scan)         if $printScan;
&printChannels($channels) if $printChannels;

&genReport({'scan' => $scan, 'channels' => $channels});

sub genReport
{
	print "GENERATING REPORT\n";
	my $par      = $_[0];
	my $scanData = $par->{scan};
	my $chanData = $par->{channels};

	my %report;
	$report{'DESIRED NETWORK'} = $desiredNetwork;

	foreach my $essid ( sort keys %$scanData )
	{
		print "\t", $essid, ($essid eq $desiredNetwork ? ' *' : ''), "\n";
		my $data = $scan->{$essid};

		if ($essid eq $desiredNetwork)
		{
			$report{'DESIRED NETWORK CURRENT CHANNEL'} = $data->{channel};
			$report{'DESIRED NETWORK CURRENT CELL'}    = $data->{cell};
			$report{'DESIRED NETWORK CURRENT MAC'}     = $data->{mac};
		} else {
			$report{'TOTAL NETWORKS'}++;
			$report{'TOTAL NETWORKS BY CHANNEL'}{$data->{channel}}++;
			$report{'TOTAL NETWORKS BY CELL'}{$data->{cell}}++;
		}
	}

	foreach my $key (sort keys %report)
	{
		my $value = $report{$key};
		if (ref $value eq 'HASH')
		{
			printf "\t%-31s ::\n", $key;
			foreach my $lKey ( sort {$a <=> $b} keys %$value )
			{
				my $lValue = $value->{$lKey};
				printf "\t\t%02d = %02d\n", $lKey, $lValue;
			}
		} else {
			printf "\t%-31s :: %s\n", $key, $value;
		}
	}
}


sub scan
{
	print "SCANNING\n";
	print "\tCMD :: $scanCmd\n" if $printScanParsing;
	my @results = `$scanCmd`;
	print @results if $printScanDebug;

	my %data;

	for (my $l =0; $l < @results; $l++ )
	{
		my $line = $results[$l];
		chomp $line;

		if ( $line =~ /Cell (\d+) - Address\: (\S+)/ )
		{
			print "\tCELL $line :: $1 $2\n" if $printScanParsing;
			my %lData;
			$lData{cell} = $1;
			$lData{mac}  = $2;

			for (my $d = $l+1; $d < @results; $d++)
			{
				my $data = $results[$d];
				chomp $data;

				if ( $data =~ /Cell (\d+) - Address\: (\S+)/ )
				{
					print "\tNEW CELL $data\n" if $printScanParsing;
					if ( exists $lData{essid} )
					{
						print "\t\tESSID $lData{essid}\n\n" if $printScanParsing;
						$data{$lData{essid}} = \%lData;
					}
					$l = $d - 1;
					last;
				}


				if ( $data =~ /Channel\:(\d+)/ )
				{
					print "\t\tCHANNEL $data :: $1\n" if $printScanParsing;
					$lData{channel} = $1;
				}
				elsif ( $data =~ /ESSID\:\"(\S+)\"/ )
				{
					print "\t\tESSID $data :: $1\n" if $printScanParsing;
					$lData{essid} = $1;
				}
				elsif ( $data =~ /Mb\/s/ )
				{
					print "\t\tSPEED $data\n" if $printScanParsing;
					while ( $data =~ /(\d+[\.\d+]*) Mb\/s/g )
					{
						print "    $1 Mb/s\n" if $printScanParsing;
						push(@{$lData{speeds}}, $1);
					}
				}
				elsif ( $data =~ /Mode\:(\S+)/ )
				{
					print "\t\tMODE $data :: $1\n" if $printScanParsing;
					$lData{mode} = $1;
				} else {
					$data =~ s/^\s+//;
					push(@{$lData{others}}, $data);
				}
			}
		}
	}
	return \%data;



          #Cell 01 - Address: 00:24:C4:1B:9C:C0
          #          Channel:1
          #          Frequency:2.412 GHz (Channel 1)
          #          Quality=39/70  Signal level=-71 dBm
          #          Encryption key:on
          #          ESSID:""
          #          Bit Rates:1 Mb/s; 2 Mb/s; 5.5 Mb/s; 6 Mb/s; 9 Mb/s
          #                    11 Mb/s; 12 Mb/s; 18 Mb/s
          #          Bit Rates:24 Mb/s; 36 Mb/s; 48 Mb/s; 54 Mb/s
          #          Mode:Master
          #          Extra:tsf=00000160bde9118c
          #          Extra: Last beacon: 1090ms ago
          #          IE: Unknown: 000100
          #          IE: Unknown: 010882848B0C12961824
          #          IE: Unknown: 030101
          #          IE: Unknown: 050400010000
          #          IE: Unknown: 07064E4C20010D17
          #          IE: Unknown: 0B050000028D5B
          #          IE: Unknown: 2A0100
          #          IE: Unknown: 32043048606C
          #          IE: Unknown: 851E05008F000F00FF0359004855422D5554522D574150303400000000000027
          #          IE: Unknown: 9606004096000200
          #          IE: WPA Version 1
          #              Group Cipher : TKIP
          #              Pairwise Ciphers (1) : TKIP
          #              Authentication Suites (1) : PSK
          #          IE: Unknown: DD06004096010104
          #          IE: Unknown: DD050040960305
          #          IE: Unknown: DD050040960B09
          #          IE: Unknown: DD050040961400
          #          IE: Unknown: DD180050F2020101800003A4000027A4000042435E0062322F00

}


sub printScan
{
	print "PRINT SCAN\n";
	my $hash = $_[0];

	foreach my $essid ( sort keys %$hash )
	{
		print "\t", $essid, "\n";
		my $data = $hash->{$essid};

		foreach my $key (sort keys %$data)
		{
			my $value = $data->{$key};

			if ( ref $value eq "ARRAY" )
			{
				printf "\t\t%-8s ::\n", $key;
				for (my $a = 0; $a < @$value; $a++)
				{
					my $aValue = $value->[$a];
					print "\t\t\t$aValue\n";
				}
			} else {
				printf "\t\t%-8s :: %s\n", $key, $value;
			}
		}
	}
}

sub channels
{
	print "LISTING CHANNELS\n";
	print "\tCMD :: $channelCmd\n" if $printChannelsParsing;
	my @results = `$channelCmd`;

	#print @results;
	my %availChannels;
	my $lastName;

	foreach my $line ( @results )
	{
		chomp $line;

		if ( $line =~ /Channel (\d+) \: \d+\.\d+ GHz/ )
		{
			print "\tCHANNEL $line\n" if $printChannelsParsing;
			my $channelNum = $1;
			if ( defined $lastName )
			{
				$availChannels{$lastName}{$channelNum} = 1;
			}
		}
		elsif ( $line =~ /(\S+)\s+(\d+) channels in total/ )
		{
			print "\tNAME $line\n" if $printChannelsParsing;
			$lastName  = $1;
		} else {
			$lastName  = undef;
		}
	}

	#wlan0     14 channels in total; available frequencies :
	#          Channel 01 : 2.412 GHz
	#          Channel 02 : 2.417 GHz
	return \%availChannels;
}

sub printChannels
{
	print "PRINT CHANNELS\n";
	my $hash = $_[0];

	foreach my $base ( sort keys %$hash )
	{
		my $numbers = $hash->{$base};
		print "\t$base\n";
		foreach my $number ( sort keys %$numbers )
		{
			print "\t\t$number\n";
		}
		print "\n";
	}
}

1;
