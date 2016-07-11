library('getopt');

spec = matrix(c(
   'help'         ,'h', 0, "logical",
   'infile'       ,'f', 1, "character",
   'outdir'       ,'d', 1, "character",
   'latAnalitica' ,'l', 1, "integer",
   'graf_num'     ,'g', 1, "character"), byrow=TRUE, ncol=4)

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

if(is.null(opt$latAnalitica)) {
   print ("De a latencia esperada");
   q(status=1);
}

#print(opt$latAnalitica);
#print(opt$graf_num);
#print(opt$outdir);
#print(opt$infile);

x <- read.table(opt$infile, header=T, col.names="LATENCIA"); 

NOME <- opt$graf_num;

# plota o histograma
setEPS()
postscript(paste(opt$outdir,"/histo_",NOME,".eps",sep=""))
#png(paste(opt$outdir,"/histo_",NOME,".png",sep=""));

inf <- opt$latAnalitica - 11.5;
sup <- opt$latAnalitica + 11.5;
eixo <- list(all.names=c('x','y'))
eixo$x <- seq(from=inf,to=sup,length.out=length(x$LATENCIA))

hist(x$LATENCIA,#xlim=c(inf, sup),
   main="Histograma e densidade das latencias de cada fluxo",
   xlab="Latencia em milissegundos", ylab="Numero de ocorrencias", col="lightgreen", 
   freq=T);

abline(v=mean(x$LATENCIA),col="red",lty=3,lwd=4)
# axis(side=3,at=mean(x$LATENCIA),las=0)

abline(v=opt$latAnalitica,col="blue",lty=4,lwd=4)
# axis(side=3,at=opt$latAnalitica,las=0)

legend("topright",c(sprintf("Media fluxos: %.3f",mean(x$LATENCIA)),
   sprintf("Media esperada: %d",opt$latAnalitica)),fill=c("red","blue"))

dev.off()

# plota CDF das latencias
setEPS()
postscript(paste(opt$outdir,"/cdf_",NOME,".eps",sep=""))
#png(paste(opt$outdir,"/cdf_",NOME,".png",sep=""))

# constroi vetor de CDF analitica
for (i in seq(1,length(x$LATENCIA))) {
   if (eixo$x[i] < inf) {
      eixo$y[i] <- 0
   } else if (eixo$x[i] >= sup) {
      eixo$y[i] <- 1;  
   }  else {
      eixo$y[i] <- (eixo$x[i] -inf)/(sup-inf)
   }
}

plot(x=eixo$x,y=eixo$y,,xlim=c(inf, sup),main="CDF das latencias",xlab="Latencias em milissegundos",ylab="Percentual",col="blue")
lines(ecdf(x$LATENCIA),col="red",lwd=4)
legend("topleft",c("CDF esperada","CDF amostrada"),fill=c("blue","red"))
dev.off()
