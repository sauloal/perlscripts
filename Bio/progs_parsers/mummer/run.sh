NUMBER=$1
EXP=$2
PREFIX=ref_qry
COUNT=$NUMBER\_q
REF=seqs/c_neo_r265.fasta 
#REF=seqs/cryptococcus_neoformans_serotype_b_1_supercontigs$NUMBER.fasta 
#QUERY=seqs/cryptococcus_neoformans_serotype_b_1_supercontigs$NUMBER.fasta 
#QUERY=seqs/consensusr4$NUMBER.fasta
QUERY=seqs/$EXP/$EXP$NUMBER.fasta
NAME=$COUNT\_$PREFIX
OUTFOLDER=out/$EXP/$NAME/
PREFIX=$OUTFOLDER$NAME
REFT=`head -n 1 $REF | awk 'sub("^.","")'`
QRYT=`head -n 1 $QUERY | awk 'sub("^.","")'`
echo $PREFIX
mkdir out/$EXP/
mkdir $OUTFOLDER
# mkdir $OUTFOLDER/$NAME

./nucmer --prefix=$PREFIX $REF $QUERY
./delta-filter -r -q $PREFIX.delta > $PREFIX\_filter.delta 
./show-coords -rcl $PREFIX.delta > $PREFIX.coords
./show-coords -rcl $PREFIX\_filter.delta > $PREFIX\_filter.coords
./mummerplot -l -S --large $PREFIX.delta -R $REF -Q $QUERY --filter --layout -p $PREFIX --png
./mummerplot -l -S --large $PREFIX\_filter.delta -R $REF -Q $QUERY --filter --layout -p $PREFIX\_filter --png
./show-aligns $PREFIX.delta $REFT $QRYT > $PREFIX.aligns
./show-tiling $PREFIX.delta > $PREFIX.tiling
#./show-snps -Clr $PREFIX.delta > $PREFIX.snps
./show-snps -lr $PREFIX.delta > $PREFIX.snps

./mapview $PREFIX.coords -m 2.0 -p $NAME -x1 500 -x2 500 -I -Ir
./mapview $PREFIX.coords -m 2.0 -p $NAME -x1 500 -x2 500 -I -Ir -f pdf


FIGFOLDER=$OUTFOLDER$NAME\_FIG
PDFFOLDER=$OUTFOLDER$NAME\_PDF

mkdir $FIGFOLDER
mkdir $PDFFOLDER
mv *.fig $FIGFOLDER
mv *.pdf $PDFFOLDER



DATABASES=( $(ls $FIGFOLDER/*.fig) )

DATABASES=(${DATABASES[@]#$FIGFOLDER/})
DATABASES=(${DATABASES[@]%.fig})


for element in $(seq 0 $((${#DATABASES[@]} -1)))
 do
   BASENAME=${DATABASES[$element]}
   echo $BASENAME
   fig2dev -L jpeg -q 100 $FIGFOLDER/$BASENAME.fig > $FIGFOLDER/$BASENAME.jpg
   fig2dev -L png $FIGFOLDER/$BASENAME.fig > $FIGFOLDER/$BASENAME.png
#   fig2dev -L pdf -l 1 -z A4 -F -c $FIGFOLDER/$BASENAME.fig > $FIGFOLDER/$BASENAME.pdf
   rm $FIGFOLDER/$BASENAME.fig
done

