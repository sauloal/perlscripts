package loadconf;

require Exporter;

@ISA       = qw{Exporter};
@EXPORT_OK = qw{new get checkNeeds};

use warnings;
use strict;

sub new
{
    
    my $print    = 0;

    my $class = shift;
    my $self = bless {}, $class;

    my %vars  = @_;

    my $config = exists $vars{config} ? $vars{config} : 'config.xml';

    open (CONFIG,"<$config") or die "FILE $config NOT FOUND";

    print "LOADING FILE..." if $print;
    my $whole_file;
    {
        local $/;
        $whole_file = <CONFIG>;
        $whole_file =~ s/\<\!\-\-.*?\-\-\>//gs;  # no comments
        $whole_file =~ s/\n//gs;                 # no lines
        $whole_file =~ s/\r//gs;                 # no lines
        $whole_file =~ s/\t+//gs;                 # no lines
    }
    close(CONFIG);
    print "DONE\n" if $print;

    print "PARSING...\n" if $print;

    &parse(\$whole_file, $self);

    foreach my $key (keys %$self)
    {
        my $value = $self->{$key};
        my $nKey = substr($key,index($key,".")+1);
        #print "KEY $key NKEY $nKey\n";
        delete $self->{$key};
        $self->{$nKey} = $value;
    }

    while ( &dereference($self) ) { };

    if ($print)
    {
        foreach my $key (sort keys %$self)
        {
            if (defined $self->{$key})
            {
                print "$key => \"" . $self->{$key} . "\"\n";
                if (ref($self->{$key}) eq "ARRAY")
                {
                    print "\t=> \"" . join("+", @{$self->{$key}}) . "\"\n";
                }
            }
            else
            {
                print "$key => <undef>\n";
            }
        }
    }

    return $self;
};

sub get
{
    my $self = shift;
    my $req  = $_[0];
    return $self->{$req};
}


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
    return;
}


sub getCov
{
    my $parent   = $_[0];
    my $str      = $_[1];
    my $startPos = $_[2];
    my $depth    = $_[3] || 1;
    my @keys;
    return [] if (index($$str, "<") == -1);

    #print "\t"x($depth-1), "GET COVERAGE :: PARENT: $parent STARTPOS: $startPos LENGTH: ",length($$str)," DEPTH: $depth\n";
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
            #print "WHILING :: LASTTITLEPOS $lastTitlePos TAGCLOSEPOS $tagClosePos\n";
            $tagClosePos  = index($$str, "</$title>", $tagClosePos+1);
            $lastTitlePos = index($$str, "<$title>",  $lastTitlePos+1);
        }

        my $tagClosePie = substr($$str, $tagClosePos, 10);
        my $nfo         = substr($$str, $bracClose+1, ($tagClosePos - $bracClose - 1));

        $nfo =~ s/^\s+//gs;                 # no lines
        $nfo =~ s/\s+$//gs;                 # no lines
        #print "\t"x($depth) . "P $p BRACOPEN $bracOpen BRACCLOSE $bracClose TAGCLOSEPOS $tagClosePos  TITLE \"$title\" [$tagClosePie] NFO $nfo\n";

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
            my $sKeys = &getCov($title,\$nfo,0, $depth+1);

            if ( @$sKeys )
            {
                #print "\t"x($depth+1), "HAS SON\n";
                for (my $k = 0; $k < @$sKeys; $k++)
                {
                    my $sk = $sKeys->[$k]->[0];
                    my $sv = $sKeys->[$k]->[1];

                    if ($title eq "array") { $title = $parent.$countTitle++; };

                    push(@keys, ["$title.$sk", $sv]);
                }
            }
            else
            {
                if ($title eq "array") { $title = $parent.$countTitle++; };
                push(@keys, [$title, $nfo]);
            }
        }
        else
        {
            if ($title eq "array") { $title = $parent.$countTitle++; };
            push(@keys, [$title, $nfo]);
        }
        $p = $tagClosePos + length($title);
    }

    return \@keys;
}

sub dereference
{
    my $hash     = $_[0];
    my $countDef = 0;

    foreach my $key (keys %$hash)
    {
        my $value  = $hash->{$key};
        my $dotted = 0;
        while ($value =~ m/\<((.+?)(\.*))\/\>/g)
        {
            #print "VALUE $value HAS LINK\n";
            my $all = $1;
            my $sub = $2;
            my $dot = $3;
            #print "  ALL '$1' SUB '$2' DOT '$3'\n";

            if ( $dot )
            {
                #print "  VALUE $value HAS DOT\n\n";
                $dotted = 1;
                foreach my $lkey ( sort keys %$hash )
                {
                    if ( $lkey =~ /^$sub(.+)/ )
                    {
                        $countDef++;
                        my $subK = $1;
                        my $subV = $hash->{$lkey};
                        #$value =~ s/\<$sub\/\>/\<$subK\>$subV\<\/$subK\>/;
                        next if ( $subV =~ m/\<((.+?)(\.*))\/\>/ );
                        $hash->{"$key$subK"} = $subV;
                    }
                }
            } else {
                #print "  VALUE $value HAS NO DOT\n\n";
                if (exists ${$hash}{$sub})
                {
                    $countDef++;
                    my $subV = $hash->{$sub};
                    #print "SUB : $sub\n";
                    $value =~ s/\<$sub\/\>/$subV/g;
                }
                else
                {
                    #print "NOT SUB : $sub\n";
                }
            } #end if dot
        } #end while value

        if    ($value eq "undef") { $value = undef;	}
        elsif ($value eq "\"\"")  { $value = "";	}
        elsif ($value eq "\'\'")  { $value = '';	}
        elsif ($value eq '')      { $value = '';	}
        elsif ( ! defined $value) { $value = undef;	}
        if ( $dotted )
        {
            delete ${$hash}{$key};
        } else {
            $hash->{$key} = $value;
        }
    } # end foreach my key

    return $countDef;
}



sub checkNeeds
{
    my $self = shift;

    if ( ! scalar keys %$self )
    {
        return undef;
    }

    for my $need (@_)
    {
        if ( ! exists $self->{$need} )
        {
            print "CONFIG '$need' NOT FOUND";
            return 0;
        };
    }

    return 1;
    #print "NEEDS MET\n";
}

1;


# Saulo Aflitos
# 2009 09 15 16 07
# 2010 03 17 15 50
# 2010 11 30 00 45
#use Cwd qw(realpath);
#use File::Basename;

#if (0)
#{
#        my $fullpath = "/home/saulo/Desktop/blast/cgh";
#        my $config   = "$fullpath/config.xml";
#	print "USING COMMAND LINE: $fullpath\n";
#	$print    = 1;
#	#$fullpath = dirname(realpath($ARGV[0]));
#	$config   = "$fullpath/" . "config.xml";
#	if ($ARGV[0]) {$config = $ARGV[0]};
#	#&loadConf($config);
#	&loadConf($config);
#}

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
#		'blast.evalue',
#		'blast.threads',
#		'blast.task',
#		'blast.identity',
#		'blast.desc',
#	);

# **** CONFIG FILE ****
#<xml>
#	<inFiles>CNA_probes</inFiles>
#<!-- <inFiles>CNA_probes</inFiles> -->
#	<expression>ORIGINAL_DATA_FINAL.txt.xml</expression>
#
#	<db>
#		<db0>
#			<fileName>Cryptococcus_gattii_R265_CHROMOSSOMES.fasta						</fileName>
#			<dbName>  cgR265                                     						</dbName>
#			<title>   Cryptococcus gattii R265                   						</title>
#			<taxId>   294750                                     						</taxId>
#		</db0>
#	</db>
#	<blast>         1 </blast>
#	<blast>
#		<doAlias>  				 0 		</doAlias>
#		<doShort>				 0		</doShort>
#		<doShort>
#	 		<gapOpen>			 2		</gapOpen>
#			<gapExtend>			 2		</gapExtend>
#		</doShort>
#		<evalue>				10			</evalue>
#	</blast>
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


