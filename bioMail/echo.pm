#!/usr/bin/perl -w
use strict;
use warnings;
use lib "./lib";
use loadconf;
my %pref = &loadconf::loadConf;
package echo;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(echo);
our $DESCRIPTION="Returns every sent command and its reverse. Testing purpose";

sub echo
{
    my $input = $_[0]; #body of the incoming message untreated

    my $output = "$input \n" . reverse($input);

    return $output; #body of the outgoing message untreated
}




1;