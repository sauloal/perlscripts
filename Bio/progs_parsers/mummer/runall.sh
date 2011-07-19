# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/maq_run_4.fasta       out/mum3_r265_maq
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/velvet_nu_03_1.fasta  out/mum3_r265_velvetnu31
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/velvet_us_06_1.fasta  out/mum3_r265_velvetus61
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/velvet_wh_11_1.fasta  out/mum3_r265_velvetwh111
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/velvet_wh_11_2.fasta  out/mum3_r265_velvetwh112
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/velvet_wh_11_3.fasta  out/mum3_r265_velvetwh113
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/c_neo_r265.fasta      out/mum3_r265_r265
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/WM276GBFF10_06.fasta  out/mum3_r265_wm276
# # ./run-mummer3 seqs/c_neo_r265.fasta seqs/solexa_assembly.fasta out/mum3_r265_solAssembly
# # mkdir out/mummer3
# # mv out/*.align      out/mummer3/
# # mv out/*.errorsgaps out/mummer3/
# # mv out/*.gaps       out/mummer3/
# # mv out/*.out        out/mummer3/
# 
# # mkdir out/mummer
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/maq_run_4.fasta       > out/mummer/mum_r265_maq.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/velvet_nu_03_1.fasta  > out/mummer/mum_r265_velvetnu31.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/velvet_us_06_1.fasta  > out/mummer/mum_r265_velvetus61.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/velvet_wh_11_1.fasta  > out/mummer/mum_r265_velvetwh111.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/velvet_wh_11_2.fasta  > out/mummer/mum_r265_velvetwh112.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/velvet_wh_11_3.fasta  > out/mummer/mum_r265_velvetwh113.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/c_neo_r265.fasta      > out/mummer/mum_r265_r265.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/WM276GBFF10_06.fasta  > out/mummer/mum_r265_wm276.mums
# # ./mummer -mum -b -c seqs/WM276GBFF10_06.fasta seqs/c_neo_r265.fasta  > out/mummer/mum_wm276_r265.mums
# # ./mummer -mum -b -c seqs/c_neo_r265.fasta seqs/solexa_assembly.fasta > out/mummer/mum_r265_solAssembly.mums
# # cat out/mummer/mum_r265_maq.mums   | ./mgaps > out/mummer/mum_r265_maq.mgaps
# # cat out/mummer/mum_r265_r265.mums  | ./mgaps > out/mummer/mum_r265_r265.mgaps
# # cat out/mummer/mum_r265_wm276.mums | ./mgaps > out/mummer/mum_r265_wm276.mgaps
# # cat out/mummer/mum_wm276_r265.mums | ./mgaps > out/mummer/mum_wm276_r265.mgaps
# # # cat out/mummer/mum_r265_velvetnu31.mums   | ./mgaps > out/mummer/mum_r265_velvetnu31.mgaps
# # # cat out/mummer/mum_r265_velvetus61.mums   | ./mgaps > out/mummer/mum_r265_velvetus61.mgaps
# # # cat out/mummer/mum_r265_velvetwh111.mums  | ./mgaps > out/mummer/mum_r265_velvetwh111.mgaps
# # # cat out/mummer/mum_r265_velvetwh112.mums  | ./mgaps > out/mummer/mum_r265_velvetwh112.mgaps
# # # cat out/mummer/mum_r265_velvetwh113.mums  | ./mgaps > out/mummer/mum_r265_velvetwh113.mgaps
# # # cat out/mummer/mum_r265_solAssembly.mums  | ./mgaps > out/mummer/mum_r265_solAssembly.mgaps
# 
# ##mummer -mum -b -c ref.fasta qry.fasta > ref_qry.mums
# ##mummerplot --postscript --prefix=ref_qry ref_qry.mums
# ##gnuplot ref_qry.gp
# 
# 
# 
# ########################
# ### C NEO R265
# ########################
# 
# # ./nucmer --prefix=out/nucmer_r265_maq         seqs/c_neo_r265.fasta seqs/maq_run_4.fasta
# # ./nucmer --prefix=out/nucmer_r265_velvetnu31  seqs/c_neo_r265.fasta seqs/velvet_nu_03_1.fasta
# # ./nucmer --prefix=out/nucmer_r265_velvetus61  seqs/c_neo_r265.fasta seqs/velvet_us_06_1.fasta
# # ./nucmer --prefix=out/nucmer_r265_velvetwh111 seqs/c_neo_r265.fasta seqs/velvet_wh_11_1.fasta
# # ./nucmer --prefix=out/nucmer_r265_velvetwh112 seqs/c_neo_r265.fasta seqs/velvet_wh_11_2.fasta
# # ./nucmer --prefix=out/nucmer_r265_velvetwh113 seqs/c_neo_r265.fasta seqs/velvet_wh_11_3.fasta
# # ./nucmer --prefix=out/nucmer_r265_r265        seqs/c_neo_r265.fasta seqs/c_neo_r265.fasta
# # ./nucmer --prefix=out/nucmer_r265_wm276       seqs/c_neo_r265.fasta seqs/WM276GBFF10_06.fasta
# # ./nucmer --prefix=out/nucmer_r265_solAssembly seqs/c_neo_r265.fasta seqs/solexa_assembly.fasta
# # ./nucmer --prefix=out/nucmer_wm276_r265       seqs/WM276GBFF10_06.fasta seqs/c_neo_r265.fasta
# 
# # mkdir out/nucmer
# # mv out/*.delta out/nucmer
# # mv out/*.cluster out/nucmer
# 
./runsingle.sh out/nucmer/ nucmer_r265_maq         seqs/c_neo_r265.fasta seqs/maq_run_4.fasta
./runsingle.sh out/nucmer/ nucmer_r265_velvetnu31  seqs/c_neo_r265.fasta seqs/velvet_nu_03_1.fasta
./runsingle.sh out/nucmer/ nucmer_r265_velvetus61  seqs/c_neo_r265.fasta seqs/velvet_us_06_1.fasta
./runsingle.sh out/nucmer/ nucmer_r265_velvetwh111 seqs/c_neo_r265.fasta seqs/velvet_wh_11_1.fasta
./runsingle.sh out/nucmer/ nucmer_r265_velvetwh112 seqs/c_neo_r265.fasta seqs/velvet_wh_11_2.fasta
./runsingle.sh out/nucmer/ nucmer_r265_solAssembly seqs/c_neo_r265.fasta seqs/solexa_assembly.fasta
./runsingle.sh out/nucmer/ nucmer_r265_velvetwh113 seqs/c_neo_r265.fasta seqs/velvet_wh_11_3.fasta
./runsingle.sh out/nucmer/ nucmer_r265_r265        seqs/c_neo_r265.fasta seqs/c_neo_r265.fasta
./runsingle.sh out/nucmer/ nucmer_r265_wm276       seqs/c_neo_r265.fasta seqs/WM276GBFF10_06.fasta
# 
# 
# 
# ########################
# ### C NEO WM276
# ########################
# # ./runsingle.sh out/nucmer/ nucmer_wm276_maq         seqs/WM276GBFF10_06.fasta  seqs/maq_run_4.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_solAssembly seqs/WM276GBFF10_06.fasta  seqs/solexa_assembly.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_velvetnu31  seqs/WM276GBFF10_06.fasta  seqs/velvet_nu_03_1.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_velvetus61  seqs/WM276GBFF10_06.fasta  seqs/velvet_us_06_1.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_velvetwh111 seqs/WM276GBFF10_06.fasta  seqs/velvet_wh_11_1.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_velvetwh112 seqs/WM276GBFF10_06.fasta  seqs/velvet_wh_11_2.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_r265        seqs/WM276GBFF10_06.fasta  seqs/c_neo_r265.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_wm276       seqs/WM276GBFF10_06.fasta  seqs/WM276GBFF10_06.fasta
# # ./runsingle.sh out/nucmer/ nucmer_wm276_velvetwh113 seqs/WM276GBFF10_06.fasta  seqs/velvet_wh_11_3.fasta
