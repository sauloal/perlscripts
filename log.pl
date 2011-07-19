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
}