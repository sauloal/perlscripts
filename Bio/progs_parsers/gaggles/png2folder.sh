ls | perl -MFile::Copy -ne 'if (/(\d+)_(\d+)_(\d+)\.png/) { chomp; print "CHROM $1 POS $2 QUAL $3 :: $_\n"; mkdir("$1_$2_$3"); move($_, "$1_$2_$3/$_")};'
