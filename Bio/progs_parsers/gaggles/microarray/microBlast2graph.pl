#!/usr/bin/perl -w
use strict;

#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	-	22012	21953	42031GE_CneoSBc1_18001_24000_s_RC-60-1989|DIFF:-0.33|R265:0.28|CBS7750:-0.05|WM276:0.34|CORR:0.37|ANNO:CP000287_CGB_B6670C_ATP_binding_cassette_ABC_transporter_required_for_the_export_of_a_factor_putative_Ste6p_1491165_1496250.102813.supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B.22012_21953_3e-14	42031GE_CneoSBc1_18001_24000_s_RC-60-1989|DIFF:-0.33|R265:0.28|CBS7750:-0.05|WM276:0.34|CORR:0.37|ANNO:CP000287_CGB_B6670C_ATP_binding_cassette_ABC_transporter_required_for_the_export_of_a_factor_putative_Ste6p_1491165_1496250.102813	rna
my $outName = "micro_wave";
my %intFields = (
	DIFF    => undef,
	R265    => undef,
	CBS7750 => undef,
	CORR    => undef,
);

my @cols;
my %db;
print "READING\n";

while (<>)
{
	chomp;
	@cols = split(/\t/);

	next if ( index($_,"#") == 0 );
	#if ($cols[5])
	#{

	#}
	#42031GE_CneoSBc1_18001_24000_s_RC-60-1989|DIFF:-0.33|R265:0.28|CBS7750:-0.05|WM276:0.34|CORR:0.37|ANNO:CP000287_CGB_B6670C_ATP_binding_cassette_ABC_transporter_required_for_the_export_of_a_factor_putative_Ste6p_1491165_1496250.102813.supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B.22012_21953_3e-14	42031GE_CneoSBc1_18001_24000_s_RC-60-1989|DIFF:-0.33|R265:0.28|CBS7750:-0.05|WM276:0.34|CORR:0.37|ANNO:CP000287_CGB_B6670C_ATP_binding_cassette_ABC_transporter_required_for_the_export_of_a_factor_putative_Ste6p_1491165_1496250.102813
	#print join("\t", @cols[0..3]);

	my @fields = split(/\|/,$cols[5]);

	$db{$cols[0]}{$cols[2]}{frame} = $cols[1];
	$db{$cols[0]}{$cols[2]}{end}   = $cols[3];
	$db{$cols[0]}{$cols[2]}{id}    = $cols[0]."_".$cols[1]."_".$cols[2]."_".$cols[3];
	$db{$cols[0]}{$cols[2]}{type}  = $cols[6];
	$db{$cols[0]}{$cols[2]}{name}  = $cols[5];

	foreach my $field (@fields)
	{
		if ($field =~ /(\S+)\:(\S+)/)
		{
			my $name  = $1;
			my $value = $2;
			#print "\t\t$name => $value\n";
			$db{$cols[0]}{$cols[2]}{$name} = $value;
		} else {
			my $name = "probe";
			my $value = $field;
			#print "\t\t$name => $value\n";
			$db{$cols[0]}{$cols[2]}{$name} = $value;
		}
	}
}

print "OPENING FILES\n";
foreach my $int (keys %intFields)
{
	my $fn = $outName . "_" . $int . ".tab";
	my $fh;
	open($fh, ">$fn") or die;
	$intFields{$int} = $fh;
}

print "EXPORTING\n";
foreach my $chrom (sort keys %db)
{
	my $starts = $db{$chrom};
	foreach my $start (sort {$a <=> $b} keys %$starts)
	{
		my $data   = $starts->{$start};
		my $frame  = $data->{frame};
		my $end    = $data->{end};
		my $id     = $data->{id};
		my $type   = $data->{type};
		my $probe  = $data->{probe};
		my $name   = $data->{name};

		my $st = "$chrom\t$frame\t$start\t$end\t$id\t";
		my $nd = "\t$type\n";

		foreach my $key (keys %intFields)
		{
			my $val = $data->{$key};
			my $fh  = $intFields{$key};
			print $fh $st, $val, $nd;
		}
	}
}

print "CLOSING\n";
foreach my $int (keys %intFields)
{
	my $fh = $intFields{$int};
	close $fh;
}

1;
