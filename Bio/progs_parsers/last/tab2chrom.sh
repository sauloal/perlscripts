#!/bin/bash

FILE=$1

echo "PARSING $FILE"
rm $FILE.* 2>/dev/null
CMD="cat $FILE | perl -nae '\`echo -n \"\$_\" >> $FILE.\$F[1].tab\`'"
echo $CMD
#eval $CMD
CMD="cat $FILE | perl -nae '\`echo -n \"\$_\" >> $FILE.\$F[6].tab\`'"
echo $CMD
#eval $CMD
CMD="ls $FILE.*.tab | xargs -I {} -n 1 scripts/last-dotplot.py {} {}.png"
echo $CMD
#eval $CMD

#0      1                                                       2       3      4     5          6       7      8     9     10           11       12
#195	supercontig_1.03_of_Cryptococcus_neoformans_Serotype_B	1248328	195	   +	 1406049	C81731	0	   195	 -	   195	        195	     4.07e-79
#start  refname                                                 start   length frame totalLeng  qryName start length frame totalLength  bitscore prob
#supercontig_1.01_of_Cryptococcus_neoformans_Serotype_B	+	165297	166888	DeNovo2_DUP_165297_166888_1591	DeNovo2_DUP_165297_166888_1591	rna

echo "#CHROM	FRAME	START	END	UNIQ NAME	NAME	TYPE" > $FILE.tab
PRINC=$FILE
PRINC=${PRINC%%.*}
PRINC=${PRINC##*/}
CHROM="\$F[1]"
FRAME="\$F[9]"
START='" .  $F[2]        . "'
END='"   . ($F[2]+$F[3]) . "'
QEND='"  . ($F[7]+$F[8]) . "'
UNIQ="DeNovo2_\$F[6]_"$START"_"$END"_\$F[7]_"$QEND"_"$PRINC
NAME="DeNovo2_\$F[6]_\$F[7]_"$QEND"_\$F[12]_"$PRINC
TYPE='rna'
DESC="DeNovo2 \$F[6] S:\$F[7] E:"$QEND" P:\$F[12] :: "$PRINC
FORMULA=$CHROM"\t"$FRAME"\t"$START"\t"$END"\t"$UNIQ"\t"$NAME"\t"$TYPE"\t"$DESC
CMD="cat $FILE | perl -nae 'print \"$FORMULA\n\"' >> $FILE.tab "
echo $CMD
eval $CMD
