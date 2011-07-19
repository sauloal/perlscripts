FASTA="original/cbs7750_DE_NOVO_LAST.fasta"
CPD="./auto/queryPrimerDesignTool.pl"
PT="./auto/primerTest.pl"
EPCR="./ePCR.pl"

function makeit
{
 DIR=$1
 #rm -rf $DIR
 #cd $DIR
 find -L $DIR -name '*.fasta.consensus.fasta' -exec $CPD {} $FASTA \;;
# find -L $DIR -name '*.fasta.consensus.fasta' -exec $PT {} $FASTA \;;
# find -L $DIR -name '*.fasta.consensus.fasta' -exec $EPCR {} $FASTA \;;
 cd ..
}

./copyConsensus.sh

#makeit Top17None01
makeit Top17None02
#makeit Top17None03
#makeit Top48None
#makeit Top82None

