INCSV=$1 #Microarray_may_r265_data.csv
INFAS=$2 #cbs7750v4.fasta
DBNAM=$3 #cbs7750
DBTIT=$4 #Cryptococcus gattii CBS7750v4


#INCSV="Microarray_may_r265_data.csv"
#INFAS="cbs7750v4.fasta"
#DBNAM="cbs7750"
#DBTIT="Cryptococcus gattii CBS7750v4"

INCSV="Microarray_may_r265_data.csv"
INFAS="R265_c_neoformans.fasta"
DBNAM="r265"
DBTIT="Cryptococcus gattii R265"

#./tab2xml.pl         $INCSV
#./merge_exp_fasta.pl $INCSV.xml

mkdir db    2>/dev/null
mkdir blast 2>/dev/null

#makeblastdb -in $INFAS -dbtype nucl -title "${DBTIT}" -out db/$DBNAM
echo RUNNING BLAST
blastn -task blastn -db db/$DBNAM -query $INCSV.xml.fasta     -out blast/$INCSV.xml.blast     -num_threads 6 -evalue 0.001  -gapopen 0 -gapextend 4 -penalty -2 -reward 2  -word_size 10
blastn -task blastn -db db/$DBNAM -query $INCSV.xml.all.fasta -out blast/$INCSV.xml.all.blast -num_threads 6 -evalue 0.001  -gapopen 0 -gapextend 4 -penalty -2 -reward 2  -word_size 10

echo IMPORTING DATA
./blast_microarray_xml.pl blast/$INCSV.xml.blast
./blast_microarray_xml.pl blast/$INCSV.xml.all.blast
echo COMPLETE
