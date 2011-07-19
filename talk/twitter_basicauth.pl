#!/usr/bin/perl -w
use strict;
use HTML::Entities;
 #decode_entities($a);
 #encode_entities($a, "\200-\377");
use Encode;

my $userName    = "";
my $pass        = "";
my $writeResult = 1; #reply with result of action
my $verbose     = 1;
my $ignoreLinks = 1;
my $realSpeak   = 1;
my $repeat      = 1; # repeat already listened tweets

my %allowedUsers;
$allowedUsers{user1}       = 1;
$allowedUsers{user1nettop} = 1;

my %verbs;
$verbs{"mod.read"} = \&MODreadLoud;

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
my $timeStamp = sprintf "%04d_%02d_%02d_%02d_%02d", ($year+1900),($mon+1), $mday, $hour, $min;
my $bn = $0;
if ( index($bn, "/") != -1 ) { $bn = substr($bn, (rindex($bn, "/")+1)); };
my $curl      = `which curl | head -1`;
chomp $curl;
print "CURL :: $curl\n" if $verbose;
my $logFileR  = "/tmp/$bn.r.$timeStamp.log";
my $logFileW  = "/tmp/$bn.w.$timeStamp.log";
my $checkFile = "/tmp/$bn.r.last.log";
my $sayCount  = 0;

if ( ! @ARGV )
{
    &readTwitter();
}
elsif ( $ARGV[0] eq "LOUD" )
{
    print "GOING VERBAL\n";
    &readTwitter(1);
}
else {
    &writeTwitter(@ARGV);
}



sub sayIt
{
    my $phrase = $_[0];
    print "FESTIVAL SAYS: $phrase\n" if $verbose;
    my $cmd        = "say $phrase";
    print $cmd if $verbose;
    `$cmd` if ( $realSpeak );
}

sub MODreadLoud
{
    my $subs = $_[0];
    #print  "SCREAMING $subs!!\n";
    &sayIt("YOU ORDERED ME TO SCREAM: ".$subs);
    return "SCREAMING $subs!!\n" if $verbose;
}

sub readTweetLoud
{
    my $who  = $_[0];
    my $what = $_[1];
    my $salute = "";
    if ( $ignoreLinks )
    {
        $what =~ s/http\:\/\/\S+//gi;
        $what =~ s/RT \@(\S+)/FROM $1\./gi;
    }
    $salute = "HELLO MASTER. " if ( ! $sayCount++ );
    &sayIt("$salute$who SAID TO YOU, AND I QUOTE, $what");
}

sub runCommand
{
    my $user = $_[0];
    my $text = $_[1];

    my $cmd = substr($text, index($text, "\@$userName")+length($userName)+2);
    print "USER \@$user EXECUTING \"$cmd\"\n" if $verbose;
    if ($cmd =~ /(\S+)\s+(.+)/)
    {
        my $verb = $1;
        my $subs = $2;
        if ( exists $verbs{$verb} )
        {
            my $resp = $verbs{"mod.$verb"}->($subs);
            &writeTwitter("\@$user VERB $verb SUBS $subs RESP $resp\n") if ( $writeResult );
        }
    }
}



sub readTwitter
{
    my $loud    = $_[0] || 0;
    my $command = "$curl -f -s --basic --user \"$userName:$pass\" \"http://twitter.com/statuses/friends_timeline.xml\" 2>&1 1>$logFileR";
    print "COMMAND :: $command\n" if ( $verbose );
    
    `$command`;

    my $lastId           = 0;
    if ( -f $checkFile )
    {
        $lastId = `cat $checkFile`;
    }
    
    my $stId             = 0;
    my $id               = 0;
    my $text             = '';
    my $user_screen_name = '';
    my $already          = 0;
    my $user             = 0;
    my $notCMD           = 1;
    
    if ( ! -f $logFileR )
    {
        print "COULD NOT FIND $logFileR\n";
        return 0;
    }
    
    open LOG, "<$logFileR" or return 0;
    while (my $_ = <LOG>)
    {
        if (/\<\/*status\>/)
        {
            #print "STATUS ON/OFF\n";
            if ( $id )
            {
                if ( $id == $stId )   { print "*"; };
                if ( $id == $lastId ) { print "-"; $already = 1; };
                print "$id\t$user_screen_name\t$text\n";

                if ( exists $allowedUsers{$user_screen_name} )
                {
                    #print "ALLOWED USER SENT A MESSAGE\n";
                    if ( index($text, "\@$userName") != -1 )
                    {
                        #print "AND THE MESSAGE WAS FOR ME\n";
                        $notCMD = 0;
                        if (( ! $already ) || ( $repeat ))
                        {
                            &runCommand($user_screen_name, $text);
                        }
                    }
                }
                &readTweetLoud($user_screen_name, $text) if ( ($loud) && ( $notCMD ) && (( ! $already ) || ( $repeat ) ) && ($user_screen_name ne $userName));
            }
            $id               = 0;
            $text             = '';
            $user_screen_name = '';
            $user             = 0;
            $notCMD           = 1;
        };
        if (/\<user\>/)   { $user = 1; };
        if (/\<\/user\>/) { $user = 0; };
        if ( $user )
        {
            if (/\<screen_name\>(\S+)\<\/screen_name\>/) { $user_screen_name = $1; };
        } else {
            if (/\<id\>(\d+)\<\/id/)
            { 
                $id = $1;
                if ( ! $stId ) { $stId = $id; };
                #print "ID $id\n";
            };
            if (/\<text\>(.+)\<\/text\>/) { $text = Encode::encode_utf8(decode_entities($1)) };
        }
    }
    close LOG;
    
    `echo -n $stId > $checkFile`;
}


sub writeTwitter
{
    my $text = join(" " , @_);
    return 0 if ( ! $text );
    $text = encode_entities(Encode::decode_utf8($text));
    print "TEXT $text USER $userName PASS $pass LOGFILEW $logFileW\n" if $verbose;  
    my $cmd = "$curl -f -s --basic --user \"$userName:$pass\" --data-urlencode status=\"$text\" \"http://twitter.com/statuses/update.xml\"  2>&1 1> $logFileW";
    print "CMD: $cmd\n" if $verbose;

    #`$curl -f -s --basic --user "$userName:$pass" --data-urlencode status="$text" "http://twitter.com/statuses/update.xml"  2>&1 1> $logFileW`
    `$cmd`;


    #$text = uri_escape_RFC3986($text);
    #$text = uri_escape(encode("UTF-8",$text),"^A-Za-z0-9\-_.~");
    #$curl -f -s -u "$user:$pass" -d status="$*" http://twitter.com/statuses/update.xml 2>&1 1> /tmp/twit.${DATE}.log
    #--data-ascii 
    
    # $curl --basic --user "$user:$pass" --data-ascii "status=`echo $@ | tr ' ' '+'`" "http://twitter.com/statuses/update.json"
}




sub uri_escape_RFC3986 {
    #http://www.social.com/main/twitter-oauth-using-perl/
    my($str) = @_;
    return uri_escape(Encode::encode("UTF-8",$str),"^A-Za-z0-9\-_.~");
}


sub listVoices
{
    my $voicesLibFolder = '/usr/share/festival/lib/voices/';
    my $cmd = 'find '.$voicesLibFolder.' -depth -maxdepth 2 -type d | perl -ne \'s/'.$voicesLibFolder.'//; s/\//\t/; print\'' ;
    print `$cmd`;
}


1;