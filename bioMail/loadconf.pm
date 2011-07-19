#!/usr/bin/perl -w
use warnings;
use strict;
package loadconf;
use Cwd qw(realpath);
use File::Basename;

my $fullpath = dirname(realpath($0));

#  my $config = "/mnt/d/sys/debian/bio/config";
#  my $setup  = "/mnt/d/sys/debian/bio/setup";
my $print  = 1;

my $config = "$fullpath/config";


&loadConf;

######################
#USAGE:
######################
# use loadconf;
# my %pref = &loadconf::loadConf;
# 
# use Cwd qw(realpath);
# use File::Basename;
# my $fullpath = dirname(realpath($0));
# 
# my $wwwfolder   = $pref{"htmlPath"}; # http folder
# my $width       = $pref{"width"};;  # graphic width in pixels
# my $multithread = $pref{"multithreadGraphic"};     # enable multithread
# my $renice      = $pref{"reniceGraphic"};     # renice process (increase priority - needs SUDO)
# my $minscore    = $pref{"minscore"};

sub loadConf
{
    my %pref;

    open (CONFIG,"<$config");
    while (<CONFIG>)
    {
        chomp;                  # no newline
        s/#.*//;                # no comments
        s/^\s+//;               # no leading white
        s/\s+$//;               # no trailing white
        next unless length;     # anything left?
        if (/(\S+)\s+\=\s+(\S+)/)
        {
            $pref{$1} = $2;
        };
    };
    close CONFIG;


    if ($print)
    {
        foreach my $key (sort keys %pref)
        {
            print "$key => " . $pref{$key} . "\n";
        }
    }

    return %pref;
};

1;