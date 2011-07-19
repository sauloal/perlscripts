#!/bin/bash
# ./runsingle.sh out/nucmer/ nucmer_r265_maq         seqs/c_neo_r265.fasta     seqs/maq_run_4.fasta 0
# ./runsingle.sh out/nucmer/ nucmer_r265_r265        seqs/c_neo_r265.fasta     seqs/c_neo_r265.fasta 0
# ./runsingle.sh out/nucmer/ nucmer_r265_solAssembly seqs/c_neo_r265.fasta     seqs/solexa_assembly.fasta 0
#./runsingle.sh out/nucmer/ nucmer_r265_velvetnu31  seqs/c_neo_r265.fasta     seqs/velvet_nu_03_1.fasta 0
# ./runsingle.sh out/nucmer/ nucmer_r265_velvetus61  seqs/c_neo_r265.fasta     seqs/velvet_us_06_1.fasta 0
# ./runsingle.sh out/nucmer/ nucmer_r265_velvetwh111 seqs/c_neo_r265.fasta     seqs/velvet_wh_11_1.fasta 0
# ./runsingle.sh out/nucmer/ nucmer_r265_velvetwh112 seqs/c_neo_r265.fasta     seqs/velvet_wh_11_2.fasta 0
# ./runsingle.sh out/nucmer/ nucmer_r265_wm276       seqs/c_neo_r265.fasta     seqs/WM276GBFF10_06.fasta 0
#./runsingle.sh out/nucmer/ nucmer_r265_MITO          seqs/c_neo_r265/c_neo_r265_25.fasta     seqs/c_neo_r265_mito.fasta 0

#./runsingle.sh out/nucmer/ nucmer_r265_velvetwh113 seqs/c_neo_r265.fasta     seqs/velvet_wh_11_3.fasta 0

./runsingle.sh out/nucmer/ nucmer_CBS7750_CBS7750  seqs/CBS7750_supercontigs.fasta	seqs/CBS7750_supercontigs.fasta      0
./runsingle.sh out/nucmer/ nucmer_CBS7750_r265     seqs/CBS7750_supercontigs.fasta	seqs/c_neo_r265.fasta                0
./runsingle.sh out/nucmer/ nucmer_r265_CBS7750     seqs/c_neo_r265.fasta            seqs/CBS7750_supercontigs.fasta	     0
./runsingle.sh out/nucmer/ nucmer_CBS7750_wm276    seqs/CBS7750_supercontigs.fasta 	seqs/WM276GBFF10_06.fasta            0

# NAMES=( $(ls seqs/c_neo_r265/*.fasta) )
# FILES=( $(ls seqs/c_neo_r265/*.fasta) )
# 
# NAMES=(${NAMES[@]#seqs/c_neo_r265/})
# NAMES=(${NAMES[@]%.fasta})
# 
# 
# for element in $(seq 0 $((${#NAMES[@]} -1)))
#  do
# NAME=${NAMES[$element]}
# FILE=${FILES[$element]}
#  echo $NAME ">" $FILE
# 	./runsingle.sh out/nucmer/ nucmer_r265_$NAME\_velvetwh113 $FILE seqs/velvet_wh_11_3.fasta
# done

#./runsingle.sh out/nucmer/ nucmer_r265_$NAME\_solexa $FILE seqs/solexa_assembly.fasta

