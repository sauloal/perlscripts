#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use MLDBM;
use MLDBM qw (DB_File Storable);
use Tie::MLDBM;
use Fcntl;

tie %XMLpos, 'MLDBM', 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
(tied %XMLpos)->DumpMeth('portable');

my $id4 = $XMLpos{$id0}{$id1}{$id2} ? "$XMLpos{$id0}{$id1}{$id2}\t$id3" : $id3;

my $Tid3 = $XMLpos{$id0}{$id1}{$id2}; $Tid3 = $id4;
my $Tid2 = $XMLpos{$id0}{$id1};       $Tid2->{$id2} = $Tid3;
my $Tid1 = $XMLpos{$id0};             $Tid1->{$id1} = $Tid2;

    (tied %XMLpos)->sync();
#   print Data::Dumper->new([\%XMLpos],["XMLpos"])->Dump;