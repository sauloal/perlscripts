#!/usr/bin/perl -w
use warnings;
use strict;

use Net::SMTP::SSL;
#perl -MCPAN -e shell
#install Net::SMTP::SSL
#install Authen::SASL
# http://robertmaldon.blogspot.com/2006/10/sending-email-through-google-smtp-from.html

use lib "./";
use loadconf;
my %pref = &loadconf::loadConf;

package msend;



sub send_mail
{
    my $server   = $_[0];
    my $to       = $_[1];
    my $subject  = $_[2];
    my $body     = $_[3];
    my $bkp      = $_[4];

    my $smtpVerbose;
    if (defined $_[4]) { $smtpVerbose = $_[4]; } else { $smtpVerbose = 0; };

    my $smtp_host;
    my $smtp_user;
    my $smtp_pass;
    my $smtp_port;

    if (! $server )
    {
        die "NOR SMTP " . $pref{"pop_1"} . " OR " . $pref{"pop_2"} . " CONFIGURATED\n";
    }   
    elsif ($server eq "1")
    {
        if ( $smtpVerbose >= 1) { print "SMTP " . $pref{"pop_1"} . " SELECTED\n"; };
        $smtp_host = $pref{"smtp_host_1"};
        $smtp_user = $pref{"pop_user_1"};
        $smtp_pass = $pref{"pop_pass_1"};
        $smtp_port = $pref{"smtp_port_1"};
    }
    elsif ($server eq "2")
    {
        if ( $smtpVerbose >= 1) { print "SMTP " . $pref{"pop_2"} . " SELECTED\n"; };
        $smtp_host = $pref{"smtp_host_2"};
        $smtp_user = $pref{"pop_user_2"};
        $smtp_pass = $pref{"pop_pass_2"};
        $smtp_port = $pref{"smtp_port_2"};
    }
    else
    {
        die "NOR SMTP " . $pref{"pop_1"} . " OR " . $pref{"pop_2"} . " CONFIGURATED\n";
    }



    my $smtp;

    if (not $smtp = Net::SMTP::SSL->new($smtp_host, Port => $smtp_port))
    {
        die "Could not connect to server\n";
    }

#   if ( $smtpVerbose ) { $smtp->Debug(1); };
#   $smtp->( Debug => 1 );

    $smtp->auth($smtp_user, $smtp_pass) || die "Authentication failed!\n";
    
    $smtp->mail($smtp_user . "\n");   #user
    my @recepients = split(/,/, $to); #recipients
    push (@recepients, $smtp_user) if ($bkp);   #send copy to itself
    foreach my $recp (@recepients)
    {
        $smtp->to($recp . "\n");
    }

    # Create arbitrary boundary text used to seperate
    # different parts of the message
    my ($bi, $bn, @bchrs);
    my $boundry = "";
    foreach $bn (48..57,65..90,97..122)
    {
        $bchrs[$bi++] = chr($bn);
    }
    foreach $bn (0..20)
    {
        $boundry .= $bchrs[rand($bi)];
    }


    $smtp->data();
    $smtp->datasend("From: "    . $smtp_user . "\n");
    $smtp->datasend("To: "      . $to        . "\n");
    $smtp->datasend("Subject: " . $subject   . "\n");
    $smtp->datasend("MIME-Version: 1.0\n");
#   $smtp->datasend("Content-Type: multipart/alternative;\n");
    $smtp->datasend("Content-Type: multipart/mixed;\n");
#   $smtp->datasend("Content-Type: text/plain;\n");
    $smtp->datasend("        boundary=\"$boundry\"\n\n");
    $smtp->datasend("\n--$boundry\n");
    $smtp->datasend("Content-Type: text/plain; charset=ISO-8859-1\n");
#   $smtp->datasend("Content-Transfer-Encoding: 7bit\n");
    $smtp->datasend("Content-Transfer-Encoding: quoted-printable\n");
    $smtp->datasend("Content-Disposition: inline\n");
    $smtp->datasend($body . "\n");
    $smtp->datasend("\n--$boundry"); # send boundary end message
    $smtp->datasend("\n");
    $smtp->dataend();
    $smtp->quit;

    if ( $smtpVerbose >=1 ) { $body = substr($body, 0, 30); print "DONE>> TO: $to SUBJ: $subject BODY: $body\n" };
}

1;

# Send away!
# &send_mail('johnny@mywork.com', 'Server just blew up', 'Some more detail');

# use Net::SMTP;
# 
# my $smtp = Net::SMTP->new("smtp.google.com",
#                       Timeout => 15,
#                       Debug => 1)|| print "ERROR creating SMTP obj: $! \n";
# 
# print "SMTP obj created.";
# print $smtp->domain,"\n";
# 
# # my $banner = $smtp->banner;
# # print $banner;
# 
# #                     Hello => 'smtp.google.com',
# 
# $smtp->mail('cbsknaw@gmail.com');
# $smtp->to("cbsknaw\@gmail.com");
# $smtp->data();
# $smtp->recipient("cbsknaw\@gmail.com", \ "user\@example2.com");
# # $smtp->to("user1@domain.com");
# # $smtp->cc("foo@example.com");
# # $smtp->bcc("bar@blah.net");
# 
# $smtp->datasend("From: cbsknaw\@gmail.com");
# $smtp->datasend("To: cbsknaw\@gmail.com");
# $smtp->datasend("Subject: This is a test");
# 
# $smtp->datasend("Disposition-Notification-To: cbsknaw\@gmail.com");
# 
# $smtp->datasend("Priority: Urgent\n");
# $smtp->datasend("Importance: high\n");
# 
# $smtp->datasend("\n");
# 
# 
# 
# $smtp->datasend("blahblah");
# 
# $smtp->dataend;
# $smtp->quit;
# 
# 
