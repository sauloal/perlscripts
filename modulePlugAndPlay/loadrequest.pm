my %availModules = &loadRequests;

sub loadRequests
{
    my @files;
    find (sub { push (@files, "$File::Find::name$/") if (( $_ =~ /(.*)\.pm$/i ) && ( $File::Find::dir eq "$here/progs" )) }, "$here/progs");
    # lists all pm files under ./progs dir

    map { chomp } @files;
    Log(join("\n", @files));
#   print @files;

    my %availModules;

    foreach my $file (@files)
    {
        (my $name, my $path, my $suffix) = fileparse($file, (".pm"));
        if ($verbose >= 3) { print "NAME: $name PATH $path SUFFIX $suffix"; };

        my $lib  = "$name$suffix";
        my $pack = "$name";

        eval { require $lib; }; if ($@) { die "FAILED TO LOAD $lib: $@\n"; }

        my $desc = "\$desc \= \$$name\:\:DESCRIPTION";
        eval $desc;  if ($@) { die "FAILED TO GET DESCRIPTION OF MODULE $lib: $@\n"; }
        # http://www.grohol.com/downloads/pod/latest/servertest.txt
        # http://perldoc.perl.org/functions/eval.html
        $availModules{$name} = $desc;
    }

    $availModules{"list"} = "List all available modules.";

    return %availModules;
}