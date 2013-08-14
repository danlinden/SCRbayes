print.scrdata <-
function(x, ...) {    
cat("Hello, world!",fill=TRUE)
ntraps<-nrow(x$traps)
nx<-table(x$captures[,"individual"])
cat("\nTotal encounters of each individual:","\n")
print(nx,...)
cat("\nSummary encounter frequencies:","\n")
print(table(nx),...)
a<-table(x$captures[,"individual"],x$captures[,"trapid"])
a<-table(apply(a>0,1,sum))
cat("\nNum. unique traps of capture:","\n")
print(a,...)
}