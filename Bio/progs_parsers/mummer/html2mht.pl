#!/usr/bin/perl -w
use strict;
use warnings;

# my $dir = "html/PNG";
# my $dir = "html/snp";
my $dir = "html/tiling";
my $ext = ".html";


my @files = &list_dir($dir,$ext);
my $header;
my $foot;
my $html_text;
my $head_text;

&load_vars;

foreach my $file (sort @files)
{
	my $newname = $file;
	$newname =~ s/\.html/\.mht/;

	open  IN,  "<$dir/$file"    || die "COULD NOT OPEN $file FILE";
	open  OUT, ">$dir/$newname" || die "COULD NOT CREATE $newname FILE";
	print OUT  $header;
	my $count  = 0;
	my $body   = 0;
	my $attach = "";
	my $html   = 0;
	my $head   = 0;

	while (<IN>)
	{

		if (/^<html>/)
		{
			print OUT $html_text;
			$html = 1;
		}
		elsif (/^<head>/)
		{
			print OUT $head_text;
			$head = 1;
		}
		elsif ((/"\/>/) && ($body))
		{
			$body = 0;
		}
		elsif ($body)
		{
			$attach .= $_;
		}
		elsif (/<img width="(\d+)" height="(\d+)" src="data:image\/png;base64,(\S+)/)
		{
			if ( ! ( $html && $head ))
			{
				print OUT "$html_text$head_text";
				print OUT "</head>\n<body>\n";
			}
			my $width  = $1."px";
			my $height = $2."px";
			my $line   = $3;
			$count++;

			$attach .= &img_header("IMAGE$count") . "$line\n";

			print OUT "<v:shape style=  \"width:$width;height:$height;\" ><v:imagedata src=  IMAGE$count /></v:shape>\n";
# 			<img width="1024" height="2717" src="data:image/png;base64,
			$body = 1;
		}
		elsif (/^<base href/)
		{
			
		}
		else
		{
			print OUT;
		}
	} #end while in
	print OUT $foot if ( ! ($html && $head));
	print OUT $attach;
	print OUT "\n\n------=_NextPart";
	close OUT;
	close IN;
} # end for my file

sub img_header
{
	my $name = $_[0];
	my $img_header = <<__EOF__


------=_NextPart
Content-Location: file:///X:/$name
Content-Transfer-Encoding: base64
Content-Type: image/png;

__EOF__
;

	return $img_header;
}



sub load_vars
{
$header =<<__EOF__
MIME-Version: 1.0
Content-Type: multipart/related; boundary="----=_NextPart"

------=_NextPart
Content-Location: file:///X:/ 
Content-Transfer-Encoding: quoted-printable 
Content-Type: text/html; charset="us-ascii" 

__EOF__
;


$foot = <<__EOF__
</body>
</html>
__EOF__
;


$html_text = <<__EOF__
<!doctype html public '-//w3c//dtd html 4.01//en' 'http://www.w3.org/tr/html4/strict.dtd'>
<html xmlns:v="urn:schemas-microsoft-com:vml">
__EOF__
;


$head_text = <<__EOF__
<head> 

<style>
v\\:* {behavior:url(#default#VML);display:inline-block;};font:13px/1.3 Verdana;}
</style>


__EOF__
}

sub list_dir
{
	my $dir = $_[0];
	my $ext = $_[1];
# 	print "openning dir $dir and searching for extension $ext\n";

	opendir (DIR, "$dir") || die "CANT READ DIRECTORY $dir: $!\n";
	my @ext = grep { (!/^\./) && -f "$dir/$_" && (/$ext$/)} readdir(DIR);
	closedir DIR;

	return @ext;
}

1;