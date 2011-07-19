INPUT=$1
SHORT=$2
echo "
data = read.table(\"$INPUT\", header=TRUE)

library(plotrix)
weighted.hist(data\$short1_cov, data\$lgth, breaks=0:50)
dev.copy2pdf()
quit(save="no")
" > run.r


R --no-save < run.r 1&>/dev/null 2&>/dev/null

rm run.r

mv Rplots.pdf $SHORT.pdf

# hist(data\$short1_cov, xlim=range(0,50), breaks=1000000)
#install.packages("plotrix")

#dev.copy2pdf(file=\"$SHORT.pdf\")
#pdf("plot.pdf")
#pdf("plot.pdf")
#dev.copy2pdf(,out.type="pdf")
#dev.copy2pdf(x11,out.type="pdf")
#dev.copy2pdf("out.pdf",out.type="pdf")
#dev.print(file="fig.eps")
#quit(save="yes")
#
