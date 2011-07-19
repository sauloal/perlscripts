#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 06 18 19 47
#TODO: TRANSFORME IN INSTANCIABLE MODULE SO ALL COMMANDS CAM BE SENT TO EACH INSTANCE
use strict;

package DBIconnect;
use lib "./";
use loadconf;
use DBI;

my %pref = &loadconf::loadConf;

my $location = "local";

sub DBIconnect
{
	my $database = $_[0] || $pref{"database"};	# mysql database
	my $host     = $pref{"host"};		# mysql host
	my $port     = $pref{"port"};		# mysql port
	my $user     = $pref{"user"};		# mysql user
	my $pw       = $pref{"pw"};			# mysql pw
	
	if ($location eq "local")
	{
		return DBIconnectLocal($database, $host, $port, $user, $pw);
	}
	elsif ($location eq "cloud")
	{
		return DBIconnectCloud($database, $host, $port, $user, $pw);
	}
	else
	{
		my $connectStr = "DBI:mysql:database=$database";
		if ((defined $host) && ($host ne "localhost") && ($host ne "127.0.0.1"))
		{
			$connectStr .= ";host=$host;port=$port";
		}
		
		my $dbh = DBI->connect($connectStr, $user, $pw, {RaiseError=>1, PrintError=>1, AutoCommit=>0})
			or die "COULD NOT CONNECT TO DATABASE $database $host $user: $! $DBI::errstr";
		
		return $dbh;
	}
}


sub DBIconnectLocal
{
	my $database = $_[0];	# mysql database
	my $host     = $_[1];	# mysql host
	my $port     = $_[2];	# mysql port
	my $user     = $_[3];	# mysql user
	my $pw       = $_[4];	# mysql pw
	
	my $connectStr = "DBI:mysql:database=$database";
	if ((defined $host) && ($host ne "localhost") && ($host ne "127.0.0.1"))
	{
		$connectStr .= ";host=$host;port=$port";
	}
	
	my $dbh = DBI->connect($connectStr, $user, $pw, {RaiseError=>1, PrintError=>1, AutoCommit=>0})
		or die "COULD NOT CONNECT TO DATABASE $database $host $user: $! $DBI::errstr";
	
	return $dbh;
}

sub DBIconnectCloud
{
	
}

1;