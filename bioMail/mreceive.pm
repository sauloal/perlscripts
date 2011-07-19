#!/usr/bin/perl
use warnings;
use strict;

use Mail::POP3Client;
use IO::Socket::SSL;
#perl -MCPAN -e shell
#install Mail::POP3Client
# #install Email::Filter

# http://conky.sourceforge.net/gmail.pl
# http://www.oreillynet.com/onlamp/blog/2004/11/my_own_gmail_notifier.html

use lib "./";
use loadconf;
my %pref = &loadconf::loadConf;

package mreceive;


sub receive_mail
{
    my $provider    = $_[0];

    my $deleteMail;
    my $popVerbose;

    if (defined $_[1]) { $deleteMail = $_[1] } else { $deleteMail = 1 };
    if (defined $_[2]) { $popVerbose = $_[2] } else { $popVerbose = 0 };

    my $pop = Mail::POP3Client->new();
    my $dis_numb = $pref{"dis_numb"};
    my $ssl_prot = $pref{"ssl_pop_prot"}; # ssl protocol 
    my $ssl_port = $pref{"ssl_pop_port"}; # ssl port number (995 is what Gmail uses) 
    
    my $pop_host;
    my $pop_user;
    my $pop_pass;

    my %out;

    if (! $provider )
    {
        die "NOR POP" . $pref{"pop_1"} . " OR " . $pref{"pop_2"} . " CONFIGURATED\n";
    }   
    elsif ($provider eq "1")
    {
        if ( $popVerbose >= 1) { print "POP  " . $pref{"pop_1"} . " SELECTED\n"; };
        $pop_host = $pref{"pop_host_1"};
        $pop_user = $pref{"pop_user_1"};
        $pop_pass = $pref{"pop_pass_1"};
    }
    elsif ($provider eq "2")
    {
        if ( $popVerbose >= 1) { print "POP  " . $pref{"pop_2"} . " SELECTED\n"; };
        $pop_host = $pref{"pop_host_2"};
        $pop_user = $pref{"pop_user_2"};
        $pop_pass = $pref{"pop_pass_2"};
    }
    else
    {
        die "NOR POP" . $pref{"pop_1"} . " OR " . $pref{"pop_2"} . " CONFIGURATED\n";
    }
    

    my $socket = IO::Socket::SSL->new( PeerAddr => $pop_host,
                       PeerPort => $ssl_port,
                       Proto    => $ssl_prot);
    
    
    $pop->User($pop_user);
    $pop->Pass($pop_pass);
    $pop->Socket($socket);
    if ( $popVerbose >= 4) { $pop->Debug(1); };
    
    $pop->Connect() >= 0 || die $pop->Message();
    
    my $msg_count = $pop->Count();

    if ( $popVerbose >= 1)  
    {
        my $plural = $msg_count == 1 ? [ 'is', '' ] : [ 'are', 's' ];
        print "$pop_user: There $$plural[0] $msg_count" . " message$$plural[1]\n";
    }
    
    if ($dis_numb == -1) { $dis_numb = $msg_count; };

    my $list_total = $msg_count-($dis_numb-1);

    if ($msg_count > 0)
    {
        for (my $i = $msg_count, my $j = 0; $i >= $list_total; $i--, $j++)
        {
            my $bodyY = 0;
            my $text  = 0;
            my $boundary;


            my $from;
            my $subj;
            my $body;
            my $out = "";
            my $all = "";

            foreach my $line ( $pop->HeadAndBody( $i ) )
        #   foreach my $line ( $pop->Body( $i ) )
        #   foreach my $line ( $pop->Retrieve( $j ) )
            {
        #       /^(From|Subject):\s+/i and print $_, "\n"; 
        #       $pop->Head( $i );
        #       $pop->Body( $i );
        #       $pop->HeadAndBody( $i );
                $all .= "$line\n";
        
                if ($line =~ m/^From:/) 
                {
                    if ($line =~ m/^From:\s+(\S+\@\S+)/) 
                    {
                        $from = $1;
                        $out .= "$j = FROM: $from\n"; 
                    }
                    elsif ($line =~ m/^From:\s+.*<(.*)>/) 
                    {
                        $from = $1;
                        $out .= "$j = FROM: $from\n"; 
                    }
                    else
                    {
                        die "WRONG FORMATED FROM\n";
                    }
                }
        
                if ($line =~ m/^Subject:/) 
                {
                    ($subj) = ($line =~ m#^Subject: (.*)#); 
                    $out .= "\tSUBJ: $line\n";  
    #               $subj = substr($subj, 0, 30); 
                }
        
                if ($line =~ m/^\s+boundary=\"(\S+)\"/)
                {
                    $boundary = $1;
                }
    
                if (($boundary) && (($line =~ m/$boundary/) || ($line =~ m/X\-Apparently\-To\:/)))
                {
                    $bodyY = 0;
                }
    
                if ($bodyY && $text)
                {
                    $body.= "$line\n";
                    $out .= "\t$line\n"; 
        #           $body = substr($body, 0, 30); 
                }
    
                if ($line =~ m/^Content-Disposition: inline/)
                {
                    $bodyY = 1;
                }
                if ($line =~ m/^Content-Transfer-Encoding: quoted-printable/)
                {
                    $bodyY = 1;
                }
    
                if ($line =~ m/^Content-Type: (.*)\/(.*)\;/)
                {
                    if (($1 eq "text") && ($2 eq "plain")) { $text = 1; } else { $text = 0; };
                }
            } # end foreach my line

            if ((defined $from) && ($from ne $pop_user))
            {
                if ( $popVerbose >= 3 ) { print $all . "\n";  };
                if ( $popVerbose >= 2 ) { print $out."\n";  };

                $out{$j}{"From"}  = $from;
                $out{$j}{"Subj"}  = $subj;
                $out{$j}{"Body"}  = $body;
                if ( $deleteMail ) { $pop->Delete($i); };
            }
        }
    }
#   print $out;
    
    # print $pop->HeadAndBody(1);
    # print $pop->Body(1);
    # print $pop->Retrieve(4);
    
    # sleep 2;
    
    $pop->Close();
    return %out;
}

1;

    # print $pop->Retrieve(0);
#   print $pop->Message();
    # print $msg_count, "\n";
    # my $msg_list = $pop->List(); # size of the message
    # print $msg_list;
    # my $msg_capa = $pop->Capa(); # capabilities
    # print $msg_capa;
    # my $msg_array = $pop->ListArray(); #size of all messages
    # print $msg_array;
    
    # print $pop->Alive(), "\n";
    # print $pop->State(), "\n";
    # print $pop->POPStat(), "\n";
    # print "LAST: ", $pop->Last(), "\n"; # returns the number of the last message retrieved from the server

    #               (my $from) = ($line =~ m#^From: .*<(.*)>#); 
    #               $from = substr($from, 0, 30);