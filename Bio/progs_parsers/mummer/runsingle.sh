FOLDER=$1
FILE=$2
REF=$3
QUERY=$4
ITERATE=$5

OUTFOLDER=$FOLDER/OUT_$FILE
PREFIX=$FOLDER$FILE

echo "FOLDER \"${FOLDER}\" FILE \"${FILE}\" REF \"${REF}\" QUERY \"${QUERY}\" ITERATE \"${ITERATE}\" OUTFOLDER \"${OUTFOLDER}\" PREFIX \"${PREFIX}\""

mkdir $OUTFOLDER 2>/dev/null
cp $PREFIX* $OUTFOLDER 2>/dev/null
PREFIX=$OUTFOLDER/$FILE




if  (true) ; then
	echo "RUNNING NUCMER $REF AGAINST $QUERY"
	./nucmer --prefix=$PREFIX $REF $QUERY
	# mv out/*.delta out/nucmer
	# mv out/*.cluster out/nucmer

	echo "ANALYZING OUTPUT $PREFIX $OUTFOLDER $QUERY"

	echo "GENERATING DELTA FILE"
	# ./delta-filter -r -q $PREFIX.delta > $OUTFOLDER/$FILE\_filterRQ.delta 2>/dev/null
	./delta-filter -r    $PREFIX.delta > $OUTFOLDER/$FILE\_filterR.delta  2>/dev/null
	# ./delta-filter -q    $PREFIX.delta > $OUTFOLDER/$FILE\_filterQ.delta  2>/dev/null

	# echo "    PLOTTING DELTA"
	# ./mummerplot --layout --color --large --filter $PREFIX.delta           -R $REF -Q $QUERY --prefix $PREFIX           --png 1>/dev/null 2>/dev/null
	# echo "    PLOTTING DELTA FILTER RQ"
	# ./mummerplot --layout --color --large --filter $PREFIX\_filterRQ.delta -R $REF -Q $QUERY --prefix $PREFIX\_filterRQ --png 1>/dev/null 2>/dev/null
	echo "    PLOTTING DELTA FILTER R"
	./mummerplot --layout --color --large --filter $PREFIX\_filterR.delta  -R $REF -Q $QUERY --prefix $PREFIX\_filterR  --png 1>/dev/null 2>/dev/null
	# echo "    PLOTTING DELTA FILTER Q"
	# ./mummerplot --layout --color --large --filter $PREFIX\_filterQ.delta  -R $REF -Q $QUERY --prefix $PREFIX\_filterQ  --png 1>/dev/null 2>/dev/null

	echo "    PLOTTING DELTA SNP"
	# ./mummerplot --layout --SNP   --large --filter $PREFIX.delta           -R $REF -Q $QUERY --prefix $PREFIX\_SNP           --png 1>/dev/null 2>/dev/null
	# echo "    PLOTTING DELTA FILTER SNP RQ"
	# ./mummerplot --layout --SNP   --large --filter $PREFIX\_filterRQ.delta -R $REF -Q $QUERY --prefix $PREFIX\_SNP\_filterRQ --png 1>/dev/null 2>/dev/null
	echo "    PLOTTING DELTA FILTER SNP R"
	./mummerplot --layout --SNP   --large --filter $PREFIX\_filterR.delta  -R $REF -Q $QUERY --prefix $PREFIX\_SNP\_filterR  --png 1>/dev/null 2>/dev/null
	# echo "    PLOTTING DELTA FILTER SNP Q"
	# ./mummerplot --layout --SNP   --large --filter $PREFIX\_filterQ.delta  -R $REF -Q $QUERY --prefix $PREFIX\_SNP\_filterQ  --png 1>/dev/null 2>/dev/null

	echo "GENERATING COORDINATES FILE"
	# ./show-coords -rcl $PREFIX.delta           > $PREFIX.coords           2>/dev/null
	# ./show-coords -rcl $PREFIX\_filterRQ.delta > $PREFIX\_filterRQ.coords 2>/dev/null
	./show-coords -rcl $PREFIX\_filterR.delta  > $PREFIX\_filterR.coords  2>/dev/null
	# ./show-coords -rcl $PREFIX\_filterQ.delta  > $PREFIX\_filterQ.coords  2>/dev/null

	# ./show-coords -rcl $PREFIX\_SNP.delta           > $PREFIX\_SNP.coords           2>/dev/null
	# ./show-coords -rcl $PREFIX\_SNP\_filterRQ.delta > $PREFIX\_SNP\_filterRQ.coords 2>/dev/null
	./show-coords -rcl $PREFIX\_SNP\_filterR.delta  > $PREFIX\_SNP\_filterR.coords  2>/dev/null
	# ./show-coords -rcl $PREFIX\_SNP\_filterQ.delta  > $PREFIX\_SNP\_filterQ.coords  2>/dev/null







	if [ $ITERATE -ne 1 ]; then
	./filter_coords.pl $PREFIX\_filterR.coords $PREFIX\_filterR.delta $PREFIX $FOLDER $FILE $REF $QUERY
	fi


	echo "    GENERATING COORDINATE MAP IMAGES"
	# ./mapview $PREFIX.coords           -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null
	# ./mapview $PREFIX\_filterRQ.coords -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null
	./mapview $PREFIX\_filterR.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null
	# ./mapview $PREFIX\_filterQ.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null

	# ./mapview $PREFIX.coords           -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null
	# ./mapview $PREFIX\_filterRQ.coords -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null
	./mapview $PREFIX\_filterR.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null
	# ./mapview $PREFIX\_filterQ.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null


	# ./mapview $PREFIX\_SNP.coords           -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null
	# ./mapview $PREFIX\_SNP\_filterRQ.coords -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null
	./mapview $PREFIX\_SNP\_filterR.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null
	# ./mapview $PREFIX\_SNP\_filterQ.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir 2>/dev/null

	# ./mapview $PREFIX\_SNP.coords           -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null
	# ./mapview $PREFIX\_SNP\_filterRQ.coords -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null
	./mapview $PREFIX\_SNP\_filterR.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null
	# ./mapview $PREFIX\_SNP\_filterQ.coords  -m 2.0 -p $PREFIX -x1 500 -x2 500 -I -Ir -f pdf 2>/dev/null

	echo "EXPORTING TILING"
	# ./show-tiling $PREFIX.delta           > $PREFIX.tiling           2>/dev/null
	# ./show-tiling $PREFIX\_filterRQ.delta > $PREFIX\_filterRQ.tiling 2>/dev/null
	./show-tiling $PREFIX\_filterR.delta  > $PREFIX\_filterR.tiling  2>/dev/null
	# ./show-tiling $PREFIX\_filterQ.delta  > $PREFIX\_filterQ.tiling  2>/dev/null
	./tilling_to_gap.pl $PREFIX\_filterR.tiling
	./coords_to_gap.pl  $PREFIX\_filterR.coords > $PREFIX\_filterR.gap2


	# ./show-tiling $PREFIX\_SNP.delta           > $PREFIX\_SNP.tiling           2>/dev/null
	# ./show-tiling $PREFIX\_SNP\_filterRQ.delta > $PREFIX\_SNP\_filterRQ.tiling 2>/dev/null
	./show-tiling $PREFIX\_SNP\_filterR.delta  > $PREFIX\_SNP\_filterR.tiling  2>/dev/null
	# ./show-tiling $PREFIX\_SNP\_filterQ.delta  > $PREFIX\_SNP\_filterQ.tiling  2>/dev/null
	./tilling_to_gap.pl $PREFIX\_SNP\_filterR.tiling
	./coords_to_gap.pl  $PREFIX\_SNP\_filterR.coords > $PREFIX\_SNP\_filterR.gap2

	# echo "    PLOTTING TILING"
	# ./mummerplot --SNP --large --color --layout $PREFIX.tiling                --prefix $PREFIX\_tiling               --png 1>/dev/null 2>/dev/null
	# ./mummerplot --SNP --large --color --layout $PREFIX\_SNP.tiling           --prefix $PREFIX\_SNP\_tiling          --png 1>/dev/null 2>/dev/null
	# echo "    PLOTTING TILING FILTER RQ"
	# ./mummerplot --SNP --large --color --layout $PREFIX\_filterRQ.tiling      --prefix $PREFIX\_tiling_filterRQ      --png 1>/dev/null 2>/dev/null
	# ./mummerplot --SNP --large --color --layout $PREFIX\_SNP\_filterRQ.tiling --prefix $PREFIX\_SNP\_tiling_filterRQ --png 1>/dev/null 2>/dev/null
	echo "    PLOTTING TILING FILTER R"
	./mummerplot --SNP --large --color --layout $PREFIX\_filterR.tiling       --prefix $PREFIX\_tiling_filterR       --png 1>/dev/null 2>/dev/null
	./mummerplot --SNP --large --color --layout $PREFIX\_SNP\_filterR.tiling  --prefix $PREFIX\_SNP\_tiling_filterR  --png 1>/dev/null 2>/dev/null
	# echo "    PLOTTING TILING FILTER Q"
	# ./mummerplot --SNP --large --color --layout $PREFIX\_filterQ.tiling       --prefix $PREFIX\_tiling_filterQ       --png 1>/dev/null 2>/dev/null
	# ./mummerplot --SNP --large --color --layout $PREFIX\_SNP\_filterQ.tiling  --prefix $PREFIX\_SNP\_tiling_filterQ  --png 1>/dev/null 2>/dev/null

	echo "EXTRACTING SNPs - STRICT"
	# ./show-snps -ClrHT -x4 $PREFIX.delta           > $PREFIX\_C.snps           2>/dev/null
	# ./show-snps -ClrHT -x4 $PREFIX\_filterRQ.delta > $PREFIX\_filterRQ\_C.snps 2>/dev/null
	./show-snps -ClrHT -x4 $PREFIX\_filterR.delta  > $PREFIX\_filterR\_C.snps  2>/dev/null
	# ./show-snps -ClrHT -x4 $PREFIX\_filterQ.delta  > $PREFIX\_filterQ\_C.snps  2>/dev/null

	# ./show-snps -ClrHT -x4 $PREFIX\_SNP.delta           > $PREFIX\_SNP\_C.snps           2>/dev/null
	# ./show-snps -ClrHT -x4 $PREFIX\_SNP\_filterRQ.delta > $PREFIX\_SNP\_filterRQ\_C.snps 2>/dev/null
	./show-snps -ClrHT -x4 $PREFIX\_SNP\_filterR.delta  > $PREFIX\_SNP\_filterR\_C.snps  2>/dev/null
	# ./show-snps -ClrHT -x4 $PREFIX\_SNP\_filterQ.delta  > $PREFIX\_SNP\_filterQ\_C.snps  2>/dev/null

	echo "EXTRACTING SNPs - ALL"
	# ./show-snps -lrHT -x4 $PREFIX.delta            > $PREFIX.snps           2>/dev/null
	# ./show-snps -lrHT -x4 $PREFIX\_filter.delta    > $PREFIX\_filter.snps   2>/dev/null
	# ./show-snps -lrHT -x4 $PREFIX\_filterRQ.delta  > $PREFIX\_filterRQ.snps 2>/dev/null
	./show-snps -lrHT -x4 $PREFIX\_filterR.delta   > $PREFIX\_filterR.snps  2>/dev/null
	# ./show-snps -lrHT -x4 $PREFIX\_filterQ.delta   > $PREFIX\_filterQ.snps  2>/dev/null

	# ./show-snps -lrHT -x4 $PREFIX\_SNP.delta            > $PREFIX\_SNP.snps           2>/dev/null
	# ./show-snps -lrHT -x4 $PREFIX\_SNP\_filter.delta    > $PREFIX\_SNP\_filter.snps   2>/dev/null
	# ./show-snps -lrHT -x4 $PREFIX\_SNP\_filterRQ.delta  > $PREFIX\_SNP\_filterRQ.snps 2>/dev/null
	./show-snps -lrHT -x4 $PREFIX\_SNP\_filterR.delta   > $PREFIX\_SNP\_filterR.snps  2>/dev/null
	# ./show-snps -lrHT -x4 $PREFIX\_SNP\_filterQ.delta   > $PREFIX\_SNP\_filterQ.snps  2>/dev/null


	# echo "EXTRACTING ALIGNMENTS"
	# REFT=( $(cat $REF   | grep ">" | awk 'sub("^.","")') )
	# QRYT=( $(cat $QUERY | grep ">" | awk 'sub("^.","")') )
	# 
	# TOTAL=$((${#REFT[@]}*${#QRYT[@]}))
	# TIMES=0
	# COUNT=0
	# echo -n "  $TOTAL ITERATIONS TO GO..."
	# ALIGNFOLDER="$OUTFOLDER/ALIGN/"

	# mkdir $ALIGNFOLDER 2>/dev/null
	# 
	# for Relement in $(seq 0 $((${#REFT[@]} -1)))
	#  do
	#    for Qelement in $(seq 0 $((${#QRYT[@]} -1)))
	#    do
	#      REFE=${REFT[$Relement]}
	#      QRYE=${QRYT[$Qelement]}
	# #      echo SHOWALIGN $FILE CLUSTERS $REFE VS $QRYE
	#      echo -n "."
	#      COUNT=$(($COUNT+1))
	#      if [ $COUNT -ge $(($TOTAL/100)) ]; then
	#          TIMES=$(($TIMES+1))
	#          COUNT=$(($COUNT*$TIMES))
	# 	 echo -n "$COUNT/$TOTAL"
	#          COUNT=0
	#      fi
	#      ./show-aligns -q $PREFIX.delta           $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE.aligns           2>/dev/null
	#      ./show-aligns -q $PREFIX\_filterRQ.delta $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE\_filterRQ.aligns 2>/dev/null
	#      ./show-aligns -q $PREFIX\_filterR.delta  $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE\_filterR.aligns  2>/dev/null
	#      ./show-aligns -q $PREFIX\_filterQ.delta  $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE\_filterQ.aligns  2>/dev/null
	# 
	#      ./show-aligns -q $PREFIX\_SNP.delta           $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE\_SNP.aligns           2>/dev/null
	#      ./show-aligns -q $PREFIX\_SNP\_filterRQ.delta $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE\_SNP\_filterRQ.aligns 2>/dev/null
	#      ./show-aligns -q $PREFIX\_SNP\_filterR.delta  $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE\_SNP\_filterR.aligns  2>/dev/null
	#      ./show-aligns -q $PREFIX\_SNP\_filterQ.delta  $REFE $QRYE > $ALIGNFOLDER/$FILE\_$REFE\_$QRYE\_SNP\_filterQ.aligns  2>/dev/null
	#    done
	# done
	# echo "."
	# 
	# ls -l $ALIGNFOLDER | grep -v R.aligns | grep -v Q.aligns | grep aligns  | echo "TOTAL     `wc -l`"
	# for i in $ALIGNFOLDER/*Q.aligns; do [ ! -s "${i}" ] && rm -f "${i}";done
	# for i in $ALIGNFOLDER/*R.aligns; do [ ! -s "${i}" ] && rm -f "${i}";done
	# for i in $ALIGNFOLDER/*.aligns;  do [ -s "${i}" ]   && echo "${i}";done | echo "POSITIVE  `wc -l`"
	# for i in $ALIGNFOLDER/*.aligns;  do [ ! -s "${i}" ] && echo "${i}";done | echo "NEGATIVE  `wc -l`"
	# for i in $ALIGNFOLDER/*.aligns;  do [ ! -s "${i}" ] && rm -f "${i}";done

	# # for i in $OUTFOLDER/*Q.aligns; do [ "1" == "1" ] && mv "${i}" $ALIGNFOLDER;done
	# # for i in $OUTFOLDER/*R.aligns; do [ "1" == "1" ] && mv "${i}" $ALIGNFOLDER;done
	# # for i in $OUTFOLDER/*.aligns;  do [ "1" == "1" ] && mv "${i}" $ALIGNFOLDER;done
	# 
	# 
	# # for i in $OUTFOLDER/*RQ.aligns; do [ ! -s "${i}" ] && echo `rm -f "${i}"; echo "${i} DELETED"`;done
	# # for i in $OUTFOLDER/*R.aligns;  do [ ! -s "${i}" ] && echo `rm -f "${i}"; echo "${i} DELETED"`;done
	# # for i in $OUTFOLDER/*Q.aligns;  do [ ! -s "${i}" ] && echo `rm -f "${i}"; echo "${i} DELETED"`;done
	# 
	# # echo `rm -f $(ls -l $OUTFOLDER/*0_filterRQ.aligns | awk '$5 == "0" {print $NF}')`
	# # echo `rm -f $(ls -l $OUTFOLDER/*0_filterR.aligns | awk '$5 == "0" {print $NF}')`
	# # echo `rm -f $(ls -l $OUTFOLDER/*0_filterQ.aligns | awk '$5 == "0" {print $NF}')`
	# 
	# # mv $OUTFOLDER/*9_filterRQ.aligns $ALIGNFOLDER 2>/dev/null
	# # mv $OUTFOLDER/*9_filterR.aligns $ALIGNFOLDER 2>/dev/null
	# # mv $OUTFOLDER/*9_filterQ.aligns $ALIGNFOLDER 2>/dev/null



	# # echo `rm -f $(ls -l $OUTFOLDER/*.aligns | awk '$5 == "0" {print $NF}')`
	# # mv $OUTFOLDER/*.aligns $ALIGNFOLDER 2>/dev/null
	# 
	# # for file in $ALIGNFOLDER/*.aligns
	# #  do
	# #     file_size=$(du $file | awk '{print $1}');
	# #     if [ $file_size == 0 ]; then
	# # #        echo "DELETING EMPTY FILE $file WITH FILE SIZE $file_size";
	# #        echo `rm -f $file`;
	# #     fi
	# #  done


	echo "CONVERTING IMAGES"
	FIGFOLDER=$OUTFOLDER/FIG
	PDFFOLDER=$OUTFOLDER/PDF

	mkdir $FIGFOLDER 2>/dev/null
	mkdir $PDFFOLDER 2>/dev/null
	mv $OUTFOLDER/*.fig $FIGFOLDER 2>/dev/null
	mv $OUTFOLDER/*.pdf $PDFFOLDER 2>/dev/null

	DATABASES=( $(ls $FIGFOLDER/*.fig) )
	DATABASES=(${DATABASES[@]#$FIGFOLDER/})
	DATABASES=(${DATABASES[@]%.fig})


	for element in $(seq 0 $((${#DATABASES[@]} -1)))
	 do
	   BASENAME=${DATABASES[$element]}
	   echo $BASENAME
		fig2dev -L jpeg -q 100 $FIGFOLDER/$BASENAME.fig > $FIGFOLDER/$BASENAME.jpg 2>/dev/null
		fig2dev -L png         $FIGFOLDER/$BASENAME.fig > $FIGFOLDER/$BASENAME.png 2>/dev/null
	 #   fig2dev -L pdf -l 1 -z A4 -F -c $FIGFOLDER/$BASENAME.fig > $FIGFOLDER/$BASENAME.pdf
		rm $FIGFOLDER/$BASENAME.fig 2>/dev/null
	done


	#$PREFIX\_filterR.coords > $PREFIX\_filterR.gap2
fi

mv ${OUTFOLDER}_* ${OUTFOLDER}/
./mummer_xml.pl "out" "nucmer" "${FILE}" "\\n"
