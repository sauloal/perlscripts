package mem;
use strict;
use warnings;


sub new
{
    my $class  = shift;
    my $self   = bless {}, $class;

    my $script = substr($0, rindex($0,"/")+1);
    #my $pid    = `pgrep $script`;
	my $pid    = $$;
    chomp $pid;
	my $cmd = "top -b -n 1 | grep \"$pid\"";
	my $valid = 0;

	print "NEW MEM :: VALID ",($pid ? "Y" : "N")," :: SCRIPT \"$script\" PID \"$pid\" CMD \"$cmd\"\n";

	if ( $pid )
	{
		$valid = 1;
		$self->{valid}  = $valid;
		$self->{script} = $script;
		$self->{pid}    = $pid;
		$self->{cmd}    = $cmd;
		$self->{max}    = 0;
	}

    return $self;
}

sub get
{
	my $self    = shift;
	my $valid   = $self->{valid};

	if ($valid)
	{
		my $results = $self->{results};
		my $pid     = $self->{pid};
		my $cmd     = $self->{cmd};
		my $script  = $self->{script};
		my $max     = $self->{max};

		print "PROCESS $script [$pid]:: $cmd\n";

		for (my $p = 0; $p < @$results; $p++)
		{
			my $desc   = $results->[$p][0];
			my $result = $results->[$p][1];
			printf "\t%-".$max."s\t:\t%s\n", $desc, $result;
		}
	}
}

sub add
{
	my $self   = shift;
	my $desc   = $_[0];
	my $print  = $_[1] || 0;
	my $valid   = $self->{valid};

	if ($valid)
	{
		my $cmd    = $self->{cmd};
		my $pid    = $self->{pid};
		my $script = $self->{script};

		$self->{max} = length $desc if (length $desc > $self->{max});

		my $result = `$cmd`;

		if ( defined $result )
		{
			$result =~ s/\s+/ /g;
			$result =~ s/\s/\t/g;
			$result =~ s/^\s+//g;
			$result =~ s/\s+$//g;
			chomp $result;

			if ( $print )
			{

				print "PROCESS $script [$pid]:: $cmd : $desc => \"$result\"\n";
			}
			push(@{$self->{results}}, [$desc, $result]);
		} else {
			print "ERROR ADDING MEM :: $script [$pid] : $cmd : $desc\n";
		}
	}
}

1;
