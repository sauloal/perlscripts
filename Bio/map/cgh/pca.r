#input <- "B3501_TYNE.txt"
data <- read.table(input, header = T)
#head(data)

Round <- round(cor(data) * 10)
write.table(Round, paste(input,"_R_0_round.txt"), quote = FALSE, sep = "\t")

#write.table(Pairs, quote = FALSE, sep = "\t")

pc1 <- prcomp(data, scale. = T)
rot <- pc1$r
x   <- pc1$x

#write.table(Summary, quote = FALSE, sep = "\t")

Rot <- round(rot * 10)
write.table(Rot, paste(input,"_R_1_rot.txt"), quote = FALSE, sep = "\t")

X <- round(x*10)
write.table(X, paste(input,"_R_2_X.txt"), quote = FALSE, sep = "\t")

Summary <- summary(pc1)


screeplot(pc1)

Pairs <- pairs(data, phc = ".", col = "blue")

file.rename("Rplots.pdf", paste(input,"_R_3_plot.pdf"));

quit()
n
