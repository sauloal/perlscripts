#!/usr/bin/perl -w
use strict;
use warnings;

use lib 'lib';
use anno;
use rna;
use loadconf;
use readTab;
use saveXml;

my $cnf  = loadconf->new();

my $inputMergedTabFile = $cnf->get('reader.inputExpTab');
my $inputAnnoTabFile   = $cnf->get('reader.inputAnnoTab');
my $outXml             = $cnf->get('reader.outXml');
print "
INPUT MERGED TAB  FILE : $inputMergedTabFile
INPUT MERGED ANNO FILE : $inputAnnoTabFile
";

my $mergedFile = readTab->new(inTabFile => $inputMergedTabFile, firstLine => 1);
my $annoFile   = readTab->new(inTabFile => $inputAnnoTabFile,   firstLine => 1);

die if ! defined $mergedFile;
die if ! defined $annoFile;

my %annoSetup = (
	inTable => $annoFile,
	primaryColumn => $cnf->get('anno.primaryColumn')
);
my $anno = anno->new(%annoSetup);
die if ! defined $anno;

my %rnaSetup = (
	primaryColumn => $cnf->get('rna.primaryColumn'),
	mergeCols     => $cnf->get('rna.mergeCols'),
        extraCols     => $cnf->get('rna.extraCols'),
	leftCol       => $cnf->get('rna.leftCol'),
	rightCol      => $cnf->get('rna.rightCol'),
	
	anno          => $anno,
	
	inTable       => $mergedFile,
);

my $rna     = rna->new(%rnaSetup);
die if ! defined $rna;

my $data    = $rna->getData();
die if ! defined $data;

my $xml     = saveXml->new(title      => 'rnaSeq',
                           sourceTab  => $inputMergedTabFile,
                           sourceAnno => $inputAnnoTabFile
                           );
die if ! defined $xml;

my $dataStr = $xml->printXml($data);
die if ! defined $dataStr;


open XML, ">$outXml" or die "COULD NOT OPEN $outXml: $!";
print XML $dataStr;
close XML;

print "DONE\n";
