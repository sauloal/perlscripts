function makeit
{
 DIR=$1
 #rm -rf $DIR
 mkdir $DIR 2>/dev/null
 cd $DIR
# find -L ../../report/individual3/$DIR -name '*.tab' -exec cp {} . \;; 
 find -L ../../report/individual3/$DIR -name '*.tab' -exec ln -s {} . \;; 
 cd ..
}

makeit Top17None01
makeit Top17None02
makeit Top17None03
makeit Top48None
makeit Top82None

