#!/usr/bin/perl -w
# multiliner.pl
use strict;
my $filename = shift;
open (FILE, "<", $filename)  or  die "Failed to read file $filename : $! \n";
my $whole_file;
{
    local $/;
    $whole_file = <FILE>;
}
close(FILE);

my %hash;

find_diamond(\%hash, $whole_file);
printHash(\%hash);


sub printHash
{
    my $hash   = $_[0];
    my $father = $_[1];

    if (ref($hash) eq "HASH")
    {
        foreach my $key (keys %{$hash})
        {
                my $keyValue = $hash->{$key};
            my $gen;
            if ( defined $father)
                             { $gen  = "$father.$key" }
            else { $gen  = $key };
            printHash($keyValue, $gen);
        }
    }
    else
    {
        print $father, " => ", $hash, "\n";
    }
}




sub find_diamond
{
    my $father   = $_[0];
    my $fragment = $_[1];
    my %child;

    while ($fragment =~ m#\<(\w*).*?\>(.*?)\<\/\1\>#sg)
    {
        my %baby;
        my $key         = $1;
        my $value       = $2;

        find_diamond(\%baby, $value);

        if (keys %baby)
        {
            $child{$key}    = $value;
            #print "KEY $key HAS CHILD\n";
            $father->{$key} = \%baby;
        }
        else
        {
            #print "KEY $key HAS NO CHILD\n";
            $father->{$key} = $value;
        }
    }

    return \%child;
}
1;