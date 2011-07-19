#!/usr/bin/perl
# Saulo Aflitos
# 2009 09 15 16 07
#
use strict;
use warnings;

package idd2file;

use lib "./";
use DBIconnect;
use loadconf;


##########
## IDD2FILE - RETURNS A HASH WITH ORGANISM ID AND ITS RESPECTIVE FILE
##########
sub idd2file
{
	my %pref = &loadconf::loadConf;
	my $originalTableOrganismId = $pref{originalTableOrganismId};
	my %idd2file;
	print "_"x2, "IDD2FILE :: STARTING GETTING FILES NAMES\n";

	my $dbh       = &DBIconnect::DBIconnect();
	my $startTime = time;
	
    my $OrganismOrganismId = $pref{OrganismOrganismId};
    my $OrganismFilename   = $pref{OrganismFilename};
    my $OrganismTable      = $pref{OrganismTable};
	my $db 				   = $pref{database};

	my $commandGetFileNames = "SELECT $OrganismOrganismId, $OrganismFilename FROM `$db`.`$OrganismTable`";

	my $retT = time;
	print "_"x6, "IDD2FILE :: RETRIEVING FILE NAMES: \"$commandGetFileNames\"\n";
	
	my $sth = $dbh->prepare($commandGetFileNames);
	$sth->execute() or die "DBD ERROR: $!";
	my $rows = $sth->rows;


	die if (( ! $rows ) || ( $rows == 0));
	
	print "_"x6, "IDD2FILE :: ",$rows, " VALID RESULTS RETRIEVED SUCCESSIFULLY IN " , (time - $retT) , "s\n";


	my $row;
	my $countRow = 0;
	while($row = $sth->fetchrow_arrayref) 
	{
		die if ( ! defined $row );

		print "_"x8, "IDD2FILE :: EXPORTING VALID ROW # $countRow: ";

		my $id       = $row->[0];
		my $filename = $row->[1];

		die if (! defined $id);
		die if (! defined $filename);
		
		$idd2file{$id} = $filename;
		
		print "$id > $filename\n";
		
		$countRow++;
	}

	if ( ! $countRow ) { die "NO FILENAME TO GET"; };

	$sth->finish();
	$sth = undef;
	$dbh->disconnect();
	$dbh = undef;

	print "_"x6, "IDD2FILE :: ",$rows, " FILENAMES RETRIEVED IN " , (time - $startTime) , "s\n\n";

	return \%idd2file;
}

1;