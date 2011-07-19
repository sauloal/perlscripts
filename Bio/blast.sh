cat probes.txt | gawk '{print ">"$1" "$2"\n"$3}' > probes.txt.fasta
mkdir db
makeblastdb -in CBS7750_supercontigs.fasta -dbtype nucl -title "Cryptococcus gattii CBS7750" -out db/cbs7750
blastn -task blastn -db db/cbs7750 -query probes.txt.fasta -out answer_probex.txt.fasta_cbs7750.blast -num_threads 6 -evalue 0.1 -word_size 4 -gapopen 0 -gapextend 4 -penalty -2 -reward 2
