INPUT=sequence.fastq
OUTPUT=WHOLE10
MINLENG=40


KMER=("31"             "31"             "31"             "31"             "31"             "31"             "31"             "31"             "31"             "31"             "31"             "31")
MIN=( "1"              "1"              "1"              "1"              "1"              "1"              "1"              "1"              "1"              "1"              "1"              "1")
MAX=( "20"             "20"             "20"             "20"             "20"             "20"             "20"             "20"             "20"             "20"             "20"             "20")
EXP=( "13"             "13"             "13"             "13"             "15"             "15"             "15"             "15"             "17"             "17"             "17"             "17")
DIV=( "0.20"           "0.20"           "0.33"           "0.33"           "0.20"           "0.20"           "0.33"           "0.33"           "0.20"           "0.20"           "0.33"           "0.33")
IND=( "3"              "6"              "3"              "6"              "3"              "6"              "3"              "6"              "3"              "6"              "3"              "6"   )
#MAX=("5" "17")

for element in $(seq 0 $((${#KMER[@]}-1)))
do
	LKMER=${KMER[$element]}
	LMIN=${MIN[$element]}
	LMAX=${MAX[$element]}
	LEXP=${EXP[$element]}
	LDIV=${DIV[$element]}
	LIND=${IND[$element]}
	LNAME=$LKMER\_$LMIN\_$LMAX\_$LEXP\_$LDIV\_$LIND
	echo "KMER $LKMER NAME $NAME MIN $LMIN EXP $LEXP MAX $LMAX DIV $LDIV IND $LIND NAME $LNAME"
	./velveth output$LNAME $LKMER -fastq input/$INPUT
	./velvetg output$LNAME/ -min_contig_lgth $MINLENG > output$LNAME/run.log  
#  -cov_cutoff $LMIN -exp_cov $LEXP -max_coverage $LMAX
	./r.sh output$LNAME/stats.txt $OUTPUT\_$LNAME
	mv $OUTPUT\_$LNAME.pdf output$LNAME/
done

for element in $(seq 0 $((${#KMER[@]}-1)))
do
	LKMER=${KMER[$element]}
	LMIN=${MIN[$element]}
	LMAX=${MAX[$element]}
	LEXP=${EXP[$element]}
	LDIV=${DIV[$element]}
	LIND=${IND[$element]}
	LNAME=$LKMER\_$LMIN\_$LMAX\_$LEXP\_$LDIV\_$LIND
cat output$LNAME/Log
cat output$LNAME/contigs.fa | grep -v ">" | wc -m > output$LNAME/run.log
done

tail -n 14 output*/run.log > run_output.log
cat output*/contigs.fa | grep ">" > contigs.idx

mkdir $OUTPUT
mv run_output.log $OUTPUT
mv contigs.idx $OUTPUT
mv output* $OUTPUT

