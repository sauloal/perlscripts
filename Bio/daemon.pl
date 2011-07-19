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
            open(FILE, $file ." |");
            close(FILE);
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