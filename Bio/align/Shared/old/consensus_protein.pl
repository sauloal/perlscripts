#!/usr/pub/bin/perl5

my $SET             = {};

$SET->{G}           = ['G', [ G ]];
$SET->{A}           = ['A', [ A ]];
$SET->{I}           = ['I', [ I ]];
$SET->{V}           = ['V', [ V ]];
$SET->{L}           = ['L', [ L ]];
$SET->{M}           = ['M', [ M ]];
$SET->{F}           = ['F', [ F ]];
$SET->{Y}           = ['Y', [ Y ]];
$SET->{W}           = ['W', [ W ]];
$SET->{H}           = ['H', [ H ]];
$SET->{C}           = ['C', [ C ]];
$SET->{P}           = ['P', [ P ]];
$SET->{K}           = ['K', [ K ]];
$SET->{R}           = ['R', [ R ]];
$SET->{D}           = ['D', [ D ]];
$SET->{E}           = ['E', [ E ]];
$SET->{Q}           = ['Q', [ Q ]];
$SET->{N}           = ['N', [ N ]];
$SET->{S}           = ['S', [ S ]];
$SET->{T}           = ['T', [ T ]];
                      
$SET->{aromatic}    = ['a', [ F, Y, W, H ]];
$SET->{aliphatic}   = ['l', [ I, V, L ]];
$SET->{hydrophobic} = ['h', [ @{$SET->{aliphatic}->[1]},
			      @{$SET->{aromatic}->[1]},
                              A, G, M, C, K, R, T ]];
                      
$SET->{positive}    = ['+', [ H, K, R ]];
$SET->{negative}    = ['-', [ D, E ]];
$SET->{charged}     = ['c', [ @{$SET->{positive}->[1]}, 
			      @{$SET->{negative}->[1]} ]];
                      
$SET->{polar}       = ['p', [ @{$SET->{charged}->[1]}, Q, N, S, T, C ]];
$SET->{alcohol}     = ['o', [ S, T ]];
                      
$SET->{tiny}        = ['u', [ G, A, S ]];
$SET->{small}       = ['s', [ @{$SET->{tiny}->[1]}, V, T, D, N, P, C ]];
$SET->{turnlike}    = ['t', [ @{$SET->{tiny}->[1]}, @{$SET->{polar}->[1]} ]];

$SET->{any}         = ['.', [ G,A,V,I,L,M,F,Y,W,H,C,P,K,R,D,E,Q,N,S,T ]];

if (!@ARGV) {
    print STDERR "usage: $0 alignment_file [threshold%]...\n";
    print_sets();
    exit 0;
}
my $FILE       = shift @ARGV;
my @THRESHOLD;
if (@ARGV) {
    @THRESHOLD = @ARGV;
} else {
    @THRESHOLD = (90, 80, 70, 60, 50);
}

my @ID;
my %ALIGNMENT;
my %SCORE;
my $LENGTH;
my %CONCENSUS;

read_alignment($FILE);
printf "%-15s %s\n",          $ID[0], join("", @{$ALIGNMENT{$ID[0]}});
my $threshold; foreach $threshold (reverse sort @THRESHOLD) {
    compute_consensus($threshold);
    my $format = sprintf "%d%%", $threshold;
    printf "%-9s/%-4s  %s\n", 'consensus', $format, $CONCENSUS{$threshold};
}

sub class {
    my ($ref) = @_;
    if ($ref->[0]) {
	return $ref->[0];
    }
    return "?";
}
sub residues {
    my ($ref) = @_;
    if ($ref->[1]) {
	return \@{$ref->[1]};
    }
    return 0;
}

sub read_alignment {
    my ($file) = @_;
    my ($id, $line, %alignment);
    local (*TMP);

    open(TMP, "< $file") or die "can't open file '$file'\n";
    while ($line = <TMP>) {
	next    if $line =~ /^CLUSTAL/;

	if ($line =~ /^([^ 	]+)\s+([-a-zA-Z*.]+) *$/) {
	    if (! $alignment{$1}) {
		#new sequence identifier
		push @ID, $1;
	    }

	    #strip spaces,tabs,newlines: extend alignment array
	    $line = $2;
	    $line =~ tr/ \t\n//d;
	    push @{$ALIGNMENT{$1}}, split("", $line);
	}
    }
    close TMP;

    $LENGTH = check_lengths();
}

#check the sequence lengths and return alignment length
sub check_lengths {
    my ($id, $l);
    my $len = scalar(@{$ALIGNMENT{$ID[0]}}); 
    foreach $id (@ID) {
	if (($l = @{$ALIGNMENT{$id}}) != $len) {
	    die "sequence length differs for '$id' ($l)\n";
	}
    }
    return $len;
}

sub member {
    my ($pattern, $list) = @_;
    my $i;
    foreach $i (@$list) {
        return 1    if $i eq $pattern;
    }
    return 0;
}

sub compute_consensus {
    my ($threshold) = @_;
    my ($id, $column) = ("", []);

    for ($c = 0; $c < $LENGTH; $c++) {
	$column = [];
	foreach $id (@ID) {
	    if (${$ALIGNMENT{$id}}[$c] ne '-' and
		${$ALIGNMENT{$id}}[$c] ne '.') {
	        push @$column, ${$ALIGNMENT{$id}}[$c];
            }
        }
        if (@$column) {
	    tally_column($column);
	    #        print_long($c);
	    arbitrate($threshold);
	} else {
	    $CONCENSUS{$threshold} .= ' ';
	}
    }
}
    
sub tally_column {
    my ($column) = @_;
    my ($class, $aa);

    #zero column score votes by class
    foreach $class (keys %$SET) {
	$SCORE->{$class} = 0;
    }

    #tally scores by class
    foreach $class (keys %$SET) {
	foreach $aa (@$column) {
	    if (member($aa, residues($SET->{$class}))) {
		$SCORE->{$class}++;
	    }
	}
	$SCORE->{$class} = 100.0 * $SCORE->{$class} / @ID;
    }
}

sub arbitrate {
    my ($threshold) = @_;
    my ($class, $bestclass, $bestscore) = ("", 'any', 0);

    #choose smallest class exceeding threshold and
    #highest percent when same size
    foreach $class (keys %$SET) {

	if ($SCORE->{$class} >= $threshold) {

	    #this set is worth considering further
	    if (@{residues($SET->{$class})} < @{residues($SET->{$bestclass})}) {

		#new set is smaller: keep it
		$bestclass = $class;
		$bestscore = $SCORE->{$class};

	    } elsif (@{residues($SET->{$class})} == @{residues($SET->{$bestclass})}) {

		#sets are same size: look at score instead
		if ($SCORE->{$class} > $bestscore) {

		    #new set has better score
		    $bestclass = $class;
		    $bestscore = $SCORE->{$class};
		}
		
	    }
	}
    }
    if ($bestclass) {
	$CONCENSUS{$threshold} .= $SET->{$bestclass}[0];
    } else {
	$CONCENSUS{$threshold} .= $SET->{any}[0];	
    }
}

sub print_long {
    my ($c) = @_;
    my $class;
    print ${$ALIGNMENT{$ID[0]}}[$c];
    foreach $class (sort keys %$SET) {
	printf " %s=%5.1f", class($SET->{$class}), $SCORE->{$class};
    }
    print "\n";
}

sub print_sets {
    my ($class, $res);
    printf STDERR "    %-15s %-3s  %s\n", 'class', 'key', 'residues';
    foreach $class (sort keys %$SET) {
	printf STDERR "    %-15s %-3s  ", $class, $SET->{$class}[0];
	print STDERR join(",", sort @{$SET->{$class}[1]}), "\n";
    }
}
