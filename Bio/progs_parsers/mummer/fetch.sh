NAME=$1;
#TOTAL=$2;
TOTAL=`cat seqs/$NAME.fasta | grep ">" | wc -l`

CCENT=0;
COUNT=1;

while [[ $COUNT -le $TOTAL ]]; do 
  echo "$COUNT / $TOTAL :: ./run.sh $COUNT $NAME";
 ./run.sh $COUNT $NAME;
  let COUNT=COUNT+1;
done














#COUNTER=1;while [ $COUNTER -lt $TEEN ]; do ./run.sh 0$COUNTER $NAME; let COUNTER=COUNTER+1; done
#COUNTER=0;while [ $COUNTER -lt $TWEN ]; do ./run.sh 1$COUNTER $NAME; let COUNTER=COUNTER+1; done
#COUNTER=0;while [ $COUNTER -lt $THRT ]; do ./run.sh 2$COUNTER $NAME; let COUNTER=COUNTER+1; done

# CCENT=0;
# COUNT=0;
# 
# while [[ $(($CCENT*100)) -le $TOTAL ]]; do 
#   CDEC=0;
#   while [[ $CDEC -le 9 ]]; do 
#     CUNI=0;
#     while [[ $CUNI -le 9 ]]; do 
#       if [[ $COUNT -le $TOTAL ]] && [[ $COUNT -gt 0 ]]; then
#         if [ $COUNT -lt 100 ]; then
#            echo "./run.sh $CDEC$CUNI $NAME";
#            ./run.sh $CDEC$CUNI $NAME;
#         fi
#         if [ $COUNT -ge 100 ]; then
#            echo "./run.sh $CCENT$CDEC$CUNI $NAME";
#            ./run.sh $CCENT$CDEC$CUNI $NAME;
#         fi
#       fi
#       let CUNI=CUNI+1;
#       #echo "UNI $CUNI";
#       let COUNT=COUNT+1;
#     done
#     let CDEC=CDEC+1;
# #    echo "DEC $CDEC";
#   done
#   let CCENT=CCENT+1;
# #  echo "CENT $CCENT";
# done

