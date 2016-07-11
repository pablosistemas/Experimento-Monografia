library('getopt');

spec = matrix(c(
   'help'   ,'h', 0, "logical",
   'infile' ,'f', 1, "character",
   'outdir', 'd', 1, "character",
   'graf_num','g',1, "integer"), byrow=TRUE, ncol=4)

opt = getopt(spec);

if(!is.null(opt$help)) {
   cat(getopt(spec,usage=TRUE));
   q(status=1);
}

if(is.null(opt$infile)) {
   print ("De o nome do arquivo de entrada");
   q(status=1);
}

if(is.null(opt$outdir)) {
   print ("De o diretorio de saida");
   q(status=1);
}

if(is.null(opt$graf_num)) {
   print ("De o numero do grafico");
   q(status=1);
}

x <- read.table(opt$infile, header=T); 

NOME <- opt$graf_num;

# plota o histograma
png(paste(opt$outdir,"/histo_",NOME,".png",sep=""))
hist(x[,1],main="Histograma e densidade dos erro");
par(new=T)
dx <- density(x[,1])
plot (dx,ann=F,xaxt='n',yaxt='n')
axis(4)
axis(3)
dev.off()

# plota o qqplot
png(paste(opt$outdir,"/qqplot_",NOME,".png",sep=""))
qqnorm(x[,1], xlab="Quantis teoricos", ylab="Quantis amostrais", main="Aproximação da distribuição dos erros pela normal");
qqline(x[,1]);
dev.off()

# plota o bloxplot
png(paste(opt$outdir,"/boxplot_",NOME,".png",sep=""))
boxdata <- boxplot(x[,1],horizontal=T,plot=F)
boxplot(x[,1],horizontal=T)
rug(x[,1],side=1)
title(main="Boxplot da distribuição do erro")
labels <- c("Menor valor","quartil inferior", "mediana","quartil superior","maior valor")
text(x=c(boxdata$stat[1,1],boxdata$stat[2,1],boxdata$stat[3,1],boxdata$stat[4,1],boxdata$stat[5,1]),labels=labels)
dev.off()

