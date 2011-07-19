#!/usr/bin/perl -w
package readpass;
#reset; perl -I ./ -Mreadpass -e '$m = new readpass(verbose => 1); print "Hey \"". $m->getValue("gtalk_username") . "\" ERR \"" . $m->getErr() . "\"\n"'
use strict;
use warnings;
use Cwd 'abs_path';
use File::stat; 
use MIME::Base64;
use Digest::SHA qw(sha512_base64);

sub new {
	my($class, %args) = @_;
	my $self = bless({}, $class);
 	my %hash;

	my $inFile  = exists $args{inFile}  ? $args{inFile}  : $ENV{HOME} . '/.passwd';
	my $verbose = exists $args{verbose} ? $args{verbose} : 0;
	my $err     = "";

    	$inFile     = abs_path($inFile);

	if ( ! -f $inFile )
	{
		$err .= "INPUT FILE $inFile DOES NOT EXISTS\n";
	} else {
	        my $st    = stat("$inFile") or die "Couldn't stat $inFile: $!";
        	my $mtime = $st->mtime; # modification time in seconds since epoch 
	        my $ctime = $st->ctime; # creation time
        	my $size  = $st->size;
	        my $uid   = $st->uid;
        	my $gid   = $st->gid;
	        my $ino   = $st->ino;
        	my $home  = $ENV{HOME};
	        my $usr   = $ENV{USER};
	        my $log   = $ENV{LOGNAME};
        	my $rid   = $<; 
	        my $reid  = $>; 
        	my $rgid  = $(; 
	        my $regid = $);
		my $key   = "$inFile$mtime$ctime$size$uid$gid$ino$home$usr$log$rid$reid$rgid$regid";

		if ( open FILE, "<$inFile" )
		{
			while (my $line = <FILE>)
			{
				chomp $line;
				if ( $line =~ /^(.+?) = (.+)/ )
				{
					my $k       = $1;
					my $v       = $2;
        			        my $hKey    = sha512_base64("$key$k");
					my $vv      = decode_base64($v);
					my $vvv     = xor_encode($vv,      $hKey);
					$hash{$k}   = $vvv;
			                #my ($deLen, $decoded) = xor_encode($encoded,$key);
					#print "K '$k' V '$v'\n" if $verbose;
			                print "\tK '$k' V '$v' VV '$vv' VVV '$vvv'\n" if $verbose;
				}
			}
		} else {
			$err .= $!;
		}
	}

	$self->{err}  = \$err;
	$self->{hash} = \%hash;
	return $self;
}

sub getErr
{
	my $self = shift;
	my $err  = $self->{err};
	return $$err;
}

sub getValue
{
	my $self = shift;
	my $qry  = shift;
	my $err  = $self->{err};
	my $hash = $self->{hash};

	if ( ! defined $qry )
	{
		$$err .= "NO QUERY DEFINED\n";
		return undef;
	}

	my $res  = ${$hash}{$qry};

	if ( defined $res )
	{
		return $res;
	} else {
		$$err .= "QUERY $qry RETURNED NO RESULT\n";
		return undef;
	}
}

sub xor_encode {
    my ($str, $key) = @_;
    my $enc_str = '';
    for my $char (split //, $str){
        my $decode = chop $key;
        $enc_str .= chr(ord($char) ^ ord($decode));
        $key = $decode . $key;
    }

   my $len = length($enc_str);
   return ($len, $enc_str);
}

1;

