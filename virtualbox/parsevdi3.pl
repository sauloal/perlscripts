#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my @keys=();
my $dump=0;
my $partition=0;
my $list=0;
my $verbose=1;

GetOptions(
  'key=s'       => \@keys,
  'verbose+'    => \$verbose,
  'quied'       => sub{ $verbose=0; },
  'partition=i' => \$partition,
  'help'        => sub{ help(); },
  'list'        => \$list,
)or help('ERROR parse Options');

my $file=shift(@ARGV) || '';
help('ERROR no File') unless(-f $file);

print "OPEN $file\n" if($verbose > 3);
open(my $fh, '<', $file) or break("ERROR open $file ($!)");
binmode($fh);

unless(unpack('A*',read_file($fh,64)) eq '<<< Oracle VM VirtualBox Disk Image >>>')
{ break("NO VirtualBox Disk Image"); }


my $data=read_file($fh,512);
print "SPLIT VDI Header\n" if($verbose > 3);
my @tmp=qw(FileInfo Signature Version cbHeader Type fFlags Comment offBlocks offData
           cbSector cCylinders cHeads cSectors Translation cbDiskUpper cbDiskLower
           cbBlock cbBlockExtra cBlocks cBlocksAllocated);
my %VDI_header=map{(shift(@tmp),$_)}unpack('A64 I I I I I A256 I I I I I I I II I I I I',$data);

my $filesize=$VDI_header{offData}+$VDI_header{cbBlock}*$VDI_header{cBlocks};

if($partition && $VDI_header{Type} == 1 && -s $file != $filesize)
{ break("Unabele to determin partition offset in a VDI file with a dynamic filesize"); }

my @partitions=();
if($VDI_header{offData} > 0 && ($VDI_header{Type} == 2 || 
  ($VDI_header{Type} == 1 && -s $file == $filesize)))
{
  print "READ DISK MBR\n" if($verbose > 3);
  @partitions=split_br($fh,$VDI_header{offData},$VDI_header{cSectors});
}

print "CLOSE $file\n" if($verbose > 3);
close($fh) or break("ERROR close $file($!)");

if(@keys)
{ print join("\n", map{$VDI_header{$_}}@keys); }

if($partition && defined($partitions[$partition-1]) && 
   ref($partitions[$partition-1]) eq 'HASH' && 
   $partitions[$partition-1]->{type} ne '00')
{ print $partitions[$partition-1]->{first}; }

if($list || (!@keys && !$partition && !$list && $verbose>0 ))
{
  print "VDI KEYS\n";
  print "   $_ = $VDI_header{$_}\n" for(sort keys(%VDI_header));
  print "\n";
  for my $p (0..$#partitions)
  {
    my $l=$partitions[$p];
    if(defined($l) && ref($l) eq 'HASH' && $l->{type} ne '00')
    {
      print "Partition ".($p+1)."\n";
      print "   $_ => $l->{$_}\n" for(sort keys(%$l) );
      print "\n";
    }
  }
}

########################################################################
########################################################################

sub help
{
  my $msg=shift;
  my $oh=\*STDOUT;
  if(defined($msg))
  {
    $oh=\*STDERR;
    print $oh "$msg\n" if($verbose > 0);
  }

  print $oh <<EOH if($verbose > 0 );
$0 [-hvql] [-p <Nr>] [-k <name>] VDI-file

  -h --help           this message
  -v --verbose        verbose output
  -q --quiet          no messages or warnings
                      (only the requested values are printed)
  -l --list           print list all aviable partitions and keys
  -p --partition <Nr> print the startposition of the partition in this file 
                      (will be return nothing if the partition not exists)
  -k --key <name>     print a VDI Header key
EOH
  exit(defined($msg)?1:0);
}

sub break
{
  my $msg=shift;
  print STDERR "$msg\n" if($verbose > 0);
  exit(1);
}

sub split_br
{
  my $fh=shift;
  my $offset=shift;
  my $ssize=shift || 512;
  my $cnt=shift || -1;
  my $partlist=shift || [];
  my %header=read_br($fh,$offset);
  if(unpack("H*",$header{signature}) eq '55aa')
  {
    print "BR Found\n" if($verbose > 2);
    for(1..4)
    {
      $cnt++;
      print "READ partition".($cnt+1)."\n" if($verbose > 1);
      my @list=unpack('a1 x3 a1 x3 I I',$header{"partition$_"});
      my %data=(boot=>0,first=>0,size=>0,type=>0);
      $data{boot}=1 if($list[0] eq "\x80");
      $data{type}=unpack('H*',$list[1]);
      $data{first}=$data{type} ne '00'?$list[2]*$ssize+$offset:0;
      $data{size}=$list[3]*$ssize;
      if($verbose > 2)
      { print "   $_ => $data{$_}\n" for(sort(keys(%data))); }
      $partlist->[$cnt]=\%data;
      split_br($fh,$data{first},$ssize,$cnt+(4-$_),$partlist) if($data{type} eq '05');
    }
  }
  return @$partlist;
}

sub read_br
{
  my $fh=shift;
  my $offset=shift || 0;
  print "Read Boot Record BLOCK\n" if($verbose > 1);
  my $data=read_file($fh,512,$offset);
  my @names=qw(bootloader disk-signature partition1 partition2 partition3 partition4 signature);
  my @tmp=@names;
  my %header=map{(shift(@tmp),$_)}unpack('a440 a4 x2 a16 a16 a16 a16 a2',$data);
  if($verbose > 2)
  { print "  $_ => ".unpack('H*',$header{$_})."\n" for(@names); }
  return %header;
}

sub read_file
{
  my $fh=shift;
  my $bytes=shift || 0;
  my $offset=shift || 0;
  print "READ FILE POS=$offset SIZE=$bytes\n" if($verbose > 1);
  my $data='';
  seek($fh,$offset,0);
  read($fh,$data,$bytes) or break("ERROR read file ($!)");
  return $data;
}
