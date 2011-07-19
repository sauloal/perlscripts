#!/usr/bin/perl -w
use strict;
my $sortAlphabetical = 0;
my $sortAppearence   = 1;
my $printList        = 0;

#venn diagram analysis compare lists
#"pathogenicity","GE_CneoSBc14_180001_186000_s_RC-60-2415"
#"pathogenicity","GE_CneoSBc12_636001_642000_s_PSO-60-4691"
#"survival_sqrt","GE_CneoSBc8_738001_744000_s_RC-60-4911"
#"survival_sqrt","GE_CneoSBc1_132001_138000_s_PSO-60-4139"


if ( ! ($ARGV[0]) ) { die "PLEASE SPECIFY INPUT FILE\n"; };

my $input = $ARGV[0];
open FILE, "<$input" or die "COULD NOT OPEN FILE $input: $!";
my @values;
my @names;
my %seenValue;
my %seen;
my %seenCount;
my %seenComb;
my $maxComb  = 0;
my $maxTimes = 0;
my $maxNamesValuesLen = 0;
my %seenNames;

my $line        = 0;
my $nameCount   = -1;
my $nameOld     = "";
my $maxNameLen  = 0;
my $maxValueLen = 0;

while (<FILE>)
{
    $line++;
    if (/^\"(\S+)\",\"(\S+)\"$/)
    {
        my $name  = $1;
        my $value = $2;
        if ($name ne $nameOld)
        {
            $nameCount++;
            $nameOld = $name;
            $maxNameLen = length($name) if (length($name) > $maxNameLen);
            $names[$nameCount] = $name;
        }
        $seenNames{$name}++;
        $maxValueLen       = length($value)            if (length($value) > $maxValueLen);
        $maxNamesValuesLen = length($seenNames{$name}) if (length($seenNames{$name}) > $maxNamesValuesLen);

        push(@{$values[$nameCount]}, $value);
        $seenValue{$value}++;
    }
    else
    {
        die "INVALID FORMAT ON LINE $line:\n\t$_\n";
    }
}

print "TOTAL NAMES        : " . @names . "\n";
print "TOTAL VALUES       : " . $line  . "\n";
print "TOTAL UNIQUE VALUES: " . (keys %seenValue) . "\n";
foreach my $name (sort keys %seenNames)
{
    printf "\t%-" . $maxNameLen . "s: %0" . $maxNamesValuesLen . "d\n", $name, $seenNames{$name};
}

# heart - count to each values in which names it has appeared
for (my $a =0; $a < @values; $a++)
{
    my $array = $values[$a];
    my $id = (2**$a);
    for (my $b = 0; $b < @{$array}; $b++)
    {
        my $value = ${$array}[$b];
        $seen{$value} += $id;
    }
}

# lungs - retrieve how many times each combination has appeared
foreach my $value (keys %seen)
{
    my $comb = $seen{$value};
    $seenComb{$comb}++;
    $maxComb  = length($comb)            if (length($comb) > $maxComb);
    $maxTimes = length($seenComb{$comb}) if (length($seenComb{$comb}) > $maxTimes);
}






#eyes - reports
foreach my $comb (sort {$a <=> $b} keys %seenComb)
{
    printf "COMBINATION %0" . $maxComb . "d HAS APPEARES %0" . $maxTimes . "d TIMES > ", $comb, $seenComb{$comb};
    foreach my $factor (sort &factorTwo($comb))
    {
        printf "  %-" . $maxNameLen . "s", $names[$factor];
    }
    print "\n";
}


if ($printList)
{
    if ($sortAlphabetical)
    {
        foreach my $name (sort keys %seen)
        {
            my $value = $seen{$name};
            printf "ELEMENT %-" . $maxValueLen . "s APPEARS IN SETS ", $name;
            foreach my $factor (sort &factorTwo($value))
            {
                printf "  %-" . $maxNameLen . "s", $names[$factor];
            }
            print "\n";
        }
    }
    elsif ($sortAppearence)
    {
        foreach my $name (sort keys %seen)
        {
            my @factors = &factorTwo($seen{$name});
            $seenCount{$name} = scalar(@factors);
        }

        foreach my $name (sort by_value sort { $b cmp $a }keys %seenCount)
        {
            my $value = $seen{$name};
            printf "ELEMENT %-" . $maxValueLen . "s APPEARS IN SETS ", $name;
            foreach my $factor (sort &factorTwo($value))
            {
                printf "  %-" . $maxNameLen . "s", $names[$factor];
            }
            print "\n";
        }
    }
}











if (0){
@names = (
"ST",
"ND",
"RD",
"4TH",
"5TH",
"6TH",
"7TH",
);
@values = (
["a", "b", "c", "d", "e"], 
["b", "c", "d", "e", "f"], 
["c", "d", "e", "f", "a"], 
["d", "e", "f", "a", "b"], 
["e", "f", "a", "b", "c"],
["f", "a", "b", "c", "d"],
["a", "b", "c", "d", "g"]
);
}




sub by_value { $seenCount{$b} <=> $seenCount{$a}; };

sub factorTwo
{
    my $number = $_[0];
    my $start  = log2($number);
    if ($start == int($start)) { return ($start); } else { $start = int($start); };

    $start = int($start);
    my @factors;

    while ($number > 0)
    {
        if ( ($number - (2**$start)) >= 0)
        {
            $number = $number - (2**$start); 
            push(@factors, $start);
        }
        $start--;
    }

    return @factors;
}

sub log2 {
    my $n = shift;
    return (log($n)/log(2));
}