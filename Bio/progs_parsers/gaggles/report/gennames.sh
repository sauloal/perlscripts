OUTNAME=$1
#reset;

rm $OUTNAME.GENES.csv 2>/dev/null
find -L . -mindepth 2 -name \*.tab -print0 | grep -Evz "FANTHASTIC|maf|AIDS" | xargs -0 head -n 100000 | grep -Ev "GAP|QUALITY|DEL|exon_|GE_Cneo|SNP|FREQ|CDS_|INS|NO_DATA|DeNovo|#" >> $OUTNAME.GENES.csv
#find -L . -mindepth 2 -name \*.tab -print0 | grep -Evz "FANTHASTIC|maf|AIDS" | xargs -0 cat | grep -Ev "GAP|QUALITY|DEL|exon_|GE_Cneo|SNP|FREQ|CDS_|INS|NO_DATA|DeNovo|#" >> $OUTNAME.GENES.csv

rm $OUTNAME.REGIO.csv 2>/dev/null
find -L . -mindepth 2 -name \*.tab -print0 | grep -Evz "FANTHASTIC|maf|AIDS" | xargs -n 1 -0 ../getRegio.sh >> $OUTNAME.REGIO.csv

#find -L . -mindepth 2 -name \*.tab -print0 | grep -Evz "FANTHASTIC|maf|AIDS" | xargs -0 head -n 100000 | grep -Ev "GAP|QUALITY|DEL|exon_|GE_Cneo|SNP|FREQ|CDS_|INS|NO_DATA|DeNovo|#"
