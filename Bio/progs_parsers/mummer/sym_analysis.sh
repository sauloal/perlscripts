#!/bin/bash
reset
REF=$1
REFN=$2
QRY=$3
QRYN=$4
OUTDIR=$5

PERL=' perl -ne '"'"'if (/\_1\.(\d\d).+?\t.+?\_1\.\1/) { print $_ }'"'| "

function analyze
{
R=$1
Q=$2
P=$3

DNA="./dnadiff ${R} ${Q} -p ${P}"
echo "REF ${R} QRY ${Q} PRE ${P}"
echo
echo RUNNING DNADIFF
echo "\"${DNA}\""
eval $DNA

echo
echo

COMMAN='
 cat '${P}'.delta  |
 grep ">"            |
 cut -d " " -f 1,2   |
 cut -b 2-           |
 gawk '"'"'{
   print $1"\t"$2;
  }'"'"' |
 '${PERL}'
 gawk '"'"'{
   system(
     "./show-aligns -r '${P}'.delta "$1" "$2" > '${P}'_"$1"_"$2".align"
   );
   print $1"\t"$2;
  }'"'"' |
 gawk '"'"'{
   print $1"\t"$2;
   system(
     "cat '${P}'_"$1"_"$2".align |
     grep -n -B 2 -E \"\\^\|\\-\" |
     grep -v -P \"\^\\d+\\-\$\" \> '${P}'_"$1"_"$2".align.filter"
   );
 }'"'"


echo RUNNING COMMAND
echo "\"${COMMAN}\""
eval ${COMMAN} 2>/dev/null
}

function convert
{
    FOLDER=$1
    NAME=$2
    echo "CONVERTING ${FOLDER} ${NAME}"
    ./mummer_xml_sym.pl $FOLDER $NAME

}

function usage
{
    echo "<REF FILE> <REF NAME> <QRY FILE> <QRY NAME> <OUT DIR>"
    exit 1
}




echo "REF \"${REF}\" REFNAME \"${REFN}\" QRY \"${QRY}\" QRYNAME \"${QRYN}\" OUTPUT DIR \"${OUTDIR}\""

if [ ! -e $REF ]; then
    echo "REF FILE ${REF} DOESNT EXISTS"
    usage
fi

if [ ! -e $QRY ]; then
    echo "QRY FILE ${QRY} DOESNT EXISTS"
    usage
fi

if [ ! -d $OUTDIR ]; then
    echo "OUTPUT DIR ${OUTDIR} DOESNT EXISTS"
    usage
fi

if [ -z $REFN ]; then
    echo "REF NAME ${REFN} NOT DEFINED"
    usage
fi

if [ -z $QRYN ]; then
    echo "QRY NAME ${QRYN} NOT DEFINED"
    usage
fi



echo "PERL \"${PERL}\""

OUTNAME="${OUTDIR}/${REFN}_${QRYN}"
echo "OUTNAME ${OUTNAME}"
analyze $REF $QRY $OUTNAME
convert ${OUTDIR} "${REFN}_${QRYN}"

