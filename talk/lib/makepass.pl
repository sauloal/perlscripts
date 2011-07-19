#!/usr/bin/perl -w
use strict;
use warnings;
use Cwd 'abs_path';
use File::stat; 
use MIME::Base64;
use Digest::SHA qw(sha512_base64);

my $inFile = $ARGV[0];
$inFile    = abs_path($inFile);
my %hash;

if ( ! -f $inFile )
{
	die "INPUT FILE $inFile DOES NOT EXISTS\n";
} else {
	my $sum = 0;

	open FILE, "<$inFile" or die $!;
	while (my $line = <FILE>)
	{
		chomp $line;
		if ( $line =~ /^(.+?)\s*=\s*(.+)/ )
		{
			my $k     = $1;
			my $v     = $2;
			$hash{$k} = $v;
			$sum     += length($k) + 3 + length($v) + 1;
		}
	}
	close FILE;

	open FILE, ">$inFile" or die "$!";
	foreach my $k ( sort keys %hash )
	{
		my $v       = $hash{$k};
		my $hKey    = sha512_base64("$k$v");
                my $vv      = xor_encode($hash{$k}, $hKey);
		my $vvv     = encode_base64($vv);
		chomp $vvv;
		print FILE "$k = $vvv\n";
		print "$k = $vvv\n";
	}
	close FILE;

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
	
	open FILE, ">$inFile" or die "$!";
        foreach my $k ( sort keys %hash )
        {
                my $v       = $hash{$k};
                my $hKey    = sha512_base64("$key$k");
                my $vv      = xor_encode($hash{$k}, $hKey);
                my $vvv     = encode_base64($vv);
		chomp $vvv;
                print FILE "$k = $vvv\n";
                #print "$k = $v\n";
	        #print "\tK '$k' V '$v' ENC '$encoded' DEC '$decoded'\n";
        }
        close FILE;
}


sub xor_encode {
    my ($str, $key) = @_;
    my $enc_str = '';
    for my $char (split //, $str){
        my $decode = chop $key;
        $enc_str .= chr(ord($char) ^ ord($decode));
        $key = $decode . $key;
    }

   return $enc_str;
}

1;

