scrData <-
function(traps,captures,statespace,alive=NULL,Xd=NULL){

# do some stuff
# check traps.lions: [,1] = id, integer, [,2]=x coord [,3]=y coord [,4]=binary only
# captures [,1] = loc_id == trap   [,2] = animal_id integer [,3] = occasion
# statespace [,1] = x coord [,2] = y coord  [, 3] = binary habitat
#
# should do some default scaling. check if scale is km or meters?
#
#captures needs to be:
 #  session = rep(1,nrow(captures.lions)),
 #  individual=captures.lions[,2],
  # occasion=captures.lions[,3],
  # trapid=captures.lions[,1])

## need to edit : column 1 can be "year" "site" "session" "stratum" "group"
### column 2 can be "ind" "individual" ind_xxxx etc..
    ### column 3 can be "period" occasion sample etc
    ## column 4 can be trap trapid trxxxx

    if(ncol(captures)==3)
 session=rep(1,nrow(captures))
else
 session<- captures[,"session"]
individual<-captures[,"individual"]
occasion<-captures[,"occasion"]
trapid<- captures[,"trapid"]
captures<-cbind(session=session,individual=individual,occasion=occasion,trapid=trapid)




traplocs<-traps[,2:3]
MASK<-as.matrix(traps[,4:ncol(traps)])
nind<-max(individual)
K<-dim(MASK)[2]
ntraps<-nrow(traplocs)

if(is.null(alive))
alive=matrix(1,nrow=length(unique(captures[,"individual"])),ncol=ncol(MASK))
if(is.null(Xd)) Xd<- rep(0,nrow(statespace))



checkdata.fn<-function(Y){
encfreqs<- table(table(Y[,2]))
totrecaps<- sum(encfreqs*(as.numeric(names(encfreqs)) -1))
trapfreqs<- table(apply(table(Y[,2],Y[,1])>0,1,sum))
multitraps<- sum(trapfreqs*(as.numeric(names(trapfreqs))-1))
c(totrecaps,multitraps)
}
## Check minimum data requirements. This is completely arbitrary but
## it is meant to FORCE the user to proceed AT THEIR OWN RISK knowing
## that they have limited data and thinking about the potential consequences
if(1==2){
smydata<-checkdata.fn(Y)
cat("You had ",smydata[1]," recaptures in your study",fill=TRUE)
cat("You had ",smydata[2]," multi-trap recaptures in your study",fill=TRUE)
if( (smydata[1]< 10) | (smydata[2] < 5) ){
 cat("You should go into the field and obtain more data.",fill=TRUE)
 cat("Try again later.",fill=TRUE)
 return(NULL)
}
}





check<-cbind(captures[,"trapid"],captures[,"occasion"])
check2<- MASK[check]
if(any(check2 != 1)){
    cat("Some trap operation data != 1",fill=TRUE)
    return("goose egg")
}




##################
##################

### old format
### scrobj<-list(traps=traps.lions,captures=captures.lions,statespace=statespace.lions)
obj<-list(
    traps=traps,
    captures=captures,
    statespace=statespace,
    alive=alive,
    Xd=Xd)

class(obj)<-c("scrdata","list")

return(obj)

}