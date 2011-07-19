#!/usr/bin/perl -w
use warnings;
use strict;

###########################################
## MAIL SCRIPT AUTO RESPONDER
## V 3.3 2008 OCT 30 1053
## S.A. AFLITOS
###########################################
## TO DO
## ACCEPT FILE (HASH) IN RETURN
## ACCEPT FILE FROM USER
## FILTER ARRAY NOT STRING
## GENERATE BETTER LOG
###########################################

################################
## USES
################################

use File::Find;
use File::Basename;
use FindBin qw($Bin);
use lib "./lib";
use lib "./progs";
use msend;
use mreceive;

use loadconf;
my %pref = &loadconf::loadConf;

my $here         = `pwd`;
chomp $here;
chomp $here;
my $piddir       = "$here/logs";
chomp $piddir;
my $tmpcache     = "$here/logs";
chomp $tmpcache;

my $verbose  = $pref{"verbose"};
my %availModules = &loadRequests;
my $begin    = localtime;
my $n        = 0;



################################
## SETTINGS
################################

my $provider      = $pref{"provider"};
    # 1 cbsknaw@gmail.com
    # 2 knawcbsknaw@yahoo.com.br

my $deleteMail    = $pref{"deleteMail"};; # Delete mail after pop them
my $popVerbose    = $pref{"popVerbose"}; # verbosity of pop 0* - 4
my $smtpVerbose   = $pref{"smtpVerbose"}; # verbosity of smtp 0* or 1
my $filterVerbose = $pref{"filterVerbose"}; # verbosity of email counting after sender filtering

my $fromFilter    = $pref{"fromFilter"}; # incoming mail to accept commands

my $daemon        = $pref{"daemon"}; 

if ($daemon)
{
    &daemon();
}
else
{
    &runflow();
}

################################
## RUN FLOW
################################
sub runflow
{
    # sub execMail (%HASH) [%HASH] executes whenever command in the mail
    # sub respond_hash (%HASH) replies every mail in %HASH
    # sub filter_hash (%HASH,$FILTER) [%] filters hash having a given FILTER as FROM data
    # sub print_hash_DUO(%HASH2PRINT) [$] prints a 2 level hash
    # sub print_hash_UNO(%HASH2PRINT) [$] prints a 1 level hash
    # sub loadRequests loads all the .PM files in the progs dir as RESQUEST MODULE
    # sub askModule ($MODULE_NAME, $DATA) [$]  send to module $MODULE_NAME a data $DATA and returns the result og the analysis
    # &receive::receive_mail($PROVIDER[1GMAIL|2YAHOO], $DELETEMAIL[0*|1\2], $POPVERBOSE[0*|1])
    # &send::send_mail($PROVIDER[1GMAIL|2YAHOO],$TO, $SUBJECT, $BODY, $SMTPVERBOSE[0*|1]);

    print "WORKING WITH PID $$ STARTED AT $begin INTERATED $n TIMES\n";

#   my %job = &mreceive::receive_mail($provider,$deleteMail, $popVerbose); #1 gmail 2 yahoo
    (my $result, my $value) = &mreceive::receive_mail($provider,$deleteMail, $popVerbose); #1 gmail 2 yahoo
    if ( ! $result )
    {
        Log("IMPOSSIBLE TO RETRIEVE MESSAGE: $value");
        print "IMPOSSIBLE TO RETRIEVE MESSAGES: $value";
    }
    else
    {
        my %job = %{$value};

        if ((keys %job) > 0)
        {
            %job = &filter_hash(\%job,$fromFilter);
            if ((keys %job) > 0)
            {       
                if ($verbose >= 1) { print &print_hash_duo(\%job); };
                %job = &execMail(\%job);
                if ($verbose >= 1) { print &print_hash_duo(\%job); };
                &respond_hash(\%job);
            }
        }
        if ($daemon) { sleep($pref{"interval"}); };
        $n++;
    }
}


######
## DAEMONIZING
## http://www.linuxquestions.org/questions/programming-9/how-to-run-a-perl-script-as-a-daemon-109978/
## http://linux.softpedia.com/get/Programming/Widgets/Perl-Modules/Daemon-Simple-38315.shtml
## http://search.cpan.org/~khs/Daemon-Simple-0.03/lib/Daemon/Simple.pm
## http://blog.highspeedweb.net/2008/07/02/perl-on-linux-making-a-deamon/
######
sub daemon
{
    use POSIX qw(setsid);
    use DateTime;
    use Fcntl qw(:flock);
    use File::CacheDir qw(cache_dir);
    
    my $file     = $0;
    my $age      = -M $file;
    my $ageConf  = -M "./config";
    
    Log("Initializing...");
    
    chomp $piddir;
    chomp $tmpcache;
    
    Log("File - ".$file.", age - ".$age);
    Log("File - config, age - ".$ageConf);
    
    Status("Daemonizing...");
    
    my $pid = fork;
    
    if(!defined $pid)
    {
        Log("Unable to fork : $!");
        die;
    }
    
    if($pid)
    {
        Log("Parent process exiting, let the deamon (".$pid.") go...");
        sleep 3;
        exit;
    }
    
    POSIX::setsid;
    
    if ( -e "$piddir/" . $file . ".pid")
    {
        open(PID, "<$piddir/".$file.".pid");
        my $runningpid = <PID>;
        close PID;
        unlink "$piddir/".$file.".pid";
        while(-e "/proc/".$runningpid)
        {
            Status("Waiting for ".$runningpid." to exit…");
            Log("Waiting for ".$runningpid." to exit…");
            sleep 1;
        }
    }
    
    open (PID, ">$piddir/".$file.".pid");
    print PID $$;
    close PID;
    
    Log("The deamon is now running...");
    Status("Deamon running");
    
    my $stdout = cache_dir({base_dir => $tmpcache, ttl => '1 day', filename => "STDOUT".$$});
    my $stderr = cache_dir({base_dir => $tmpcache, ttl => '1 day', filename => "STDERR".$$});
    
    Log("STDOUT : ".$stdout);
    Log("STDERR : ".$stderr);
    open STDIN, '/dev/null';
    open STDOUT, '>>'.$stdout;
    open STDERR, '>>'.$stderr;
    
    # print "PID $$\n";
    open PID, ">$piddir/" . $file . ".pid";
    print PID $$;
    close PID;
    
    while(1)
    {
        &runflow();
    
        if ( ($age - (-M $file)) || ($ageConf - (-M "./config")) )
        {
            Log("File modified, restarting");
            #open(FILE, $file ." |");
            #close(FILE);
            last;
        }
    
        if(!-e "$piddir/".$file.".pid")
        {
            Log("Pid file doesn't exist, time go exit.");
            last;
        }
    
        sleep 1;
    }

}

################################
## SUB PROGRAMS
################################

sub Log
{
    # http://blog.highspeedweb.net/2008/07/02/perl-on-linux-making-a-deamon/
    my $string = shift;
    if($string)
    {
        my $time = DateTime->now();
        if(open(LOG, ">>$tmpcache/deamon.log"))
        {
            #flock(LOG, LOCK_EX);
            print LOG $$ . " [" . $time->ymd . " " . $time->hms . "] - ".$string . "\n";
            #flock(LOG, LOCK_UN);
            close LOG;
        }
    }
}

sub Status
{
    # http://blog.highspeedweb.net/2008/07/02/perl-on-linux-making-a-deamon/
    my $string = shift;
    if($string)
    {
        $0 = $pref{"statusName"} . "- " . $string;
    }
    return $0;
}

sub execMail
{
    my %to_do = %{$_[0]};
    my %done;

    foreach my $key (sort keys %to_do)
    {
        my $from = $to_do{$key}{"From"};
        my $subj = $to_do{$key}{"Subj"};
        my $body = $to_do{$key}{"Body"};
        (my $subjst) = ($subj =~ m#^(\S+)#);

        $done{$key}{"From"} = $from;

        if (($subjst eq "list") || ($subjst eq "test"))
        {
            %availModules = &loadRequests;
            if ($verbose >= 2) { print "\t$subjst AVAILABLE. EXECUTING\n"; };
            $done{$key}{"Subj"}  = "DONE :: $subj";
            $done{$key}{"Body"}  = printHeader("SUCCESS");
            $done{$key}{"Body"} .= printHeader("LISTING AVAILABLE MODULES");
            $done{$key}{"Body"} .= &print_hash_uno(\%availModules);
        }
        elsif (exists $availModules{$subjst})
        {
            if ($verbose >= 2) { print "\t$subjst MODULE AVAILABLE. EXECUTING\n"; };
            $done{$key}{"Subj"}  = "DONE :: $subj";
            my $result = &askModule($subjst, $body, $subj);
            $done{$key}{"Body"}  = printHeader("SUCCESS");
            $done{$key}{"Body"} .= printHeader("MODULE $subjst EXECUTED");
            $done{$key}{"Body"} .= "\n\n$result\n\n";
        }
        else
        {
            if ($verbose >= 2) { print "\t$subjst MODULE NOT AVAILABLE. TRY ANOTHER\n"; };
            $done{$key}{"Subj"}  = "FAIL :: $subj";
            $done{$key}{"Body"}  = printHeader("PROCESS FAILED");
            $done{$key}{"Body"} .= printHeader("MODULE NOT AVAILABLE");
            $done{$key}{"Body"} .= printHeader("PLEASE CHECK SPELLING");
            $done{$key}{"Body"} .= $body;
        }
    }

    return %done;
}

sub respond_hash
{
    my %to_do = %{$_[0]};

    foreach my $key (sort keys %to_do)
    {
        my $from = $to_do{$key}{"From"};
        my $subj = $to_do{$key}{"Subj"};
        my $body = $to_do{$key}{"Body"};
        my $bkp  = 1;

        if (($subj =~ /^DONE :: list/i) || ($subj =~ /^DONE :: test/i)) { $bkp = 0; };
        print "SUBJECT $subj BACKUP $bkp\n";

        (my $result, my $value) = &msend::send_mail($provider,$from, $subj, $body, $smtpVerbose, $bkp);
        if ($result)
        {
            Log("MESSAGE FROM $from SUBJECT $subj SENT SUCCESSIFULLY");
        }
        else
        {
            Log("MESSAGE FROM $from SUBJECT $subj FAILED TO BE SENT");
        }
    }

#   for (my $i = 12; $i < 14; $i++)
#   {
#       &msend::send_mail($provider,$to, "$subject $i", "$body $i", $smtpVerbose);
#   }
}


sub filter_hash
{
    my %to_do      = %{$_[0]};
    my $fromFilte  = $_[1];
    my %out;

    my $msg_count = 0;

    foreach my $key (sort keys %to_do)
    {
        if ($to_do{$key}{"From"} =~ /$fromFilte/)
        {
            $out{$key}{"From"} = $to_do{$key}{"From"};
            $out{$key}{"Subj"} = $to_do{$key}{"Subj"};
            $out{$key}{"Body"} = $to_do{$key}{"Body"};
            $msg_count++;
        }
    }

    if ($filterVerbose) { my $plural = $msg_count == 1 ? [ 'is', '' ] : [ 'are', 's' ]; print "\tThere $$plural[0] $msg_count" . " message$$plural[1] from $fromFilte\n"; };

    return %out;
}



sub print_hash_duo
{
    my %to_do = %{$_[0]};
    my $out = "";
    foreach my $key (sort keys %to_do)
    {
        $out .= "MESSAGE #:$key\n";
        foreach my $subk (sort keys %{$to_do{$key}})
        {
            my $value = "";
            $value    = $to_do{$key}{$subk} if ( defined $to_do{$key}{$subk} );
            $out     .= "\t$subk:\t$value\n";
        }
        $out .= "\n";
    }
    return $out;
}


sub print_hash_uno
{
    my %to_do = %{$_[0]};
    my $out = "";
    foreach my $key (sort keys %to_do)
    {
        my $value = $to_do{$key};
        $out .= "$key:\t$value\n";
    }
    return $out;
}


sub loadRequests
{
    my @files;
    find (sub { push (@files, "$File::Find::name$/") if (( $_ =~ /(.*)\.pm$/i ) && ( $File::Find::dir eq "$here/progs" )) }, "$here/progs");
    # lists all pm files under ./progs dir

    map { chomp } @files;
    Log(join("\n", @files));
#   print @files;

    my %availModules;

    foreach my $file (@files)
    {
        (my $name, my $path, my $suffix) = fileparse($file, (".pm"));
        if ($verbose >= 3) { print "NAME: $name PATH $path SUFFIX $suffix"; };

        my $lib  = "$name$suffix";
        my $pack = "$name";

#       eval { require $lib; }; if ($@) { die "FAILED TO LOAD $lib: $@\n"; }
        eval { require $lib; };
        if ($@)
        {
            Log("IMPOSSIBLE TO LOAD LIBRARY $lib: $@");
        }
        else
        {
            my $desc = "\$desc \= \$$name\:\:DESCRIPTION";
            eval $desc;
            if ($@)
            {
#               die "FAILED TO GET DESCRIPTION OF MODULE $lib: $@\n";
                Log("FAILED TO GET DESCRIPTION OF MODULE $lib: $@");
            }
            else
            {
                # http://www.grohol.com/downloads/pod/latest/servertest.txt
                # http://perldoc.perl.org/functions/eval.html
                $availModules{$name} = $desc;
            }
        }
    }

    $availModules{"list"} = "List all available modules.";

    return %availModules;
}


sub askModule
{
    my $module  = $_[0];
    my $command = $_[1];
    my $title;
    if ( $_[2] ) { $title = $_[2]; } else { $title = 0; }; 

    my $result;
    my $evalu   = "\$result \= \&$module\:\:$module(\'$command\',\'$title\')\;";

#   eval $evalu;  if ($@) { die "FAILED TO RUN MODULE $module: $@\n"; }
    eval $evalu;  if ($@) { Log("FAILED TO RUN MODULE $module: $@"); $result = ''; };

    return $result;
}

sub printHeader
{
    my $text      = $_[0];
    my $totalSize = 50;
    my $border    = "+";

    my $size      = length $text;
    my $side      = int(($totalSize - $size) / 2);

    my $newText   = $border x $side . " $text " . $border x $side . "\n";
#   print "SIZE: $size SIDE: $side NEWTEXT: $newText";

    return $newText;
}

# 1;
__END__