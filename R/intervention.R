#Uses http://cran.r-project.org/web/packages/meta/
#Alternatives:f
# http://cran.r-project.org/web/packages/metafor/ (allows continuity correction)
# http://cran.r-project.org/web/packages/rmeta/
# Discussion of continuity correction:
# http://handbook.cochrane.org/chapter_16/16_9_2_studies_with_zero_cell_counts.htm
intervention <- function(content, measure, year, pmid, sortby, lefthand, righthand, type, cofactorlabel, topic, theme) {
temp <- content
# Uses package meta http://cran.r-project.org/web/packages/meta/
# http://stat.ethz.ch/R-manual/R-devel/library/base/html/regex.html
temp <- gsub('\n', '', fixed = TRUE, temp, perl = TRUE)
#temp <- gsub("\\s+$", "", temp, perl = TRUE) #Removing trailing whitespace
#temp <- gsub(",+$", "", temp, perl = TRUE) #Remove trailing comma if accidentally added by user online
temp <- gsub("\t", ' ', fixed = TRUE, temp)
temp <- gsub(',', '","', fixed = TRUE, temp)
temp <- paste('"',temp,'"',sep = '')
temp <- paste('Mymatrix <- matrix(c(',temp,'), ncol=8, byrow=TRUE, dimnames = list(NULL, c("Study","year", "pmid", "exp_events", "exp_total","control_events","control_total","cofactor")))')
x<-eval(parse(file = "", n = NULL, text = temp))
myframe <- data.frame (x)
myframe$Study<-gsub("\'", '', fixed = TRUE, myframe$Study)
myframe$Study<-as.character(str_trim(myframe$Study))
myframe$year<-as.numeric(as.character(str_trim(myframe$year)))
myframe$pmid<-as.numeric(as.character(str_trim(myframe$pmid)))
PosParenth1 <- regexpr("(", myframe$exp_events, fixed=TRUE)
if (PosParenth1 > 0)
	{
	PosParenth2 <-regexpr(")", myframe$exp_events, fixed=TRUE)
	myframe$exp_mean<-as.numeric(substring(myframe$exp_events, 1, PosParenth1 - 1))
	myframe$exp_sd<-as.numeric(substring(myframe$exp_events, PosParenth1 + 1, PosParenth2 - 1))
	PosParenth1 <-regexpr("(", myframe$control_events, fixed=TRUE)
	PosParenth2 <-regexpr(")", myframe$control_events, fixed=TRUE)
	myframe$control_mean<-as.numeric(substring(myframe$control_events, 1, PosParenth1 - 1))
	myframe$control_sd<-as.numeric(substring(myframe$control_events, PosParenth1 + 1, PosParenth2 - 1))
	}
else
	{
	myframe$exp_events<-as.numeric(as.character(str_trim(myframe$exp_events)))
	myframe$control_events<-as.numeric(as.character(str_trim(myframe$control_events)))
	}
myframe$exp_total<-as.numeric(as.character(str_trim(myframe$exp_total)))
myframe$control_total<-as.numeric(as.character(str_trim(myframe$control_total)))
if (sortby=="weight")
	{
	sortvalue <- NULL
	}
if (sortby=="cofactor")
	{
	sortvalue <- myframe$cofactor
	}
if (sortby=="year")
	{
	sortvalue <- myframe$year
	}
for(i in 1:length(myframe$Study))
{
if(myframe$exp_events[i]==0 & myframe$control_events[i]==0)
	{
	#myframe$exp_events[i] == 0.5 
	#myframe$control_events[i] == 0.5
	}
}
attach(myframe)
KUBlue = "#0022B4"
SkyBlue = "#6DC6E7"
pubbiastext = "Test for funnel plot asymmetry"
analyticmethod = "Random effects model (Hartung-Knapp)"
#par(col.axis="black" ,col.lab=KUBlue ,col.main=KUBlue ,col.sub=KUBlue, col=KUBlue,new = TRUE) #bg=SkyBlue)
if (type=="ignore")
	{
	# from http://cran.r-project.org/web/packages/meta/
	if (PosParenth1 > 0)
		{
		meta1 <- metacont(exp_total, exp_mean, exp_sd, control_total, control_mean, control_sd, data=myframe, sm = measure, hakn = TRUE, studlab=paste(Study,", ", year, sep=""))
		if (measure == "MD"){xlimits=NULL}else{xlimits=c(-2, 2)}
		#Publication bias
		if (length(myframe$Study)>9)
			{
			pubbias = metabias(meta1, method.bias="linreg", plotit=FALSE)
			pubbiastext = paste(pubbiastext, " (Egger): p= ",round(pubbias$p.value,3),sep="");
			}
		else
			{
			pubbiastext = paste(pubbiastext,": too few studies to test",sep="")
			}
		}
	else
		{
		meta1 <- metabin(exp_events, exp_total, control_events, control_total, data=myframe, sm = measure, hakn = TRUE, method="Inverse", level = 0.95, incr = "TA", allstudies = TRUE, studlab=paste(Study,", ", year, sep=""))
		xlimits=c(0.1, 10)
		#Publication bias / small study effect
		if (length(myframe$Study)>9)
			{
			meta1.as <- metabin(exp_events, exp_total, control_events, control_total, data=myframe, sm="ASD", method="I")
			pubbias = metabias(meta1.as, plotit=FALSE)
			pubbiastext = paste(pubbiastext, " (Rucker): p= ",round(pubbias$p.value,3),sep="");
			}
		else
			{
			pubbiastext = paste(pubbiastext,": too few studies to test",sep="")
			}
		}
	if (sortby=="weight")
		{
		sortvalue <- 1/meta1$w.random
		}
	#stop(paste(topic,lefthand, righthand, sep=", "))
	forest(meta1, sortvalue, xlim=xlimits, col.diamond="blue", col.diamond.lines="blue", title = topic, comb.fixed=FALSE,print.tau2=FALSE, label.left=lefthand, label.right=righthand,text.random=analyticmethod,text.random.w=analyticmethod, fs.random=12, ff.random = 1, ff.hetstat=2, fs.hetstat=12)
	#grid.text(topic, 0.5, 0.97, gp = gpar(fontsize = 14, fontface = "bold"))
	grid.text(topic, 0.5, 0.97, gp = gpar(fontsize = 14, fontface = "bold"))
	#main=textGrob(topic, gp=gpar(cex=3), just="top")
	grid.text(pubbiastext, 0.1, 0.02, hjust = 0, gp = gpar(fontsize = 12, fontface = "bold"))
	}
if (type=="subgroup")
	{
	# from http://cran.r-project.org/web/packages/meta/
	myframe$cofactor<-gsub("\'", '', fixed = TRUE, myframe$cofactor)
	myframe$cofactor<-as.character(str_trim(myframe$cofactor))
	if (PosParenth1 > 0)
		{
		meta1 <- metacont(exp_total, exp_mean, exp_sd, control_total, control_mean, control_sd, data=myframe, sm = measure, hakn = TRUE, studlab=paste(Study,", ", year, sep=""), label.left=lefthand, label.right=righthand, title = topic, byvar=cofactor, print.byvar = FALSE)
		if (measure == "MD"){xlimits=NULL}else{xlimits=c(-2, 2)}
		#Publication bias
		if (length(myframe$Study)>9)
			{
			meta1.egger <- metacont(exp_total, exp_mean, exp_sd, control_total, control_mean, control_sd, data=myframe, sm = measure)
			pubbias = metabias(meta1.egger, method.bias="linreg", plotit=FALSE)
			pubbiastext = paste(pubbiastext, " (Egger): p= ",round(pubbias$p.value,3),sep="");
			}
		else
			{
			pubbiastext = paste(pubbiastext,": too few studies to test",sep="")
			}
		}
	else
		{
		meta1 <- metabin(exp_events, exp_total, control_events,control_total, data=myframe, sm = measure, method="Inverse", hakn = TRUE, level = 0.95, incr = "TA", allstudies = TRUE, studlab=paste(Study,", ", year, sep=""), label.left=lefthand, label.right=righthand, title = topic, byvar=cofactor, print.byvar = FALSE)
		xlimits=c(0.1, 10)
		#Publication bias / small study effect
		if (length(myframe$Study)>9)
			{
			meta1.as <- metabin(exp_events, exp_total, control_events, control_total, data=myframe, sm="ASD", method="I")
			pubbias = metabias(meta1.as, plotit=FALSE)
			pubbiastext = paste(pubbiastext, " (Rucker): p= ",round(pubbias$p.value,3),sep="");
			}
		else
			{
			pubbiastext = paste(pubbiastext,": too few studies to test",sep="")
			}
		}
	if (sortby=="weight")
		{
		sortvalue <- 1/meta1$w.random
		}
	forest(meta1, sortvalue, col.diamond="blue", col.diamond.lines="blue", title = topic, main = topic, comb.fixed=FALSE,print.tau2=FALSE, label.left=lefthand, label.right=righthand,text.random=analyticmethod,text.random.w=analyticmethod, fs.random=12, ff.random = 1, ff.hetstat=2, fs.hetstat=12)
	grid.text(topic, 0.5, 0.97, gp = gpar(fontsize = 14, fontface = "bold"))
	grid.text(pubbiastext, 0.1, 0.04, hjust = 0, gp = gpar(fontsize = 12, fontface = "bold"))
	#Test for subgroup differences
	#Hartung-Knapp gives Q = 0 if a subgroup has single member
	meta1 <- update(meta1,hakn = FALSE)
	byvartext = 1 - pchisq(meta1$Q.b.random, df = meta1$df.Q.b);
	byvartext = sprintf(byvartext, fmt='%#.3f');
	byvartext = paste("Test for differences among subgroups: p = ", byvartext ,sep="");
	grid.text(byvartext, 0.1, 0.07, hjust = 0, gp = gpar(fontsize = 12, fontface = "bold"))
	}
if (type=="metaregression")
	{
	# From http://cran.r-project.org/web/packages/rmeta/ **remeta**
	myframe$cofactor<-as.numeric(as.character(str_trim(myframe$cofactor)))
	meta1 <- meta.DSL(myframe[["exp_total"]], myframe[["control_total"]], myframe[["exp_events"]], myframe[["control_events"]],names=Study,conf.level=0.95)
	studyweights <- 1 / (meta1$tau2 + meta1$selogs^2)
	x <- myframe$cofactor
	y <- meta1$logs
	metaregression <- lm(y ~ x , data = myframe , weights = studyweights)
	plot(y ~ x, data = myframe, main=paste("Meta-regression of ", topic), xlab="", ylab="",ylim=c(-1,1),xaxs="r",type="n")
	points(y ~ x,cex=10*studyweights/sum(studyweights),pch=21,bg='blue',col='blue')
	text(x=x, y=y,labels=paste(Study), cex=0.65, pos=4,adj=0,font=1,col='black')
	abline(h=0, v=0, col = "gray90")
	abline(lm(y ~ x, data = myframe, weights = studyweights))
	legendtext = "Correlation of cofactor and odds ratio:\n"
	legendtext = paste(legendtext,"All studies (" ,length(myframe$Study),"):",round(summary(metaregression)$coef[2,1],3),", p =",round(summary(metaregression)$coef[2,4],3))
	legend("topright", legend=legendtext,lty=1, lwd = 2, inset=0.05)
	if ( cofactorlabel != "")
		{
		mtext(side=1,line=2,paste("Cofactor: ",cofactorlabel), font=2)
		}
	else
		{
		mtext(side=1,line=2,"Cofactor", font=2)
		}
	mtext(side=2,line=3,"Odds ratio transformed to natural log (Ln)", font=2)
	mtext(side=2,line=2,"(0 indicates odds ratio = 1)")
	#mtext(side=3,line=0.5,"(Ln odds ratio below 0 favors treatment)")
	mtext(side=1,line=3,cex=0.9,adj=0,"Notes:", font=2)
	mtext(side=1,line=4,cex=0.9,adj=0, "1. For each study, the size of the point is its weight in the meta-regression.", font=1)
	}
#if(theme=="KU"){display_logo(x=1.2,y=0.05)}
}