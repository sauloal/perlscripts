INFILE=$1

cat $INFILE | perl -MSet::IntSpan -ne ' BEGIN {$interval = Set::IntSpan->new() } END { print $interval->run_list, "\n" } if ((/(\d+)\s+(\d+)/) && ( $2 < 20 )) { $interval->insert($1) }'
