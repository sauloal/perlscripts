#!/usr/bin/perl -w
use warnings;
use strict;
# use Data::Dumper;
package threading;

use Cwd qw(realpath);
use File::Basename;
my $script_name = basename($0);

my $minmen      = "0.2"; # minimum of memory to be kept free
my $renice  = 1;     # renice process (increase priority - needs SUDO)
my $sleeptime   = 1;     # sleep time in case the computer runs out of resource

# use FindBin;
# use lib "$FindBin::Bin/lib";
# use threading;
# my @pid;
# my $multithread = 0;     # enable multithread
#
#
#   my $pid = threading::multiThread("in",$multithread);
#   push(@pid, $pid) if ($pid > 1);
#   if ($pid <= 1)
#   {
# 
#       YOUR CODE GOES HERE!!!
# 
#   threading::multiThread("out",$multithread);
#   }
# &threading::checkprocess(\@pid,$multithread); # check how many processes are still in execution avoinding the close of parent while still executing child

sub multiThread
{
    my $position    = $_[0]; # in or out
    my $multithread = $_[1];
    my $verbose     = $_[2]; # verbose

    my $filename    = realpath($0);

    print "\t\tCALLING MULTITHREAD $$\n" if $verbose;

    if ($multithread) # if multithread
    {
        $SIG{CHLD} = 'IGNORE';
        my $free = &free;

#       if ($free <= 0.1) { die "PROCESS OVERFLOW. PLEASE LOWER DOWN MINIMUM MEMORY\n"; };
        if ($position eq "in") # if IN
        {
            print "\t\tMULTITHREAD $$ IN\n" if $verbose;

            if ($free >=$minmen) # if free memory bigger than minimum
            {
                print "\t\tMULTITHREAD $$ IN >$minmen " . $free . "\n" if $verbose;
                my $pid = fork(); # fork
                if ($pid) # if parent
                {
#                   push(@pid, $pid); # put in PID list
                    print "\t\tMULTITHREAD $$ IN >$minmen PARENT\n" if $verbose;
                    return $pid; # return 0 avoiding re-executing the comand after threading function call
                }
                elsif ($pid == 0) # if child
                {
                    print "\t\tMULTITHREAD $$ IN >$minmen RENICE\n" if $verbose;
                    if ($renice) { `sudo renice -10 $$`; };
                    return 1; # return 1 to execute the code after the threading function call
                }
            }
            else # if there's not enought memory
            {
                print "\t\tMULTITHREAD $$ IN <$minmen PARENT\n" if $verbose;
                print "FREE $free SLEEP\n";
                do {
                    sleep($sleeptime); # sleep
                } while (&free < $minmen);
                multiThread("in",1); # try again to multithread
            }
        }
        elsif ($position eq "out") # if OUT
        {
            print "\t\tMULTITHREAD $$ OUT\n" if $verbose;
#           &listThreads($filename) if ($filename); #list active threads
            exit(0); # leave thread
        }
        else
        {
            die "COULDNT FORK\nTURN THREAD OFF\n";
        }
    }
    else # if not threadening, return 1 to execute code after the threading function call without forking
    {
        return 1;
    } #END IF MULTITHREAD
} #END MULTITHREAD

sub listThreads
{
    my $program = $_[0]; # get program name
    my @working = `ps aux | grep $program`; # get lint of instances of the program
#   print "PROGRAM $program\n";
#   print @working . " PROCESSES STILL ACTIVE: " . join("\t",@working) . "\n";
    print @working . " PROCESSES ACTIVE\n"; # print number of active processes
};

sub checkprocess
{
    my @pid     = @{$_[0]};
    my $multithread = $_[1];
    if ($multithread) #if multithread activated
    {
#       print "WAITING " . @pid . " PRINTING PROCESSES TO FINISH\n";
        foreach (@pid) # foreach saved PID
        {
            waitpid($_,0);# wait till the last to exit program
        };
    };
};

sub free
{
    my @memory = `free`; # get the memory status via FREE system call
    my $total;
    my $used;
    my $free;
    foreach my $line (@memory)
    {
        if ($line =~ /^Mem:\s{1,}(\S{1,})\s{1,}(\S{1,})\s{1,}(\S{1,})/)
        {
#           print "TOTAL\tUSED\tFREE\n";
            $total = int($1 / 1024);
            $used  = int($2 / 1024);
            $free  = int($3 / 1024);
#           print "$total\t$used\t$free\n";
        }
    }
    return ($free / $total); # return proportion free
}

1;