#!/usr/bin/perl -w 
use warnings; 
use strict; 
############################################ 
####                SETUP               #### 
############################################ 
use FindBin; 
use lib "$FindBin::Bin/lib";

use loadconf; 
my %pref = &loadconf::loadConf;

my $wwwfolder   = $pref{"htmlPath"}; # http folder
my $width       = $pref{"width"};;  # graphic width in pixels
my $multithread = $pref{"multithreadGraphic"};     # enable multithread
my $renice  = $pref{"reniceGraphic"};     # renice process (increase priority - needs SUDO)
my $minscore    = $pref{"minscore"};


############################################
####        STATEMENTS      ####
############################################
use Storable;
use Bio::Graphics;
use Bio::SeqFeature::Generic;
use Bio::SearchIO;
use Data::Dumper;
use GD::Graph::bars;
use GD::Image;
use File::Basename;
use File::Copy;

use Cwd qw(realpath);

use threading;
use loadFasta;
use distribution;

my $fullname    = realpath($0);
my $fullpath    = dirname($fullname);   # fullpath
my $script_name = basename($0);
my $time        = localtime time;   # printable time
my $start       = time;         # calculable time
my @filenames;
my @input;
my @pid;
my %fasta;
my %final;
if ($renice) { `sudo renice -10 $$`; };

############################################
####        LOADING         ####
############################################
if ( ! $ARGV[0])
{
    die "USAGE: graphic.pl link.dump\n";
}

my $input     = $ARGV[0];
loadretrieve(\@input);      # load input arguments
%fasta = &loadFasta::loadFasta;
# savedump(\%fasta,"fasta");
my %database  = %{$input[0]};   # database
my $select    = $input[1];  # filter selection
my $titleFile = $input[2];  # filename (title without spaces)
my $titleHtml = $input[3];  # title

############################################
####        PROGRAM         ####
############################################
if ($select eq "codefilter")
{
    %final = &distribution::printFinal(\%database,1);
#   &savedump(\%final,"final");
};
&graphicSplit(&generateGraphicDB(\%database, $select, $titleFile)); # forward database to specific graphic interface
# savestore(\@filenames);
&threading::checkprocess(\@pid,$multithread); # check how many processes are still in execution

my $elapsed = time - $start; # calculate elapsed time
print "\tELAPSED $elapsed SECONDS\n";

############################################
####        ROUTINES        ####
############################################
sub generateGraphicDB
{
    my %a_database = %{$_[0]}; #savedump(\%a_database,"a_database"); # database
    my $selection  = $_[1];     # filter
    my $titleFile  = $_[2];     # filename
    print "\tGENERATING GRAPHIC " . uc($selection) . "." x (11 - length($selection)) . "\n";
    my $count      = 0;
    my %byselection;
    my %byselectionnew;
    my %byselectionnewest;
    my @line;
#   savedump(\%a_database,"a_database");

    foreach my $seq (sort keys %a_database) #foreach key in database
    {
        foreach my $count (sort keys %{$a_database{$seq}}) #foreach count (number index)
        {
            if (exists $a_database{$seq}{$count}{"pos"}) #if position
            {
                my $pos    = $a_database{$seq}{$count}{"pos"};
                if ($pos < 0) {$pos = (500 - $pos)}; # case position is negative, convert to positive
                if ($pos < 500) # case position less than 500
                {
                    my $code   = $a_database{$seq}{$count}{"code"}; #gene code
                    my $method = $a_database{$seq}{$count}{"method"}; #method used
                    my $prob;
                    my $strand;
                    my $other;
                    $prob   = $a_database{$seq}{$count}{"prob"}   if (defined $a_database{$seq}{$count}{"prob"}); #probability
                    $strand = $a_database{$seq}{$count}{"strand"} if (defined $a_database{$seq}{$count}{"strand"}); #strand
                    $other  = $a_database{$seq}{$count}{"other"}  if (defined $a_database{$seq}{$count}{"other"}); #other informations

                    my $first;
                    my $second;
                    my $third;
                    my $fourth;

                    if ($selection eq "method")      { $first = $method  ; $second = $pos;    $third = $seq ; }; #map fields names
                    if ($selection eq "code")        { $first = $code    ; $second = $pos;    $third = $seq ; };
                    if ($selection eq "sequence")    { $first = $seq     ; $second = $pos;    $third = $code; };
                    if ($selection eq "position")    { $first = $pos     ; $second = $seq;    $third++      ; };
                    if ($selection eq "methodshort") { $first = $method  ; $second = $seq;    $third++      ; };

                    if ($selection eq "methodnew")   { $first = $method  ; $second = $code;   $third = $seq ; $fourth = $pos ; };
                    if ($selection eq "codenew")     { $first = $code    ; $second = $method; $third = $seq ; $fourth = $pos ; };

                    my $start = $pos; # start position
                    my $end   = $pos + 8; # avereage end of pattern

                    for (my $i = $start; $i <= $end; $i++)
                    {
                        $line[$i]++; #append appearence count in all positions in which it appears
                    }

                    $byselection{$first}{$second}            = $third if (($selection ne "codenewest") && ($selection ne "methodnewest") && ($selection ne "codefilter") && ($selection ne "methodfilter")); #map values in desired positions
                    $byselectionnew{$first}{$second}{$third} = $fourth if (($selection ne "codenewest") && ($selection ne "methodnewest") && ($selection ne "codefilter") && ($selection ne "methodfilter"));

                    if (($selection eq "codenewest") || ($selection eq "codefilter"))
                    {
                        $byselectionnewest{$code}{$method}{$seq}{'pos'}    = $pos;
                        $byselectionnewest{$code}{$method}{$seq}{'prob'}   = $prob   if ($prob);
                        $byselectionnewest{$code}{$method}{$seq}{'strand'} = $strand if ($strand);
                        $byselectionnewest{$code}{$method}{$seq}{'other'}  = $other  if ($other);
                    };
                    if (($selection eq "methodnewest") || ($selection eq "methodfilter"))
                    {
                        $byselectionnewest{$method}{$code}{$seq}{'pos'}    = $pos;
                        $byselectionnewest{$method}{$code}{$seq}{'prob'}   = $prob   if ($prob);
                        $byselectionnewest{$method}{$code}{$seq}{'strand'} = $strand if ($strand);
                        $byselectionnewest{$method}{$code}{$seq}{'other'}  = $other  if ($other);
                    };
                }
            }
        }
    }

    my @result; # graphic.pl input capsule
    if ($selection eq "codenew")
    {
        print "\tPRINTING by code new";
        @result = &generateResult(\%byselectionnew, "codenew", "method", "sequence", "position"); #return values needed by graphic.pl encapsulated in array
    }

    if ($selection eq "methodnew")
    {
        print "\tPRINTING by method new";
        @result = &generateResult(\%byselectionnew, "methodnew", "code", "sequence", "position");
    }





    if ($selection eq "codenewest")
    {
        print "\tPRINTING by code newest";
        @result = &generateResult(\%byselectionnewest, "codenewest", "method", "sequence","field");
    }

    if ($selection eq "methodnewest")
    {
        print "\tPRINTING by method newest";
        @result = &generateResult(\%byselectionnewest, "methodnewest", "code", "sequence","field");
    }





    if ($selection eq "codefilter")
    {
        print "\tPRINTING by code filter";
        @result = &generateResult(\%byselectionnewest, "codefilter", "method", "sequence","field");
    }

    if ($selection eq "methodfilter")
    {
        print "\tPRINTING by method filter";
        @result = &generateResult(\%byselectionnewest, "methodfilter", "code", "sequence","field");
    }




    if ($selection eq "method")
    {
        print "\tPRINTING by method";
        @result = &generateResult(\%byselection, "method", "position", "sequence");
    }

    if ($selection eq "code")
    {
        print "\tPRINTING by code";
        @result = &generateResult(\%byselection, "code", "position", "sequence");
    }

    if ($selection eq "position")
    {
        print "\tPRINTING by position";
        @result = &generateResult(\%byselection, "position", "sequence", "count");
    }

    if ($selection eq "sequence")
    {
        print "\tPRINTING by sequence";
        @result = &generateResult(\%byselection, "sequence", "position", "code");
    }

    if ($selection eq "methodshort")
    {
        print "\tPRINTING by methodshort";
        @result = &generateResult(\%byselection, "methodshort", "sequence", "count");
    }

    undef %byselection;
    undef %byselectionnew;
    undef %byselectionnewest;
    return @result;
}


sub generateResult
{
    #return values needed by graphic.pl encapsulated in array
    my %base   = %{$_[0]};
    my $name   = $_[1];
    my $first  = $_[2];
    my $second = $_[3];
    my $third  = $_[4];

    my @result;
    $result[0] = \%base;    #specific database
    $result[1] = $name; #filter name
    $result[2] = $first;    #first key name
    $result[3] = $second;   #second key name
    $result[4] = $third;    #third key name
#   savedump(\@result,"result"); # database
    return @result;
}

sub graphicSplit
{
#   print "GraphiSplit.....";
    my %a_database = %{$_[0]};  # database
    my $title1     = $_[1];     # title 1st field
    my $title2     = $_[2];     # title 2nd field
    my $title3     = $_[3];     # title 3rd field
    my $title4     = $_[4];     # title 4th field


    if ($title1 eq "codenewest")
    {
        &splitCodeNewestAna(\%a_database,$title1,$title2,$title3,$title4,"0");
        &splitCodeNewestAll(\%a_database,$title1,$title2,$title3,$title4);
    }
    elsif ($title1 eq "codefilter")
    {
        &splitCodeNewestAna(\%a_database,$title1,$title2,$title3,$title4,"1");
        &splitCodeNewestAll(\%a_database,$title1,$title2,$title3,$title4);
    }
    elsif ($title1 eq "methodnewest")
    {
        &splitMethodNewestAna(\%a_database,$title1,$title2,$title3,$title4);
        &splitMethodNewestAll(\%a_database,$title1,$title2,$title3,$title4);
    }
    elsif ($title1 eq "methodfilter")
    {
#       &splitMethodNewestAna(\%a_database,$title1,$title2,$title3,$title4,1);
        &splitMethodNewestAll(\%a_database,$title1,$title2,$title3,$title4);
    }
    else
    {
#       if (($title1 ne "codenew") && ($title1 ne "methodnew") && ($title1 ne "codenewest") && ($title1 ne "methodnewest")) { 
        &splitCode(\%a_database,$title1,$title2,$title3);
#        };
    }
    print "..DONE\n";
}



sub stat_result
{
    my $code;
    my $method;
    my $seq;
    my $pos;
    my $end;
    my $strand;
    my $other;
    my $prob;
    my $desc;

    if ($_[0]) { $code    = $_[0] } else { $code   = "" };
    if ($_[1]) { $method  = $_[1] } else { $method = "" };
    if ($_[2]) { $seq     = $_[2] } else { $seq    = "" };
    if ($_[3]) { $pos     = $_[3] } else { $pos    = "" };
    if ($_[4]) { $end     = $_[4] } else { $end    = "" };
    if ($_[5]) { $strand  = $_[5] } else { $strand = "" };
    if ($_[6]) { $other   = $_[6] } else { $other  = "" };
    if ($_[7]) { $prob    = $_[7] } else { $prob   = "" };
    if ($_[8]) { $desc    = $_[8] } else { $desc   = "" };

    open FILE, ">>/bio/stat.out" or die "CANT OPEN STAT.OUT (GRAPH_STATRESULT_001): $!\n";
    print FILE "$select\t$code\t$method\t$seq\t$pos\t$end\t$strand\t$other\t$prob\t$desc\n";
    close FILE;
}

############################################
####        GRAPHIC         ####
############################################
sub splitCodeNewestAll
{
    my %a_database = %{$_[0]};
    my $title1     = $_[1];
    my $title2     = $_[2];
    my $title3     = $_[3];
    my $title4     = $_[4];

    my $folder = "$titleFile\/$title1";

    &checkdir("$wwwfolder\/$titleFile");    #check for main folder
    &checkdir("$wwwfolder\/$folder");   #check for specific subfolder

    foreach my $code (sort keys %a_database)
    {
        if ($multithread)
        {
            my $threads_num = `pgrep $script_name | wc -l`;
    
            while ($threads_num >= 4)
            {
                sleep(2); # sleep
                $threads_num = `pgrep $script_name | wc -l`;
            };
        }

        my $pid = threading::multiThread("in",$multithread);
        push(@pid, $pid) if ($pid > 1);
        if ($pid <= 1)
        {
            my $panel = Bio::Graphics::Panel->new(
                            -length    => 550,
                            -width     => $width,
                            -key_style => 'between',
                            -pad_left  => 10,
                            -pad_right => 10,
                            );
    
            my $full_length = Bio::SeqFeature::Generic->new(
                            -start        =>1,
                            -end          =>500,
                            -display_name =>$code
                            );

            my %sorted_features;
            my @line;
    
            foreach my $method (sort keys %{$a_database{$code}})
            {
                foreach my $seq (sort keys %{$a_database{$code}{$method}})
                {
                    my $pos    = $a_database{$code}{$method}{$seq}{'pos'};
                    my $prob;
                    my $strand;
                    my $other;
                    $prob   = $a_database{$code}{$method}{$seq}{'prob'}   if (defined $a_database{$code}{$method}{$seq}{'prob'});
                    $strand = $a_database{$code}{$method}{$seq}{'strand'} if (defined $a_database{$code}{$method}{$seq}{'strand'});
                    $other  = $a_database{$code}{$method}{$seq}{'other'}  if (defined $a_database{$code}{$method}{$seq}{'other'});
                    my $desc;

                    $desc .= "STRAND: $strand; " if ($strand);
                    $desc .= "$other"  if ($other);
    
                    my $end = $pos + length($seq);
    
                    my $feature = Bio::SeqFeature::Generic->new(
                                        -display_name =>"$seq($pos)",
                                        -start        =>$pos,
                                        -end          =>$end,
                                        -connector    =>'dashed',
                                        -tag          =>{ description => $desc},
                                        );
    
                    push(@{$sorted_features{$method}},$feature);
                    undef $feature;
                    &stat_result($code,$method,$seq,$pos,$end,$strand,$other,$prob,$desc);
                }#END FOREACH SEQUENCE
            }#END FOREACH METHOD
    
            my @colors = qw(cyan orange lgray dgray gray blue gold purple green chartreuse magenta yellow aqua pink marine cyan);
            my $idx    = 0;
    
            for my $tag (sort keys %sorted_features)
            {
                $panel->add_track($full_length,
                        -glyph   => 'arrow',
                        -tick    => 3,
                        -fgcolor => 'black',
                        -double  => 1,
                        -label   => 1,
                        );
    
                my $features = $sorted_features{$tag};
                $panel->add_track($features,
                        -glyph       =>  'generic',
                        -bgcolor     =>  $colors[$idx++ % @colors],
                        -fgcolor     => 'black',
                        -font2color  => 'red',
                        -connector   => 'dashed',
                        -key         => "${tag}",
                        -bump        => +1,
                        -height      => 8,
                        -label       => 1,
                        -description => 1,
                        );
            }#END FOR MY TAG
    
            my $png = $panel->png;

            my $filename           = $titleFile . "_" . $title1 . "_" . $code . ".png";
            my $pngShortFileName   = "$folder\/$filename"; #png filename short
            my $pngFileName        = "$wwwfolder\/$pngShortFileName"; # png full filename

            open(IMG, ">$pngFileName") or die "CANNOT SAVE PNG $pngFileName (GRAPHIC_SPLITCODENEWESTALL_001): $!";
            binmode IMG;
            print IMG $png;
            close IMG;

            undef $panel;
            undef $full_length;
        threading::multiThread("out",$multithread);
        }
    }#END FOREACH CODE
    undef %a_database;
}#END SPLIT CODE NEWEST


sub splitCodeNewestAna
{
    my %a_database = %{$_[0]};
    my $title1     = $_[1];
    my $title2     = $_[2];
    my $title3     = $_[3];
    my $title4     = $_[4];
    my $codeFilter = $_[5];
    my $promlist;

    my $folder = "$titleFile\/$title1";
    &checkdir("$wwwfolder\/$titleFile");    #check for main folder
    &checkdir("$wwwfolder\/$folder");   #check for specific subfolder

    foreach my $code (sort keys %a_database)
    {
        my $threads_num = `pgrep $script_name | wc -l`;
        $promlist  = "</pre><table>\n";
        $promlist .= <<HTML
    <tr>
      <td style=\"border-bottom-style: solid; border-bottom-width: 3\" align=\"center\"><b><font size=\"4\">PROMOTER</font></b></td>
      <td style=\"border-bottom-style: solid; border-bottom-width: 3\" align=\"center\"><b><font size=\"4\">POSITION</font></b></td>
      <td style=\"border-bottom-style: solid; border-bottom-width: 3\" align=\"center\"><b><font size=\"4\">PROB.</font></b></td>
      <td style=\"border-bottom-style: solid; border-bottom-width: 3\" align=\"center\"><b><font size=\"4\">STRAND</font></b></td>
      <td style=\"border-bottom-style: solid; border-bottom-width: 3\" align=\"center\"><b><font size=\"4\">OTHER INFO</font></b></td>
      <td style=\"border-bottom-style: solid; border-bottom-width: 3\" align=\"center\"><b><font size=\"4\">METHOD</font></b></td>
    </tr>\n
HTML
;
        while ($threads_num >= 4)
        {
            sleep(2); # sleep
            $threads_num = `pgrep $script_name | wc -l`;
        };

        my $pid = threading::multiThread("in",$multithread);
        push(@pid, $pid) if ($pid > 1);
        if ($pid <= 1)
        {
            my @line;

            my %methods;
    
            foreach my $method (sort keys %{$a_database{$code}})
            {
                foreach my $seq (sort keys %{$a_database{$code}{$method}})
                {
                    my $pos    = $a_database{$code}{$method}{$seq}{'pos'};
                    my $prob;
                    my $strand;
                    my $other;
                    if (defined $a_database{$code}{$method}{$seq}{'prob'})   { $prob   = $a_database{$code}{$method}{$seq}{'prob'}    } else { $prob   = 'na'; };
                    if (defined $a_database{$code}{$method}{$seq}{'strand'}) { $strand = $a_database{$code}{$method}{$seq}{'strand'}  } else { $strand = 'na'; };
                    if (defined $a_database{$code}{$method}{$seq}{'other'})  { $other  = $a_database{$code}{$method}{$seq}{'other'}   } else { $other  = 'na'; };
                    my $desc;

                    $desc .= "STRAND: $strand;" if ($strand ne "na");
                    $desc .= " $other"  if ($other ne "na");
    
                    my $end = $pos + length($seq);
                    $seq =~ s/\w{10}/$& /g;

                    $promlist .=  <<HTML
<tr>
  <td style=\"border-bottom-style: solid; border-bottom-width: 1\">$seq</td>
  <td style=\"border-bottom-style: solid; border-bottom-width: 1\" align=\"center\">$pos</td>
  <td style=\"border-bottom-style: solid; border-bottom-width: 1\" width=\"100\" align=\"center\">$prob</td>
  <td style=\"border-bottom-style: solid; border-bottom-width: 1\" align=\"center\">$strand</td>
  <td style=\"border-bottom-style: solid; border-bottom-width: 1\">$other</td>
  <td style=\"border-bottom-style: solid; border-bottom-width: 1\" align=\"center\">$method</td>
</tr>\n
HTML
;

                    for (my $i = $pos; $i <= $end; $i++)
                    {
                        $line[$i]++;
                        ${$methods{$method}}[$i]++;
                    }# END FOR MY I
                }#END FOREACH SEQUENCE
            }#END FOREACH METHOD
            $promlist .= "</table><pre>\n";
            my @line2;
            my @line3;

            my @keys = (sort keys %methods);
            for (my $i = 0; $i < 500; $i++)
            {
                foreach my $method (@keys)
                {
                    if (exists ${$methods{$method}}[$i]) { $line2[$i] += 1; };
                }
            }#END FOR MY I

            if ( ! $codeFilter)
            {
#               print "error\t";
                @line     = &distribution::analyseLineShort(@line)                   if ($title1 ne 'position');
                @line2    = &distribution::analyseLineScoreShort(@line2)             if ($title1 ne 'position');
                @line3    = &distribution::analyseLineCompositeShort(\@line,\@line2) if ($title1 ne 'position');
    
                my $gif1  = plotGraphShort(@line,"$titleFile :: $title1 :: $code :: GENERAL APPEARENCE");
                my $filenamegif1 = $titleFile . "_" . $title1 . "_" . $code . "_1.gif";
                open(IMG, ">$wwwfolder\/$folder\/$filenamegif1") or die "CANNOT SAVE GIF $wwwfolder\/$folder\/$filenamegif1 (GRAPHIC_splitCodeNewestAna_001): $!";
                binmode IMG;
                print IMG $gif1;
                close IMG;
    
                my $gif2  = plotGraphShort(@line2,"$titleFile :: $title1 :: $code :: METHOD SCORED APPEARENCE");
                my $filenamegif2 = $titleFile . "_" . $title1 . "_" . $code . "_2.gif";
                open(IMG, ">$wwwfolder\/$folder\/$filenamegif2") or die "CANNOT SAVE GIF $wwwfolder\/$folder\/$filenamegif2 (GRAPHIC_splitCodeNewestAna_002): $!";
                binmode IMG;
                print IMG $gif2;
                close IMG;
    
                my $gif3  = plotGraphShort(@line3,"$titleFile :: $title1 :: $code :: VALID APPEARENCE");
                my $filenamegif3 = $titleFile . "_" . $title1 . "_" . $code . "_3.gif";
                open(IMG, ">$wwwfolder\/$folder\/$filenamegif3") or die "CANNOT SAVE GIF $wwwfolder\/$folder\/$filenamegif3 (GRAPHIC_splitCodeNewestAna_003): $!";
                binmode IMG;
                print IMG $gif3;
                close IMG;

                my $line1 = &distribution::plotGraphText(@line,,"$titleFile :: $title1 :: $code :: GENERAL APPEARENCE",\%fasta, $code);
                my $filenametxt1 = $titleFile . "_" . $title1 . "_" . $code . "_1.txt";
                open FILE, ">$wwwfolder\/$folder\/$filenametxt1" or die "CANNOT SAVE TXT $wwwfolder\/$folder\/$filenametxt1 (GRAPHIC_splitCodeNewestAna_004): $!";
                print FILE $line1;
                close FILE;
    
                my $line2 = &distribution::plotGraphText(@line2,"$titleFile :: $title1 :: $code :: METHOD SCORED APPEARENCE",\%fasta,$code);
                my $filenametxt2 = $titleFile . "_" . $title1 . "_" . $code . "_2.txt";
                open FILE, ">$wwwfolder\/$folder\/$filenametxt2" or die "CANNOT SAVE TXT $wwwfolder\/$folder\/$filenametxt2 (GRAPHIC_splitCodeNewestAna_005): $!";
                print FILE $line2;
                close FILE;

                my $line3 = &distribution::plotGraphText(@line3,"$titleFile :: $title1 :: $code :: VALID APPEARENCE",\%fasta,$code);
                my $filenametxt3 = $titleFile . "_" . $title1 . "_" . $code . "_3.txt";
                open FILE, ">$wwwfolder\/$folder\/$filenametxt3" or die "CANNOT SAVE TXT $wwwfolder\/$folder\/$filenametxt3 (GRAPHIC_splitCodeNewestAna_006): $!";
                print FILE $line3 . "\n\n";
                print FILE $promlist . "\n";
                close FILE;
            }
            else
            {
#               print $final{$code} . "\t";
                my $line4 = $final{$code};
                my $filenametxt1 = $titleFile . "_" . $title1 . "_" . $code . "_1.txt";
                open FILE, ">$wwwfolder\/$folder\/$filenametxt1" or die "CANNOT SAVE TXT $wwwfolder\/$folder\/$filenametxt1 (GRAPHIC_splitCodeNewestAna_007): $!";
                print FILE $code . "\n";
                print FILE $line4 . "\n\n";
                print FILE $promlist;
                close FILE;
            }

        threading::multiThread("out",$multithread);
        }
    }#END FOREACH CODE
    undef %a_database;
}#END SPLIT CODE NEWEST


sub splitMethodNewestAll
{
    my %a_database = %{$_[0]};
    my $title1     = $_[1];
    my $title2     = $_[2];
    my $title3     = $_[3];
    my $title4     = $_[4];

    my $folder = "$titleFile\/$title1";

    &checkdir("$wwwfolder\/$titleFile");    #check for main folder
    &checkdir("$wwwfolder\/$folder");   #check for specific subfolder

    foreach my $method (sort keys %a_database)
    {
        my $pid = threading::multiThread("in",$multithread);
        push(@pid, $pid) if ($pid > 1);
        if ($pid <= 1)
        {
            my $panel = Bio::Graphics::Panel->new(
                            -length    => 550,
                            -width     => $width,
                            -key_style => 'between',
                            -pad_left  => 10,
                            -pad_right => 10,
                            );
    
            my $full_length = Bio::SeqFeature::Generic->new(
                            -start        =>1,
                            -end          =>500,
                            -display_name =>$method
                            );
    
            my %sorted_features;
            my @line;
    
            foreach my $code (sort keys %{$a_database{$method}})
            {
                foreach my $seq (sort keys %{$a_database{$method}{$code}})
                {
                    my $pos    = $a_database{$method}{$code}{$seq}{'pos'};
                    my $prob;
                    my $strand;
                    my $other;
                    $prob   = $a_database{$method}{$code}{$seq}{'prob'}   if (defined $a_database{$method}{$code}{$seq}{'prob'});
                    $strand = $a_database{$method}{$code}{$seq}{'strand'} if (defined $a_database{$method}{$code}{$seq}{'strand'});
                    $other  = $a_database{$method}{$code}{$seq}{'other'}  if (defined $a_database{$method}{$code}{$seq}{'other'});
                    my $desc;

                    $desc .= "STRAND: $strand; " if ($strand);
                    $desc .= "$other"  if ($other);

                    my $end = $pos + length($seq);

                    my $feature = Bio::SeqFeature::Generic->new(
                                        -display_name =>"$seq($pos)",
                                        -start        =>$pos,
                                        -end          =>$end,
                                        -connector    =>'dashed',
                                        -tag          =>{ description => $desc},
                                        );
    
                    push(@{$sorted_features{$code}},$feature);
                    undef $feature;
                    &stat_result($method,$code,$seq,$pos,$end,$strand,$other,$prob,$desc);
                }#END FOREACH SEQUENCE
            }#END FOREACH METHOD
    
            my @colors = qw(cyan orange lgray dgray gray blue gold purple green chartreuse magenta yellow aqua pink marine cyan);
            my $idx    = 0;
    
            for my $tag (sort keys %sorted_features)
            {
                $panel->add_track($full_length,
                        -glyph   => 'arrow',
                        -tick    => 3,
                        -fgcolor => 'black',
                        -double  => 1,
                        -label   => 1,
                        );
    
                my $features = $sorted_features{$tag};
                $panel->add_track($features,
                        -glyph       =>  'generic',
                        -bgcolor     =>  $colors[$idx++ % @colors],
                        -fgcolor     => 'black',
                        -font2color  => 'red',
                        -connector   => 'dashed',
                        -key         => "${tag}",
                        -bump        => +1,
                        -height      => 8,
                        -label       => 1,
                        -description => 1,
                        );
            }#END FOR MY TAG
    
#           my $png   = $panel->png;
            my $heig  = $panel->height;
            my $chunk = 10240;
            my $total = (int($heig / $chunk) + 1);

            for (my $i = 1; $i <= $total; $i++)
            {
                my $start = ($i - 1) * $chunk;
                my $end   = $i * $chunk;
                $end = $heig if ($end > $heig);
#               print "$pngFileName HEIGHT $heig FINAL $total I $i START $start END $end\n";

                my $length = length($i);
                my $complement = 3 - $length;

                my $image = new GD::Image($width,($end-$start));
                $image->copy($panel->gd,0,0,0,$start,$width,$chunk);
                my $namei = 0 x $complement . $i;

                my $filename           = $titleFile . "_" . $title1 . "_" . $method . "_$namei.png";
                my $pngShortFileName   = "$folder\/$filename"; #png filename short
                my $pngFileName        = "$wwwfolder\/$pngShortFileName"; # png full filename

                open(IMG, ">$pngFileName") or die "CANNOT SAVE PNG $pngFileName (GRAPHIC_splitMethodNewestAll_001): $!";
                binmode IMG;
#               print IMG $png;
                print IMG $image->png;
                close IMG;
            }

            undef $panel;
            undef $full_length;
#       print "running THREAD $oldpid $$ ENDED\n" if $multithread;
        threading::multiThread("out",$multithread);
        };
    }#END FOREACH METHOD
    undef %a_database;
}#END SPLIT METHOD NEWEST

sub splitMethodNewestAna
{
    my %a_database = %{$_[0]};
    my $title1     = $_[1];
    my $title2     = $_[2];
    my $title3     = $_[3];
    my $title4     = $_[4];

    my $folder = "$titleFile\/$title1";
    &checkdir("$wwwfolder\/$titleFile");    #check for main folder
    &checkdir("$wwwfolder\/$folder");   #check for specific subfolder

    foreach my $method (sort keys %a_database)
    {
        my $pid = threading::multiThread("in",$multithread);
        push(@pid, $pid) if ($pid > 1);
        if ($pid <= 1)
        {
            my %sorted_features;
            my @line;

            my %methods;
    
            foreach my $code (sort keys %{$a_database{$method}})
            {
                foreach my $seq (sort keys %{$a_database{$method}{$code}})
                {
                    my $pos    = $a_database{$method}{$code}{$seq}{'pos'};
                    my $prob;
                    my $strand;
                    my $other;
                    $prob   = $a_database{$method}{$code}{$seq}{'prob'}   if (defined $a_database{$method}{$code}{$seq}{'prob'});
                    $strand = $a_database{$method}{$code}{$seq}{'strand'} if (defined $a_database{$method}{$code}{$seq}{'strand'});
                    $other  = $a_database{$method}{$code}{$seq}{'other'}  if (defined $a_database{$method}{$code}{$seq}{'other'});
                    my $desc;

                    $desc .= "STRAND: $strand; " if ($strand);
                    $desc .= "$other"  if ($other);
    
                    my $end = $pos + length($seq);
    
                    for (my $i = $pos; $i <= $end; $i++)
                    {
                        $line[$i]++;
                        ${$methods{$method}}[$i]++;
                    }# END FOR MY I
                }#END FOREACH SEQUENCE
            }#END FOREACH METHOD
            my @line2;
            my @line3;

#           for (my $i = 0; $i <= @line; $i++)
            my @keys = (sort keys %methods);
            for (my $i = 0; $i < 500; $i++)
            {
                foreach my $method (@keys)
                {
                    if (exists ${$methods{$method}}[$i]) { $line2[$i] += 1; };
                }
            }#END FOR MY I
# 
            @line     = &distribution::analyseLineShort(@line)                   if ($title1 ne 'position');
            @line2    = &distribution::analyseLineScoreShort(@line2)             if ($title1 ne 'position');
            @line3    = &distribution::analyseLineCompositeShort(\@line,\@line2) if ($title1 ne 'position');
#           savedump(\@line2,"line2");
# 
            my $gif1  = plotGraphShort(@line,"$titleFile :: $title1 :: $method :: GENERAL APPEARENCE");
            my $filenamegif1 = $titleFile . "_" . $title1 . "_" . $method . "_1.gif";
            open(IMG, ">$wwwfolder\/$folder\/$filenamegif1") or die "CANNOT SAVE GIF $wwwfolder\/$folder\/$filenamegif1 (GRAPHIC_splitMethodNewestAna_001): $!";
            binmode IMG;
            print IMG $gif1;
            close IMG;
# 
#           my $gif2  = plotGraphShort(@line2);
#           my $filenamegif2 = $titleFile . "_" . $title1 . "_" . $method . "_2.gif";
#           open(IMG, ">$wwwfolder\/$folder\/$filenamegif2") or die "CANNOT SAVE GIF $filenamegif2: $!";
#           binmode IMG;
#           print IMG $gif2;
#           close IMG;
# 
#           my $gif3  = plotGraphShort(@line3);
#           my $filenamegif3 = $titleFile . "_" . $title1 . "_" . $method . "_3.gif";
#           open(IMG, ">$wwwfolder\/$folder\/$filenamegif3") or die "CANNOT SAVE GIF $filenamegif3: $!";
#           binmode IMG;
#           print IMG $gif3;
#           close IMG;
# 
            my $line1 = &distribution::plotGraphText(@line,"$titleFile :: $title1 :: $method :: GENERAL APPEARENCE");
            my $filenametxt1 = $titleFile . "_" . $title1 . "_" . $method . "_1.txt";
            open FILE, ">$wwwfolder\/$folder\/$filenametxt1" or die "CANNOT SAVE TXT $wwwfolder\/$folder\/$filenametxt1 (GRAPHIC_splitMethodNewestAna_002): $!";
            print FILE $line1;
            close FILE;
#
#           my $line2 = plotGraphText(@line2);
#           my $filenametxt2 = $titleFile . "_" . $title1 . "_" . $method . "_2.txt";
#           open FILE, ">$wwwfolder\/$folder\/$filenametxt2" or die "CANNOT SAVE TXT $filenametxt2: $!";
#           print FILE $line2;
#           close FILE;
# 
#           my $line3 = plotGraphText(@line3);
#           my $filenametxt3 = $titleFile . "_" . $title1 . "_" . $method . "_3.txt";
#           open FILE, ">$wwwfolder\/$folder\/$filenametxt3" or die "CANNOT SAVE TXT $filenametxt3: $!";
#           print FILE $line3;
#           close FILE;
# 
#       print "running THREAD $oldpid $$ ENDED\n" if $multithread;
        threading::multiThread("out",$multithread);
        };#END IF THREAD
    }#END FOREACH METHOD
    undef %a_database;
}#END SPLIT METHOD NEWEST

sub splitCode
{
    my %a_database = %{$_[0]};
    my $title1     = $_[1];
    my $title2     = $_[2];
    my $title3     = $_[3];

    foreach my $first (sort keys %a_database)
    {
        my @line;
        my $pid = threading::multiThread("in",$multithread);
        push(@pid, $pid) if ($pid > 1);
        if ($pid <= 1)
        {
            my $panel = Bio::Graphics::Panel->new(
                            -length    => 550,
                            -width     => $width,
                            -key_style => 'between',
                            -pad_left  => 10,
                            -pad_right => 10,
                            );
    
            my $full_length = Bio::SeqFeature::Generic->new(
                            -start=>1,
                            -end=>500,
                            -display_name=>$first
                            );
    
            $panel->add_track($full_length,
                    -glyph   => 'arrow',
                    -tick    => 2,
                    -fgcolor => 'black',
                    -double  => 1,
                    -label   => 1,
                    );
    
            my %sorted_features;
            
            foreach my $second (sort keys %{$a_database{$first}})
            {
                my $value = $a_database{$first}{$second};
    
                my $start;
                my $end;
                ($start, $end) = &startend($title1, $title2, $title3, $first, $second, $value);
    
                my $feature;
    
                $feature = Bio::SeqFeature::Generic->new(
                                    -display_name=>$second,
                                    -start=>$start,
                                    -end=>$end,
                                    -description=>$second,
                                    );
    
                push(@{$sorted_features{$value}},$feature);
                undef $feature;

                &stat_result($first, $second, $value, $start, $end);
    
                for (my $i = $start; $i <= $end; $i++)
                {
                    $line[$i]++;
                }
            }#END FOR MY SECOND
    
            my @colors = qw(cyan orange blue purple green chartreuse magenta yellow aqua);
            my $idx    = 0;
    
            for my $tag (sort keys %sorted_features)
            {
                my $features = $sorted_features{$tag};
                $panel->add_track($features,
                        -glyph       =>  'generic',
                        -bgcolor     =>  $colors[$idx++ % @colors],
                        -fgcolor     => 'black',
                        -font2color  => 'red',
                        -connector   => 'dashed',
                        -key         => "${tag}",
                        -bump        => +1,
                        -height      => 8,
                        -label       => 1,
                        -description => 1,
                        );
            } # END FOR MY TAG
            (my $gif, my $graphline) = &analyseLine(@line) if ($title1 ne 'position');
            my $png = $panel->png;
            &printImage($png,$title1,$first,$gif,undef,$graphline,undef);
    
            undef $panel;
            undef $full_length;
        threading::multiThread("out",$multithread);
        }; #END IF PID
    } # END FOREACH FIRST
    undef %a_database;
}# END SUB SPLIT CODE



############################################
####        ANALISE LINE        ####
############################################
# sub analyseLineScore
# {
#   my @line = @_;
#   my @special;
#   my @special2;
# 
#   my $count = scalar(@line);
#   my $sum;
#   my $sumvar;
#   my $return;
#   my $count_non_empty = 0;
# 
# #     for (my $i = 0; $i <= $count; $i++)
#   for (my $i = 0; $i < 500; $i++)
#   {
#       if ($line[$i])
#       {
#           $sum += $line[$i];
#           $count_non_empty++;
#       }
#       else
#       {
#           $line[$i] = 0;
#       }
#   };
# 
#   my $mean   = $sum / $count_non_empty;
# 
#   my $min      = $mean;
#   my $max      = $mean;
# 
#   my $minimum  = 0;
#   my $maximum  = 0;
# 
# #     for (my $i = 0; $i <= $count; $i++)
#   for (my $i = 0; $i < 500; $i++)
#   {
#       my $meani = $line[$i];
#       my $texti;
#       my $textj;
# 
#       $minimum = $meani if ($meani < $minimum);
#       $maximum = $meani if ($meani > $maximum);
# 
#       $texti = ""   . ($i +1) if (($i +1) >= 100);    
#       $texti = "0"  . ($i +1) if (($i +1) <  100);
#       $texti = "00" . ($i +1) if (($i +1) <   10);
# 
#       my $length = length($meani);
#       my $complement = 3 - $length;
#       $textj = ""   . "$meani"               if ($meani >= 100);
#       $textj = "0"  x $complement . "$meani" if ($meani <  100);
# 
#       if ($meani >= $minscore) { $texti .= " +"; $special[$i] = "$meani"; };
# 
#       if (($meani >= $max) && ($meani <  $minscore)) { $texti .= " *"; $special2[$i] = "$meani"; };
#       if (($meani <  $minscore) && ($meani <  $max)) { $texti .= "  "; };
# 
#       $return .= "$texti $textj " . "#" x ($meani * 10) . "\n" if $meani;
#       $return .= "$texti $textj \n" if (!($meani));
#   };
# 
#   my $gif;
#      $gif = plotGraph(\@line,\@special,$min,"5",$minimum,$maximum,\@special2) if (@special2);
#      $gif = plotGraph(\@line,\@special,$min,"5",$minimum,$maximum,) if (!(@special2));
# 
#   my $graphline = generateHtmlGraph($return);
#   my @return;
#   $return[0] = $gif;
#   $return[1] = $graphline;
#   return @return;
# };
# 
# sub analyseLine
# {
#   my @line = @_;
#   my @line2;
#   my @line3;
#   my @special;
#   my @special2;
#   my $count = scalar(@line);
#   my $sum;
#   my $sumvar;
#   my $return;
# 
#   for (my $i = 0; $i < 500; $i++)
#   {
#       if ($line[$i])
#       {
#           $sum    += $line[$i];
#           push(@line2,$line[$i]);
#           $special[$i]  = 0;
#           $special2[$i] = 0;
#       }
#       else
#       {
#           $line[$i]     = 0;
#           $special[$i]  = 0;
#           $special2[$i] = 0;
#       }
#   };
# 
#   my $mean   = $sum / @line2;
# 
#   for (my $i = 0; $i < @line2; $i++)
#   {
#       $sumvar   += ($line2[$i] - $mean) ** 2;
#   };
# 
#   my $variance = $sumvar / @line2;
#   my $stdDev = sqrt($variance);
# 
#   my $min99 = $mean - ($stdDev * 2.576); # 99%
#   my $max99 = $mean + ($stdDev * 2.576);
# 
#   my $min95 = $mean - ($stdDev * 1.960); # 95%
#   my $max95 = $mean + ($stdDev * 1.960); 
# 
#   my $min90 = $mean - ($stdDev * 1.645); # 90%
#   my $max90 = $mean + ($stdDev * 1.645); 
# 
#   my $minimum = 0;
#   my $maximum = 0;
# 
#   for (my $i = 0; $i < 500; $i++)
#   {
#       my $meani = $line[$i];
# 
#       my $texti;
#       my $textj;
# 
#       $minimum = $meani if ($meani < $minimum);
#       $maximum = $meani if ($meani > $maximum);
# 
#       $texti = ""   . ($i +1) if (($i +1) >= 100);        
#       $texti = "0"  . ($i +1) if (($i +1) <  100);
#       $texti = "00" . ($i +1) if (($i +1) <   10);
# 
#       my $length = length($meani);
#       my $complement = 3 - $length;
#       $textj = ""   . "$meani"               if ($meani >= 100);
#       $textj = "0"  x $complement . "$meani" if ($meani <  100);
# 
#       if    ($meani > $max95)                          { $texti .= " +"; $special[$i]  = "$meani"; $line[$i] = 0; }
#       elsif (($meani > $max90)  && ($meani < $max95))  { $texti .= " *"; $special2[$i] = "$meani"; $line[$i] = 0; }
#       elsif (($meani <= $max90) && ($meani <= $max95)) { $texti .= "  ";};
# 
#       $return .= "$texti $textj " . "#" x (int($meani / 10)) . "\n" if $meani;
#       $return .= "$texti $textj " . "#" x $meani        . "\n" if (!($meani));
#   };
# 
#   my $graphline = generateHtmlGraph($return);
# 
#   my $gif;
#      $gif = plotGraphShort(\@line,\@special,\@special2,"SEQUENCE APPEARENCE");
# 
#   my @return;
#   $return[0] = $gif;
#   $return[1] = $graphline;
#   return @return;
# };


sub plotGraphShort
{
    my @lines    = @{$_[0]};
    my @special  = @{$_[1]};
    my @special2 = @{$_[2]};
    my $title    = $_[3];

    my @legend_keys;
    my $max = 0;
    my @line2;

    $line2[0] = \@lines;
    $line2[1] = \@special;
    $line2[2] = \@special2;
    $line2[3] = \@lines;
    $legend_keys[0] = ">95%";
    $legend_keys[1] = ">90%";
    $legend_keys[2] = "not valid";

    my $panel = GD::Graph::bars->new($width, ($width * .85));

    $panel->set(    title           => "PROMOTER APEARENCE :: $title",
            y_label         => 'count',
#           y_tick_number       => (int($max) / 10),
            y_label_skip        => '2',
            y_min_value     => '0',
#           y_max_value     => int($max),
            x_label         => 'position',
            x_tick_number       => '10',
            x_label_skip        => '2',
            x_min_value     => '0',
            x_max_value     => '500',
            l_margin        => '10',
            r_margin        => '10',
            borderclrs      => 'black',
            cumulate        => 'false',
            legend_placement    => 'RT',
            legend_marker_width => '24', 
            legend_marker_height    => '16',
        ) or die "ERROR CREATING GRAPHIC (GRAPHIC_plotGraphShort_001) " . $panel->error;

    $panel->set_legend(@legend_keys);
    $panel->set_legend_font('gdMediumBoldFont');
    $panel->set( dclrs => [ qw(lred purple lgreen) ] ) if (scalar(@legend_keys) == 3);
    $panel->set( dclrs => [ qw(lred lgreen) ] )        if (scalar(@legend_keys) == 2);

    my $gd  = $panel->plot(\@line2) or die  "ERROR CREATING GRAPHIC (GRAPHIC_plotGraphShort_002) " . $panel->error; 
    my $gif = $gd->gif;
    return $gif;
}



sub plotGraph
{
    my @lines   = @{$_[0]};
    my @special = @{$_[1]};
    my $min     = $_[2];
    my $max     = $_[3];
    my $minimum = $_[4];
    my $maximum = $_[5];
    my @special2;
    @special2 = @{$_[6]} if $_[6];

    my @line2;
    my @line3;
    my @names;
    my @ex;
    my @yp;
    my @zt;
    my @legend_keys;

    if (@special2)
    {
#       for (my $k = 0; $k < (@lines); $k++)
        for (my $k = 0; $k < 500; $k++)
        {
            $names[$k] = "n";
            if ($special[$k])
            {
                $ex[$k+1]    = $special[$k];
            }
            elsif ($special2[$k])
            {
                $zt[$k+1]    = $special2[$k];   
            }
            else
            {
                $yp[$k+1]    = $lines[$k];
            }
        };
        $line2[0] = \@names;
        $line2[1] = \@ex;
        $line2[2] = \@zt;
        $line2[3] = \@yp;
        $legend_keys[0] = ">95%";
        $legend_keys[1] = ">90%";
        $legend_keys[2] = "not valid";
    }
    else
    {
#       for (my $k = 0; $k < (@lines); $k++)
        for (my $k = 0; $k < 500; $k++)
        {
            $names[$k] = "n";
            if ($special[$k])
            {
                $ex[$k+1]    = $special[$k];
            }
            else
            {
                $yp[$k+1]    = $lines[$k];
            }
        }
        $line2[0] = \@names;
        $line2[1] = \@ex;
        $line2[2] = \@yp;
        $legend_keys[0] = ">99%";
        $legend_keys[1] = "not valid";
    }

    
    my $panel = GD::Graph::bars->new($width, ($width * .75));

    $panel->set(    title         => 'PROMOTER APEARENCE',
            y_label       => 'count',
            y_tick_number => (int($maximum) / 10),
            y_label_skip  => '2',
            y_min_value   => '0',
            y_max_value   => int($maximum),
            x_label       => 'position',
            x_tick_number => '10',
            x_label_skip  => '1',
            x_min_value   => '0',
            x_max_value   => '500',
            l_margin      => '10',
            r_margin      => '10',
            borderclrs    => 'black',
            cumulate      => 'false',
            legend_placement     => 'RT',
            legend_marker_width  => '24', 
            legend_marker_height => '16',
        ) or die "ERROR CREATING GRAPHIC (GRAPHIC_plotGraph_001) " . $panel->error;

    $panel->set_legend(@legend_keys);
    $panel->set_legend_font('gdMediumBoldFont');
    $panel->set( dclrs => [ qw(lred purple lgreen) ] ) if (scalar(@legend_keys) == 3);
    $panel->set( dclrs => [ qw(lred lgreen) ]        ) if (scalar(@legend_keys) == 2);

    my $gd  = $panel->plot(\@line2) or die "ERROR CREATING GRAPHIC (GRAPHIC_plotGraph_002) " . $panel->error; 
    my $gif = $gd->gif;
    return $gif;
}

sub generateHtmlGraph
{
    my $graphline;
    if ($_[0])
    {
        $graphline  = $_[0];
        $graphline .= " |  |  |\n";
        $graphline .= " |  |  |________________________\n";
        $graphline .= " |  |________                   |\n";
        $graphline .= " |           |                  |\n";
        $graphline .= "pos number / significance 95% / number of motifs in this pos.\n";
    }
    else
    {
        $graphline = "";
    };
    return $graphline;
}

############################################
####        TOOLS           ####
############################################
sub startendnew
{
    #defines and return start and end positions
    my $title4;
    my $third;
    my $title1 = $_[0];
    my $title2 = $_[1];
    my $title3 = $_[2];
    if ($_[3]) { $title4 = $_[3]; } else { $title4 = ""; };
    my $first  = $_[4];
    my $second = $_[5];
    if ($_[6]) { $third  = $_[6]; } else { $third  = ""; };
    my $value  = $_[7];

    my $start = 1;
    my $end   = 1;

    if ($title1 eq "position") { $start = $first  ;};
    if ($title2 eq "position") { $start = $second ;};
    if ($title3 eq "position") { $start = $third  ;};
    if ($title4 eq "position") { $start = $value  ;};

    if ($title1 eq "sequence") { $end = $start + length($first)  ;};
    if ($title2 eq "sequence") { $end = $start + length($second) ;};
    if ($title3 eq "sequence") { $end = $start + length($third)  ;};
    if ($title4 eq "sequence") { $end = $start + length($value)  ;};

    my @return;
    $return[0] = $start;
    $return[1] = $end;
    return @return;
}

sub startend
{
    #defines and return start and end positions
    my $title1 = $_[0];
    my $title2 = $_[1];
    my $title3 = $_[2];
    my $first  = $_[3];
    my $second = $_[4];
    my $value  = $_[5];

    my $start = 1;
    my $end   = 1;

    if ($title1 eq "position") { $start = $first  ;};
    if ($title2 eq "position") { $start = $second ;};
    if ($title3 eq "position") { $start = $value  ;};

    if ($title1 eq "sequence") { $end = $start + length($first)  ;};
    if ($title2 eq "sequence") { $end = $start + length($second) ;};
    if ($title3 eq "sequence") { $end = $start + length($value)  ;};

    my @return;
    $return[0] = $start;
    $return[1] = $end;
    return @return;
}

sub getMethod
{
    # returns the method name
    my $title1 = $_[0];
    my $title2 = $_[1];
    my $title3 = $_[2];
    my $title4 = $_[3];
    my $first  = $_[4];
    my $second = $_[5];
    my $third  = $_[6];
    my $value  = $_[7];

    my $method;

    if (($title1 eq "method") || ($title1 eq "methodnew")) { $method = $first  ;};
    if (($title2 eq "method") || ($title2 eq "methodnew")) { $method = $second ;};
    if (($title3 eq "method") || ($title3 eq "methodnew")) { $method = $third  ;};
    if (($title4 eq "method") || ($title4 eq "methodnew")) { $method = $value  ;};

    return $method;
}

sub printImage
{
    # print image to file
    my $gif1;
    my $gif2;
    my $filenamegif1;
    my $filenamegif2;
    my $graphline1;
    my $graphline2;
    my $png   = $_[0]; # png image
    my $title = $_[1]; # filter
    my $first = $_[2]; # filter value (key)

       if ($_[3]) { $gif1         = $_[3]; } else { $gif1       = ""; };#print "GIF1 NOT DEFINED\n"; }; # gif1 image
       if ($_[4]) { $gif2         = $_[4]; } else { $gif2       = ""; };#print "GIF2 NOT DEFINED\n"; }; # gif2 image
       if ($_[5]) { $graphline1   = $_[5]; } else { $graphline1 = ""; };#print "GRAPHLINE1 NOT DEFINED\n"; }; # graph1 textmode
       if ($_[6]) { $graphline2   = $_[6]; } else { $graphline2 = ""; };#print "GRAPHLINE2 NOT DEFINED\n"; }; # graph2 textmode

    my $filename     = $titleFile . "_" . $title . "_" . $first . ".png";
       $filenamegif1 = $titleFile . "_" . $title . "_" . $first . "_1.gif" if ($gif1);
       $filenamegif2 = $titleFile . "_" . $title . "_" . $first . "_2.gif" if ($gif2);

    my $folder = "$titleFile\/$title";

    &checkdir("$wwwfolder\/$titleFile");    #check for main folder
    &checkdir("$wwwfolder\/$folder");   #check for specific subfolder

    my $name = "$wwwfolder\/$folder\/$titleFile" . "_" . $title . "_" . $first . "_1.txt";
    open FILE, ">$name"  or die "COULD NOT OPEN $name (GRAPHIC_plotGraph_001): $!";
    print FILE $graphline1;
    close FILE;

    $name    = "$wwwfolder\/$folder\/$titleFile" . "_" . $title . "_" . $first . "_2.txt";
    open FILE, ">$name"  or die "COULD NOT OPEN $name (GRAPHIC_plotGraph_002): $!";
    print FILE $graphline2;
    close FILE;


    if ($gif1) # if gif1 defined, print it to actual file
    {
        open(IMG, ">$wwwfolder\/$folder\/$filenamegif1") or die "CANNOT SAVE GIF $wwwfolder\/$folder\/$filenamegif1 (GRAPHIC_printImage_003): $!";
        binmode IMG;
        print IMG $gif1;
        close IMG;
    };

    if ($gif2) # if gif2 defined, print it to actual file
    {
        open(IMG, ">$wwwfolder\/$folder\/$filenamegif2") or die "CANNOT SAVE GIF2 $wwwfolder\/$folder\/$filenamegif2 (GRAPHIC_printImage_004): $!";
        binmode IMG;
        print IMG $gif2;
        close IMG;
    };

    my $pngShortFileName   = "$folder\/$filename"; #png filename short
    my $pngFileName        = "$wwwfolder\/$pngShortFileName"; # png full filename
    open(IMG, ">$pngFileName") or die "CANNOT SAVE PNG $pngFileName (GRAPHIC_printImage_005): $!";
    binmode IMG;
    print IMG $png;
    close IMG;
}

############################################
####        SERVICES        ####
############################################
sub checkdir
{
    my $dir = $_[0];

    if (!(-d $dir)) # check the existence of temporary directory
    {
        mkdir("$dir",0777); #create otherwise
    };
};

sub loadretrieve
{
    my $ref  = $_[0];

    if (ref($ref) eq "HASH") # if hash
    {
        %{$ref} = %{retrieve("$input")};
    }
    elsif (ref($ref) eq "ARRAY") # if array
    {
        @{$ref} = @{retrieve("$input")};
    };
};

# sub savestore
# {
#   my $ref  = $_[0];
#   store $ref, "output.dump";
# };

sub savedump
{
    my $ref  = $_[0]; #reference
    my $name = $_[1]; #name of variable to save
    my $d = Data::Dumper->new([$ref],["*$name"]);

    $d->Purity   (1);     # better eval
#   $d->Terse    (0);     # avoid name when possible
    $d->Indent   (3);     # identation
    $d->Useqq    (1);     # use quotes 
    $d->Deepcopy (1);     # enable deep copy, no references
    $d->Quotekeys(1);     # clear code
    $d->Sortkeys (1);     # sort keys
    $d->Varname  ($name); # name of variable
#   open (DUMP, ">".$prefix."_dump_".$name.".dump") or die "Cant save $name.dump file: $!\n";
    print $d->Dump;
#   close DUMP;
};

# sub loadConf
# {
#   open (CONFIG,"/bio/config") or die "COULD NOT OPEN /bio/config (GRAPHIC_LOADCONF_001): $!";
#   while (<CONFIG>)
#   {
#       chomp;                  # no newline
#       s/#.*//;                # no comments
#       s/^\s+//;               # no leading white
#       s/\s+$//;               # no trailing white
#       next unless length;     # anything left?
#       if (/(\S+)\s+\=\s+(\S+)/)
#       {
#           $pref{$1} = $2;
#       };
#   };
# };

1;