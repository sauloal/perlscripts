#!/usr/bin/perl
#http://www.perlmonks.org/index.pl?node_id=785470
=head1 NAME amarok-im.pl

=head1 SYNOPSIS 

    ./amarok-im.pl [-d]

    The -d command line flag triggers XMPP level debugging.

=head1 DESCRIPTION
    
    amarok-im.pl provides an chat based UI for amarok over XMPP via  google talk.

=cut

use strict;
use warnings;
use Net::XMPP;
use File::Basename;
use Cwd;

################################################################################
#
#  Globals
#
################################################################################

my $debug_level = ( ( $ARGV[0] ) and ( $ARGV[0] eq '-d' ) ) ? 1 : 0;

my %im_status;

my $Connection;

my $lastPlaying = '';

my $body = '';    # message body

my %daemon;       # Variables for notifying daemon connection and operation

my $MUSIC_ROOT = "/storage/usb00/l-space/Music";

my $playlistCD = $MUSIC_ROOT;    # playlist browser Current Directory

my @dirEntries;

my %playlistSubdirs;

##  Google Talk login credentials ##
$daemon{'username'} = '';
$daemon{'password'} = '';

#  Mostly static values
$daemon{'hostname'}       = 'talk.google.com';
$daemon{'port'}           = 5222;
$daemon{'componentname'}  = 'gmail.com';
$daemon{'connectiontype'} = 'tcpip';
$daemon{'tls'}            = 1;
$daemon{'resource'}       = 'PerlBot';
$daemon{'delay'}          = 5;

################################################################################
#
#  Usage
#
################################################################################

my $usage =
    "Valid Commands\n"
  . "\th:Help\n"
  . "INFO:\n"
  . "\tl:playList\n"
  . "\ts:Status\n"
  . "TRNSPRT:\n"
  . "\tb:Back\n"
  . "\tn:Next\n"
  . "\tp:toggle Pause\n"
  . "\tt###:Track\n"
  . "VOLUME:\n"
  . "\tu:vol Up\n"
  . "\td:vol Down\n"
  . "\tm:Mute\n"
  . "\tv###:Vol set\n"
  . "\tf:Full vol\n"
  . "PLAYLIST:\n"
  . "\ta:Add selected dir to playlist\n"
  . "\tc:Change selected dir\n"
  . "\tz:Zap playlist\n";

################################################################################
#
#  Dispatch Table:  Given a single character, execute the corresponding coderef
#  or anonymous subroutine.
#
################################################################################

my %dispatch_table = (

    "A" => \&addPlaylistItems,

    "B" => sub { player("prev"); $lastPlaying = ''; return "Previous track" },

    "C" => \&changePlaylistDir,

    "D" =>
      sub { player("volumeDown"); return "Volume: " . player("getVolume") },

    "F" =>
      sub { player("setVolume 100"); return "Volume: " . player("getVolume") },

    "H" => sub { return $usage },    #  Help message

    "L" => \&displayPlaylist,

    "M" => sub { player("mute"); return "Volume: " . player("getVolume") },

    "N" => sub { player("next"); $lastPlaying = ''; return "Next track" },

    "P" => sub { player("playPause"); return player("isPlaying") },

    "S" => \&displayStatus,

    "T" => \&setTrack,

    "U" => sub { player("volumeUp"); return "Volume: " . player("getVolume") },

    "V" => \&setVol,

    "Z" => \&clearPlaylistItems,
);

################################################################################
#
# Signal handlers
#     These ensure that the connection is closed if the program is killed
#
################################################################################

$SIG{HUP}  = \&shutdown;
$SIG{KILL} = \&shutdown;
$SIG{TERM} = \&shutdown;
$SIG{INT}  = \&shutdown;

sub shutdown {
    notifyUsers("Signal caught. Disconnecting and Shutting down.");
    $Connection->Disconnect();

    print "SIGNAL: Signal caught.  Disconnected and now Shutting down.\n";
    exit(0);

}    # sub shutdown

################################################################################
#
#
#
################################################################################
sub msgHeader {

    my $hostname = `hostname`;
    chomp $hostname;
    my $time = `uptime | cut -d' ' -f2,10-`;
    chomp $time;
    return "\n======  $hostname  ====  $time  =====\n"

};    # sub msgHeader

################################################################################
#
#
#
################################################################################
sub displaySong() {

    my $tmp_msg = player('isPlaying') . " " . player("nowPlaying");
    $tmp_msg .= " (vol:" . player("getVolume") . ")\n";

    return $tmp_msg;

};    # sub displaySong

################################################################################
#
#
#
################################################################################
sub displayPlaylist {

    my $playing = basename( player("path") );
    my @retval  = `dcop amarok playlist filenames`;

    my $tmp_string = "Playlist:\n";

    my $tmp_idx = 1;
    foreach my $tmp_name (`dcop amarok playlist filenames`) {

        $tmp_string .= "[$tmp_idx]\t";   

        # remove common suffixes
        chomp $tmp_name;
        #for my $suffix ( '.mp3', '.flac', '.shn', '.ogg' ) {
        #    $tmp_name =~ s/$suffix$//;
        #}
	$tmp_name =~ s/\.(?:mp3|flac|shn|ogg)\z//;

        # and append the filename
        $tmp_string .= 
          ( $playing =~ /$tmp_name/ ) ? "*** $tmp_name ***\n" : "$tmp_name\n";

        $tmp_idx++;
    }

    return $tmp_string;

};    # sub displayPlaylist

################################################################################
#
#
#
################################################################################
sub displayStatus() {

    my $tmp_pct = sprintf( "%02d",
        player("trackCurrentTime") / player("trackTotalTime") * 100 );
    my $tmp_eta = player("trackTotalTime") - player("trackCurrentTime");

    my $tmp_msg = displaySong;
    $tmp_msg .= " (%$tmp_pct eta:T-$tmp_eta)\n";
    $tmp_msg .= " (path:" . player("path") . ")\n";

    $tmp_msg .= "\nIM Status\n=========\n";

    foreach my $user ( sort keys %im_status ) {

        $tmp_msg .= "$user ";
        $tmp_msg .= $im_status{$user}->{'available'} ? '' : 'un';
        $tmp_msg .= 'available';

        if ( $im_status{$user}->{'show'} ) {
            $tmp_msg .= ' (' . $im_status{$user}->{'show'} . ')';
        }

        $tmp_msg .= "\n";
    }

    return $tmp_msg;

};    # sub displayStatus

################################################################################
#
#
#    Parameters: getVolume isPlaying nowPlaying path
#                playPause trackCurrentTime trackTotalTime
#
#
################################################################################
sub player {

    my $directive = shift;

    my ($retval) = `dcop amarok player $directive 2>&1`;

    if ( defined $retval ) {

        chomp $retval;

        # special output for isPlaying
        if ( $directive eq 'isPlaying' ) {
            if   ( $retval eq 'true' ) { return "Amarok is playing" }
            else                       { return "Amarok is stopped" }
        }

        # 'call failed' processing
        if ( $retval =~ /^call failed/ ) {
            return "Is Amarok running?";
        }

    }
    else { $retval = '' }

    return $retval;

};    # sub player

################################################################################
#
#
#
################################################################################
sub setVol {

    my $tmp_val = substr( $body, 1 ) or return "Bad Input";

    if ( $tmp_val =~ /^[+-]?\d+$/ ) {

        # this one goes to 11(0).
        if ( ( $tmp_val < 0 ) or ( $tmp_val > 110 ) ) {
            return "Usage: V### where 1 < ### < 110";
        }

        # change the volume, and return the resulting volume level.
        player("setVolume $tmp_val");
        return "Volume: " . player("getVolume");

    }
    else { return "Non-Integer Input" }

};    # sub setVol

################################################################################
#
#
#
################################################################################
sub changePlaylistDir {

    my $reply = "Current Dir: $playlistCD\n";

    opendir( my $DIR, $playlistCD ) || die "can't opendir $playlistCD: $!";
    my @tmpEntries = readdir($DIR);
    closedir $DIR;

    my $tmp_entry_string = '';
    my $tmp_entry_idx    = 1;

    foreach my $entry ( sort @tmpEntries ) {

        next if ( $entry eq '.' );
        $tmp_entry_string .= "[$tmp_entry_idx]\t$entry\n";

        $playlistSubdirs{$tmp_entry_idx} = $entry;

        $tmp_entry_idx++;
    }

    my $tmp_val = substr( $body, 1 ) or return ( $reply . $tmp_entry_string );

    if ( $tmp_val =~ /^[+-]?\d+$/ ) {

        my $tmp_playlistCD .= $playlistCD . "/" . $playlistSubdirs{$tmp_val};

        my $curDir = cwd;
        if ( chdir $tmp_playlistCD ) { $playlistCD = cwd };
        chdir $curDir;
        
        $reply = "cd=$playlistCD";

    }

    return $reply;

}

################################################################################
#
#
#
################################################################################
sub addPlaylistItems {

    my @retval = `dcop amarok playlist addMedia \"$playlistCD\"`;
    return "Added $playlistCD to playlist";

};    # sub addPlaylistItems

################################################################################
#
#
#
################################################################################
sub clearPlaylistItems {

    my @retval = `dcop amarok playlist clearPlaylist`;
    $playlistCD = $MUSIC_ROOT;    # reset playlist browser Current Directory
    return "Playlist cleared";

};    # sub addPlaylistItems
################################################################################
#
#
#
################################################################################
sub setTrack {

    my $tmp_val = substr( $body, 1 ) or return "Bad Input";

    # regex for integer
    if ( $tmp_val =~ /^[+-]?\d+$/ ) {

        #  These indexes are zero based, and you're gonna have to decrement
        #  the value extracted from the command line to match ( as the printed
        #  playlists are ONE based ).
        my $reindexed_val = $tmp_val - 1;

        # change the track
        my @retval = `dcop amarok playlist playByIndex $reindexed_val`;
        return "Track changed to $tmp_val";

    }
    else { return "Non-Integer Input" }

};    # sub setTrack

################################################################################
#
#
#
################################################################################
sub notifyUsers {

    my $msg = shift;

    foreach my $user ( sort keys %im_status ) {

        next if $user eq $daemon{'username'};

        if (    ( $im_status{$user}->{"available"} )
            and ( $im_status{$user}->{"show"} ne 'dnd' ) )
        {

            $Connection->MessageSend(
                to       => "$user\@" . $daemon{'componentname'},
                body     => msgHeader() . $msg,
                resource => $daemon{'resource'}
            );
            print "\t$user notified.\n";
        }
        ;    # if

    };    # foreach

};    # sub notifyUsers

################################################################################
#
#
#
################################################################################
sub messageChatCB {

    my ( $sid, $mess ) = @_;

    my $from = $mess->GetFrom();
    my ($user) = split( /\@/, $from );

    $body = uc( $mess->GetBody() );
    $body =~ s/^\s+//;    # trim leading blanks
    $body =~ s/\s+$//;    # trim trailing blanks

    my $tmp_cmd = substr $body, 0, 1;    # extract a single letter.
    my $to = $mess->GetTo();

    my $timestamp = $mess->GetTimeStamp();
    print
"MSG:$timestamp from:$from cmd:$tmp_cmd\n----body----\n$body\n------------\n";

    #fetch the code ref from the table, and invoke it
    my $sub = $dispatch_table{$tmp_cmd};
    my $reply =
        $sub
      ? $sub->()
      : "'$tmp_cmd' not recognized as a valid command.\n$usage";

    $Connection->MessageSend(
        to       => $from,
        body     => msgHeader() . $reply,
        resource => $daemon{'resource'}
    );

    print "OUT:$reply\n\n";

};    # sub messageChatCB

################################################################################
#
#
#
################################################################################
sub messageErrorCB {

    my ( $sid, $mess ) = @_;

    my $error     = $mess->GetError();
    my $errCode   = $mess->GetErrorCode();
    my $from      = $mess->GetFrom();
    my $to        = $mess->GetTo();
    my $timestamp = $mess->GetTimeStamp();

    if ( $errCode == 503 ) {
        print "503:$timestamp f:$from t:$to\n\n";
        return;
    }

    print "\nERR:$errCode:$error\n\n";
    return;

};    # sub messageErrorCB

################################################################################
#
#
#
################################################################################
sub presenceAvailableCB {

    my ( $sid, $pres ) = @_;

    my ( $user, $federation ) = split( /\@/, my $from = $pres->GetFrom() );
    my $type     = $pres->GetType();
    my $status   = $pres->GetStatus();
    my $priority = $pres->GetPriority();
    my $show     = $pres->GetShow();

    # mark available
    $im_status{$user}->{"show"}      = $show;
    $im_status{$user}->{"available"} = 1;

    # display presence data
    print "PRESENCE: Available ";

    $from     ? print "from $from "         : 0;
    $type     ? print "type $type "         : 0;
    $status   ? print "status $status "     : 0;
    $priority ? print "priority $priority " : 0;
    $show     ? print "show $show "         : 0;

    print "\n";

    return;

};    # sub presenceAvailableCB

################################################################################
#
#
#
################################################################################
sub presenceUnavailableCB {

    my ( $sid, $pres ) = @_;

    my ( $user, $federation ) = split( /\@/, my $from = $pres->GetFrom() );
    my $type     = $pres->GetType();
    my $status   = $pres->GetStatus();
    my $priority = $pres->GetPriority();
    my $show     = $pres->GetShow();

    # mark unavailable
    $im_status{$user}->{"show"}      = $show;
    $im_status{$user}->{"available"} = 0;

    # display presence data
    print "PRESENCE: Unavailable ";

    $from     ? print "from $from "         : 0;
    $type     ? print "type $type "         : 0;
    $status   ? print "status $status "     : 0;
    $priority ? print "priority $priority " : 0;
    $show     ? print "show $show "         : 0;

    print "\n";

    return;

};    # sub presenceUnavailableCB

###############################################################################
#
#
#
###############################################################################
sub ConnectClient {

    $Connection = new Net::XMPP::Client( debuglevel => $debug_level );

    $Connection->SetMessageCallBacks(
        chat  => \&messageChatCB,
        error => \&messageErrorCB
    );

    $Connection->SetPresenceCallBacks(
        available   => \&presenceAvailableCB,
        unavailable => \&presenceUnavailableCB
    );

    $Connection->RosterDB();
    $Connection->PresenceDB();

    # Connect to talk.google.com
    my $status = $Connection->Connect(
        hostname       => $daemon{'hostname'},
        port           => $daemon{'port'},
        componentname  => $daemon{'componentname'},
        connectiontype => $daemon{'connectiontype'},
        tls            => $daemon{'tls'}
    );

    if ( not defined($status) ) {
        print "FATAL: Jabber server is down or connection was not allowed.\n";
        exit(0);
    }

    # Change hostname
    my $sid = $Connection->{SESSION}->{id};
    $Connection->{STREAM}->{SIDS}->{$sid}->{hostname} =
      $daemon{'componentname'};

    # Authenticate
    my @result = $Connection->AuthSend(
        username => $daemon{'username'},
        password => $daemon{'password'},
        resource => $daemon{'resource'}
    );

    if ( ( not $result[0] ) or ( $result[0] ne "ok" ) ) {
        print "FATAL: Authorization failed.\n";
        exit(0);
    }

    $Connection->PresenceSend();
    $Connection->RosterRequest();

    print "SERVER: Connected.\n";

}    # sub ConnectClient

################################################################################################
##
##  BEGIN

while (1) {

    ConnectClient;

    while ( ( defined($Connection) )
        and ( defined( $Connection->Process( $daemon{'delay'} ) ) ) )
    {

        if ( $lastPlaying ne player("nowPlaying") ) {

            $lastPlaying = player("nowPlaying");

            print "SONGCHANGE: $lastPlaying\n";

            notifyUsers( displaySong() );

            print "\n";

        }

    };    # while defined connection....

    #  wait a bit before trying to reconnect
    sleep $daemon{'delay'};

};    # while (1)

__END__

