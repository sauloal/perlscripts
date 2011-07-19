STFILE=$1
STNAME=$2
STDB=$3

NDFILE=$4
NDNAME=$5
NDDB=$6

mkdir db  2>/dev/null
mkdir xml 2>/dev/null

makeblastdb -in ${STFILE} -dbtype nucl -title "${STNAME}" -out db/${STDB}
makeblastdb -in ${NDFILE} -dbtype nucl -title "${NDNAME}" -out db/${NDDB}

blastn -task blastn -db db/${STDB} -query ${NDFILE} -out ${NDDB}_vs_${STDB}.blast -num_threads 6
blastn -task blastn -db db/${NDDB} -query ${STFILE} -out ${STDB}_vs_${NDDB}.blast -num_threads 6 

./blast_xml.pl ${NDDB}_vs_${STDB}.blast
./blast_xml.pl ${STDB}_vs_${NDDB}.blast

