

function run
{
	FOLDER=$1
	NAME=$2
	if [ -d $FOLDER ]; then
		cd $FOLDER
		echo -e "IN FOLDER $FOLDER WITH NAME $NAME : "`pwd`
		echo -e "\tGENERATING NAMES"
			../gennames.sh $NAME
		echo -e "\tCONVERTING TAB TO MAPS"
			../tab2map.pl $NAME.GENES.csv
			../tab2map.pl $NAME.REGIO.csv
		echo -e "\tCUTING FASTA"
			../cutFasta.pl ../R265_c_neoformans.fasta $NAME.GENES.csv.out.tab 
			../cutFasta.pl ../R265_c_neoformans.fasta $NAME.REGIO.csv.out.tab 
		cd ..
		echo -e "\n\n"
	else
		echo -e "FOLDER $FOLDER DOESNT EXISTS. SKIPPING"
		echo -e "\n\n"
	fi
}

#INDIVIDUAL3
run Top17None Top17None
#run Top17None01 Top17None01
run Top17None02 Top17None02
run Top17None03 Top17None03
run Top48None Top48None
run Top82None Top82None

#INDIVIDUAL
#run Top05 Top05
#run Top10 Top10
#run Top25 Top25
#run TopAll TopAll


#cd Top05
#./Top05_run.sh
#cd ..

#cd Top10
#./Top10_run.sh
#cd ..

#cd Top25
#./Top25_run.sh
#cd ..

#cd TopAll
#./TopAll_run.sh
#cd ..


#NAME="fantastic"
#./gennames.sh $NAME
#./tab2map.pl $NAME.csv
#./cutFasta.pl R265_c_neoformans.fasta $NAME.csv.out.tab 

#NAME="bookmarks_09"
#./tab2map.pl $NAME
#./cutFasta.pl R265_c_neoformans.fasta $NAME.out.tab 


