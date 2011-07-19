FILE=$1

FOLDER=`dirname "${FILE}"`
FOLDER=${FOLDER##"./"}
export FOLDER
export FILE

#echo "RUNNING WITH ${FILE} FROM FOLDER ${FOLDER}"

cat "${FILE}" | grep -v "#" | perl -ane 'BEGIN {$folder = $ENV{"FOLDER"}; $file = $ENV{"FILE"}; $chrom; $max = -1; $min = 1_000_000_000; print "==> $file <==\n"; } END { print "$chrom\t$min\t$max\tnone\t$folder\n\n" }  if ( $F[2] < $F[3] ) { $chrom = $F[0]; $min = $F[2] if ( $F[2] < $min ); $max = $F[3] if $F[3] > $max; }'
