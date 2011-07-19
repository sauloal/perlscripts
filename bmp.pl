#!/usr/bin/perl -w
use strict;
use warnings;
use GD;
#my $w = 5462;
#my $h = 3072;

#&printPallet();
#&checkPallet();




sub checkPallet
{
	##open my $fh, "<", "bmp.png";
	##my $BitMap = newFromPng GD::Image($fh);
	
	#open my $fh, "<", "bmp.gd";
	#my $BitMap = GD::Image->newFromGd($fh) || die;
	##These methods initialize a GD::Image from a Gd file, filehandle, or data. Gd is Tom Boutell's disk-based storage format, intended for the rare case when you need to read and write the image to disk quickly. It's not intended for regular use, because, unlike PNG or JPEG , no image compression is performed and these files can become BIG .
	
	#my $BitMap = GD::Image->newFromGd2Part($file,srcX,srcY,width,height) || die;
	##This class method allows you to read in just a portion of a GD2 image file. In addition to a filehandle, it accepts the top-left corner and dimensions (width,height) of the region of the image to read. For example:
	##my $BitMap = GD::Image->newFromGd2Part(\*GDF,10,20,100,100) || die;
	#my $BitMap = GD::Image->newFromGd2Part($fh,10,20,100,100) || die;
	
	#open my $fh, "<", "bmp.jpg";
	#my $BitMap = GD::Image->newFromJpeg($fh) || die;

	open my $fh, "<", "bmp.gd2";
	my $BitMap = GD::Image->newFromGd2($fh) || die;
	##This works in exactly the same way as "newFromGd()" and newFromGdData, but use the new compressed GD2 image format.
	
	my $W       = $BitMap->width;
	my $H       = $BitMap->height;
	my $maxSize = $W * $H;
	print "MAX SIZE = $maxSize :: H = $H W = $W\n";
	#Return the width and height of the image, respectively.
	my $is_truecolor = $BitMap->isTrueColor();
	
	#my $size = 256 * 256 * 256;
	#my ( $W, $H ) = &getSides($size);
	
	my $x = 0;
	my $y = 0;

	for my $r (0..254)
	{
		for my $g (0..254)
		{
			for my $b (0..254)
			{
				#$index = $image->getPixel(x,y);
				#This returns the color table index underneath the specified point. It can be combined with rgb() to obtain the rgb color underneath the pixel.
				#($r,$g,$b) = $myImage->rgb($index)
				
				my $index = $BitMap->getPixel($x,$y);
				my ($R,$G,$B) = $BitMap->rgb($index);
				die "pos ($x,$y) r $r not equal R $R" if ( $r != $R );
				die "pos ($x,$y) g $g not equal G $G" if ( $g != $G );
				die "pos ($x,$y) b $b not equal B $B" if ( $b != $B );
				
				$x++;
				if ( $x == ( $W -1 ) )
				{
					$x = 0;
					#printf "CHECKING (%04d,%04d) AS (%03d,%03d,%03d)\n", $x, $y, $r, $g, $b;
					$y++;
				}
			}
		}
	}	
	
	close $fh;
}

sub printPallet
{
	my $pallet = &genPallet();
	
	## write png-format to file
	#open my $fhp,">","bmp.png" or die "$!";
	#binmode $fhp;
	#print $fhp $pallet->png(0);
	#close($fhp);
	#
	#open my $fhj,">","bmp.jpg" or die "$!";
	#binmode $fhj;
	#print $fhj $pallet->jpeg(100);
	#close($fhj);
	
	open my $fhg,">","bmp.gd" or die "$!";
	binmode $fhg;
	print $fhg $pallet->gd;
	close($fhg);
	
	open my $fhg2,">","bmp.gd2" or die "$!";
	binmode $fhg2;
	print $fhg2 $pallet->gd2;
	close($fhg2);
}


sub genPallet
{
	my $size = 256 * 256 * 256;
	my ( $W, $H ) = &getSidesP($size);

	my $x = 0;
	my $y = 0;
	my $BitMap = GD::Image->newTrueColor($W, $H);

	for my $r (0..254)
	{
		for my $g (0..254)
		{
			for my $b (0..254)
			{
				my $color = $BitMap->colorExact($r,$g,$b);
			      	$BitMap->setPixel($x,$y,$color); 
				$x++;
				if ( $x == ( $W -1 ) )
				{
					$x = 0;
					#printf "SETTING (%04d,%04d) AS (%03d,%03d,%03d)\n", $x, $y, $r, $g, $b;
					$y++;
				}
			}
		}
	}
	
	return $BitMap;
}





sub getSidesP
{
	my $size = $_[0];
	my $ph   = defined $_[1] ? $_[1] : 1;
	my $pw   = defined $_[2] ? $_[2] : 1;
	#16X . 9X = $size
	#144X^2 = $size
	#X^2 = $size / 144
	#X = sqr($size / 144);
	#H = 9X
	#W = 16x
	#maxSize = H x W
	my $X = sqrt($size/($ph*$pw));
	   $X = int($X) + 1 if ( $X > int($X) );
	my $H = int($X * $ph);
	my $W = int($X * $pw);
	
	my $maxSize = $H * $W;
	print "SIZE $size :: X = $X : h = $ph H = $H : w = $pw W = $W : MAX SIZE = $maxSize\n";
	return ($W, $H);
}

1;
