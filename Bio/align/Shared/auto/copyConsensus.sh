BASE="/home/saulo/Desktop/blast/Ferry_Genome" 
function makeit
{
 DIR=$1
 #rm -rf $DIR
 mkdir $DIR 2>/dev/null
 cd $DIR
 find -L $BASE/$DIR -name '*.fasta.consensus.fasta' -exec ln -f -s {} . \;; 
 cd ..
}

makeit Top17None01
makeit Top17None02
makeit Top17None03
makeit Top48None
makeit Top82None

