FILE=$1
WORD=$2

#LENGTH=`wc -l ${FILE} | gawk '{print $1}'`
FIRSTAPP=`cat -n ${FILE} | grep -E "${WORD}" | gawk '{print $1}' | head -1`
MINUS=$(($FIRSTAPP - 1))
echo "FILE     $FILE"
echo "WORD     $WORD"
#echo "LENGTH   $LENGTH"
echo "FIRSTAPP $FIRSTAPP"
echo "MINUS    $MINUS"

head -$MINUS ${FILE}
