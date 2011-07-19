#!/usr/bin/perl -w
# Saulo Aflitos
# 2009 09 16 20 49
# 2009 09 15 16 07
# 2010 03 17 15 50
# 2010 08 16 21 04
# 2010 10 15 16 35
use warnings;
use strict;
package loadconf;
use Cwd qw(realpath);
use File::Basename;

my $print    = 0;

if (0)
{
    my $fullpath = "/home/saulo/Desktop/blast/cgh";
    my $config   = "$fullpath/config.xml";

    print "USING COMMAND LINE: $fullpath\n";


    $print    = 1;
    #$fullpath = dirname(realpath($ARGV[0]));
    $config   = "$fullpath/" . "config.xml";
    if ($ARGV[0]) {$config = $ARGV[0]};
    #&loadConf($config);
    &loadConf($config);
}

######################
#USAGE:
######################
# **** SCRIPT ****
# use loadconf;
# my %pref = &loadconf::loadConf;
#
# my $wwwfolder   = $pref{"htmlPath"}; # http folder
# my $renice      = $pref{"reniceGraphic"};     # renice process (increase priority - needs SUDO)
# my $minscore    = $pref{"minscore"};
#&loadconf::checkNeeds(
#       'blast.evalue',
#       'blast.threads',
#       'blast.task',
#       'blast.identity',
#       'blast.desc',
#   );

# **** CONFIG FILE ****
#<xml>
#   <inFiles>CNA_probes</inFiles>
#<!-- <inFiles>CNA_probes</inFiles> -->
#   <expression>ORIGINAL_DATA_FINAL.txt.xml</expression>
#
#   <db>
#       <db0>
#           <fileName>Cryptococcus_gattii_R265_CHROMOSSOMES.fasta                       </fileName>
#           <dbName>  cgR265                                                            </dbName>
#           <title>   Cryptococcus gattii R265                                          </title>
#           <taxId>   294750                                                            </taxId>
#       </db0>
#   </db>
#   <blast>         1 </blast>
#   <blast>
#       <doAlias>                0      </doAlias>
#       <doShort>                0      </doShort>
#       <doShort>
#           <gapOpen>            2      </gapOpen>
#           <gapExtend>          2      </gapExtend>
#       </doShort>
#       <evalue>                10          </evalue>
#   </blast>
#</xml>
#

#******* hash output **********
#blast => "1"
#blast.desc => "EVALUE 10 TASK blastn IDENTITY 50"
#blast.doAlias => "0"
#blast.doShort => "0"
#blast.doShort.gapExtend => "2"
#blast.doShort.gapOpen => "2"
#blast.evalue => "10"
#db.db0.dbName => "cgR265"
#db.db0.fileName => "Cryptococcus_gattii_R265_CHROMOSSOMES.fasta"
#db.db0.taxId => "294750"
#db.db0.title => "Cryptococcus gattii R265"
#expression => "ORIGINAL_DATA_FINAL.txt.xml"
#inFiles => "CNA_probes"



# **** PROCESS ****
# 01. reads a xml file named "config.xml" in the current directory of the calling script line per line
# 02. trim everythig between <!-- -->. multiline
# 03. trim every consecutive Spaces in the begining and end
# 04. gets everything between two identical tags (<tag></tag>)
# 05. trim every consecutive Spaces in the begining and end of the value
# 06. if value has a empty tag <tag/> which tag name has been already loaded, replace it by it's value
# 07. if the value is "" '' or undef, replace it by empty string or undef


sub loadConf
{
    my $config = $_[0];
    die "NO CONFIG FILE DEFINED" if ! $config;
    my %pref;

    open (CONFIG,"<$config") or die "FILE $config NOT FOUND: $!";
    print "LOADING FILE $config...\n" if $print;
    my $whole_file;
    {
        local $/;
        $whole_file = <CONFIG>;
        $whole_file =~ s/\<\!\-\-.*?\-\-\>//gs;  # no comments
        $whole_file =~ s/\n//gs;                 # no lines
        $whole_file =~ s/\r//gs;                 # no lines
        $whole_file =~ s/\t+//gs;                 # no lines
        #print $whole_file if $print;
    }
    close(CONFIG);
    print "LOADING FILE $config...DONE\n" if $print;

    print "PARSING $config...\n" if $print;
    &parse(\$whole_file, \%pref);
    print "PARSING $config...DONE\n" if $print;

    print "DEREFERENCING $config...\n" if $print;
    &dereference(\%pref);
    print "DEREFERENCING $config...DONE\n" if $print;

    if ($print)
    {
        foreach my $key (sort keys %pref)
        {
            if (defined $pref{$key})
            {
                print "\t$config :: $key => \"" . $pref{$key} . "\"\n" if $print;
                if (ref($pref{$key}) eq "ARRAY")
                {
                    print "\t=> \"" . join("+", @{$pref{$key}}) . "\"\n" if $print;
                }

            }
            else
            {
                print "$key => <undef>\n";
            }
        }
    }

    return %pref;
};



sub parse
{
    my $str  = $_[0] || die;
    my $hash = $_[1];

    my $keys     = &getCov('', $str, 0);

    for (my $k = 0; $k < @$keys; $k++)
    {
        my $ke = $keys->[$k]->[0];
        my $va = $keys->[$k]->[1];
        #print "K $k KEY $ke VALUE $va\n";
        $hash->{$ke} = $va;
    }
}


sub getCov
{
    my $parent   = $_[0];
    my $str      = $_[1];
    my $startPos = $_[2];
    my $depth    = $_[3] || 1;
    my @keys;

    my $printParsing = 0;
    if (index($$str, "<") == -1)
    {
        print "\t"x($depth-1), "GET COVERAGE :: PARENT: $parent STARTPOS: $startPos LENGTH: ",length($$str)," DEPTH: $depth :: INVALID STR\n" if $printParsing;
        return [];
    };

    print "\t"x($depth-1), "GET COVERAGE :: PARENT: $parent STARTPOS: $startPos LENGTH: ",length($$str)," DEPTH: $depth\n" if $printParsing;
    my $countTitle = 0;

    for (my $p = $startPos; $p < length($$str);)
    {
        my $bracOpen    = index($$str, "<", $p);
        my $bracClose   = index($$str, ">", $bracOpen);

        last if (($bracOpen == -1) || ($bracClose == -1));
        last if ($bracClose == index($$str, "/>", $bracOpen) + 1);

        my $title       = substr($$str, $bracOpen+1, ($bracClose-$bracOpen - 1));
        my $tagClosePos = index($$str, "</$title>", $bracClose);

        my $lastTitlePos = index($$str, "<$title>", $bracClose);

        while ( ( $lastTitlePos != -1 ) && ( index($$str, "<$title>", $lastTitlePos) < $tagClosePos ) )
        {
            print "WHILING :: LASTTITLEPOS $lastTitlePos TAGCLOSEPOS $tagClosePos\n" if $printParsing;
            $tagClosePos  = index($$str, "</$title>", $tagClosePos+1);
            $lastTitlePos = index($$str, "<$title>",  $lastTitlePos+1);
        }

        my $tagClosePie = substr($$str, $tagClosePos, 10);
        my $nfo         = substr($$str, $bracClose+1, ($tagClosePos - $bracClose - 1));

        $nfo =~ s/^\s+//gs;                 # no lines
        $nfo =~ s/\s+$//gs;                 # no lines
        print "\t"x($depth) . "P $p BRACOPEN $bracOpen BRACCLOSE $bracClose TAGCLOSEPOS $tagClosePos  TITLE \"$title\" [$tagClosePie] NFO $nfo\n" if $printParsing;

        if ($tagClosePos == -1 )
        {
            print "\t"x($depth-1), "GET COVERAGE :: PARENT: $parent STARTPOS: $startPos LENGTH: ",length($$str)," DEPTH: $depth\n";
            print "\t"x($depth),   "P $p BRACOPEN $bracOpen BRACCLOSE $bracClose TAGCLOSEPOS $tagClosePos  TITLE \"$title\" [$tagClosePie] NFO \"$nfo\"\n";
            print "\t"x($depth),   "LINE \"$$str\"\n";
            print "\t"x($depth),   "p         [", $p        , "]: \"", substr($$str, $p -1),        "\"\n";
            print "\t"x($depth),   "BRACOPEN  [", $bracOpen , "]: \"", substr($$str, $bracOpen -1), "\"\n";
            print "\t"x($depth),   "BRACCLOSE [", $bracClose, "]: \"", substr($$str, $bracOpen -1), "\"\n";
            die "NOT A VALID XML FILE AT POS $p\n" ;
        }

        if ( index($nfo, "<") != -1)
        {
            print "\t"x($depth+1), "NFO HAS BRACKETS\n" if $printParsing;
            my $sKeys = &getCov($title,\$nfo,0, $depth+1);

            if ( @$sKeys )
            {
                print "\t"x($depth+1), "VALID SON\n" if $printParsing;
                for (my $k = 0; $k < @$sKeys; $k++)
                {
                    my $sk = $sKeys->[$k]->[0];
                    my $sv = $sKeys->[$k]->[1];
                    if ( defined $sv )
                    {
                        if ($title eq "array") { $title = $parent.$countTitle++; };
                        print "\t"x($depth+1), "ADDING TITLE \"$sk\" INFO \"$sv\"\n" if $printParsing;
                        push(@keys, ["$title.$sk", $sv]);
                    } else {
                        print "\t"x($depth+1), "SKIPPINH TITLE \"$sk\" INFO \"$sv\"\n" if $printParsing;
                    }
                }
            }
            else
            {
                print "\t"x($depth+1), "INVALID SON\n" if $printParsing;
                if ( defined $nfo )
                {
                    print "\t"x($depth+1), "ADDING TITLE \"$title\" INFO \"$nfo\"\n" if $printParsing;
                    if ($title eq "array") { $title = $parent.$countTitle++; };
                    push(@keys, [$title, $nfo]);
                } else {
                    print "\t"x($depth+1), "SKIPPING TITLE \"$title\" INFO \"$nfo\" :: NFO NOT DEFINED\n" if $printParsing;
                }
            }
        }
        else
        {
            print "\t"x($depth+1), "NFO HAS NO BRACKETS\n" if $printParsing;
            if ( defined $nfo )
            {
                print "\t"x($depth+1), "ADDING TITLE \"$title\" INFO \"$nfo\"\n" if $printParsing;
                if ($title eq "array") { $title = $parent.$countTitle++; };
                push(@keys, [$title, $nfo]);
            } else {
                print "\t"x($depth+1), "SKIPPING TITLE \"$title\" INFO \"$nfo\"\n" if $printParsing;
            }
        }
        $p = $tagClosePos + length($title);
    }

    if ( $printParsing )
    {
         map { print join("\t", @$_), "\n" } @keys;
        print "\n";
    }

    return \@keys;
}

sub dereference
{
    my $hash = $_[0];
    my %newHash;

    foreach my $key (keys %$hash)
    {
        my $value = $hash->{$key};
        my $nKey = substr($key,index($key,".")+1);
        #print "KEY $key NKEY $nKey\n";
        $newHash{$nKey} = $value;
    }

    foreach my $key (keys %newHash)
    {
        my $value = $newHash{$key};
        while ($value =~ m/\<(.*?)\/\>/g)
        {
            my $sub = $1;

            if (exists $newHash{$sub})
            {
                my $subV = $newHash{$sub};
                #print "SUB : $sub\n";
                $value =~ s/\<$sub\/\>/$subV/;
            }
            else
            {
                #print "NOT SUB : $sub\n";
            }
        }

        if    ($value eq "undef") { $value = undef; }
        elsif ($value eq "\"\"")  { $value = "";    }
        elsif ($value eq "\'\'")  { $value = '';    }
        elsif ($value eq '')      { $value = '';    }
        elsif ( ! defined $value) { $value = undef; }

        $newHash{$key} = $value;
    }

    %{$hash} = %newHash;
}












sub loadConfOriginal
{
    my $config = $_[0];
    die "NO CONFIG FILE DEFINED" if ! $config;
    my %pref;

    open (CONFIG,"<$config") or die "FILE $config NOT FOUND: $!";
    print "LOADING FILE..." if $print;
    my $whole_file;
    {
        local $/;
        $whole_file = <CONFIG>;
        $whole_file =~ s/\<\!\-\-.*?\-\-\>//gs;  # no comments
    }
    close(CONFIG);
    print "DONE\n" if $print;

    print "PARSING...\n" if $print;
    foreach my $line (split("\n", $whole_file))
    {
        chomp $line;                  # no newline

        $line =~ s/^\s+//;               # no leading white
        $line =~ s/\s+$//;               # no trailing white
        next unless length($line);     # anything left?
        print "PARSING LINE... $line\n" if $print;

        if ($line =~ /\<(.*)\>(.*)\<\/\1\>/)
        {
            my $key   = $1;
            my $value = $2;
            $key   =~ s/^\s+//; # no leading white
            $key   =~ s/\s+$//; # no trailing white
            $value =~ s/^\s+//; # no leading white
            $value =~ s/\s+$//; # no trailing white

            #print "KEY $key > $value\n";
            $pref{$key} = $value;
        }
        elsif (($line) && ( ! $line =~ /xml\>/))
        {
            print "NOT PARSED: ", $_, "\n";
        };
    };

    foreach my $key (keys %pref)
    {
        my $value = $pref{$key};

        while ($value =~ m/\<(.*?)\/\>/g)
        {
            my $sub = $1;

            if (exists $pref{$sub})
            {
                #print "SUB : $sub\n";
                $value =~ s/\<$sub\/\>/$pref{$sub}/;
            }
            else
            {
                #print "NOT SUB : $sub\n";
            }
        }


        if    ($value eq "undef") { $value = undef; }
        elsif ($value eq "\"\"")  { $value = "";    }
        elsif ($value eq "\'\'")  { $value = '';    }
        elsif ($value eq '')      { $value = '';    }
        elsif ( ! defined $value) { $value = undef; }


        $pref{$key} = $value;
    } # end foreach my key

    if ($print)
    {
        foreach my $key (sort keys %pref)
        {
            if (defined $pref{$key})
            {
                print "$key => " . $pref{$key} . "\n";
                if (ref($pref{$key}) eq "ARRAY")
                {
                    print "\t=> " . join("+", @{$pref{$key}}) . "\n";
                }

            }
            else
            {
                print "$key => <undef>\n";
            }
        }
    }

    return %pref;
};

sub checkNeeds
{
    my $config = $_[0];
    my %pref   = defined $_[1] ? %{$_[1]} : {};

    die "NO CONFIG FILE DEFINED" if ! $config;

    if ( ! %pref)
    {
        %pref = &loadConf($config);
    }

    for my $need (@_)
    {
        if ( ! exists $pref{$need})
        {
            die "CONFIG $need NOT FOUND";
        };
    }

    #print "NEEDS MET\n";
}

1;