./mapN.pl r265_vs_denovo2.maf.sort.maf.nopar.maf.fasta             &> r265_vs_denovo2.maf.sort.maf.nopar.maf.fasta_NONE.tab.log
./mapN.pl R265_c_neoformans.fasta                                  &> R265_c_neoformans.fasta_NONE.tab.log

./mkplotfromnone.pl R265_c_neoformans.fasta R265_c_neoformans.fasta_NONE.tab r265_vs_denovo2.maf.sort.maf.nopar.maf.fasta_NONE.tab


