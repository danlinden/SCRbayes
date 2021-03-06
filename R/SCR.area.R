SCR.area = function(obj, SO, Mb=0, Mbvalue=NULL, Msex=0, Msexsigma=0, Xsex = NULL, Mss=0, Xd=NULL, Meff=0, Xeff=NULL, iter=NULL, scalein=1000,useSnowfall=FALSE, nprocs = 1, con.type="SOCK",...){
	# Some basic error checking on behavioral covariates
	# The expectations on this input likely need some further thought. 
	# I allow either a global or trap-specific value	
	require(raster)
	require(sp)
	if (Mb==1){ 
		if(!is.numeric(Mbvalue)) {
			cat("Error: Please supply a numeric value for behavioral capture effect", fill=T)
			return()}
		if (!(length(Mbvalue) %in% c(1,nrow(obj$G)))){
			cat("Error: Behavioral effect should take on a single value or a trap-specific value", fill=T)
			return()
		}
	}
	
	#Some basic error checking for sex covariates
	if (Msex==1|Msexsigma==1){
		if (!is.null(Xsex)){
			if(!is.numeric(Xsex)) {
				cat("Error: Please supply a numeric value for Xsex", fill=T)
				return()}
			if (!(length(Xsex) %in% c(1))){
				cat("Error: Sex should take on a single value for prediction", fill=T)
				return()
			}
			if(Xsex<0|Xsex>1){
				cat("Error: Value of Xsex should be between 0 and 1")
				return()
			}
		}
	}
	
	# Basic error check for effort covariate
	if (Meff == 1){
		if(!is.numeric(Xeff)) {
			cat("Error: Please supply a numeric value for Xeff", fill=T)
			return()}
		if (!(length(Xeff) %in% c(1,nrow(obj$G)))){
			cat("Error: Xeff should take on a single value or trap-specific value", fill=T)
			return()
		}
		
	}
	# Compute activity centers for each iteration of the chain
	# This takes some time and it may be better to incorporate this 
	# into the if statements below for computing param.values to improve calculation time
	# centers= (obj$Sout*obj$zout)
	# gridchain = matrix(nrow=nrow(centers),ncol=nrow(obj$statespace))
	
	# for (k in 1:nrow(centers)){
		# for (j in 1:nrow(obj$statespace)){
			# gridchain[k,j] = sum(centers[k,]==j)
		# }
	# }
	#n.animals=apply(gridchain,2,sum)
	
	mcmchistin = obj$mcmchist
	# Remove NA column that acts as telemetry habitat covariate placeholder
	obj$mcmchist= obj$mcmchist[, 1:15]
	# if iter is a character defining a functioning passed to apply...
	if (any(is.character(iter))){
		if(iter!="all"){
			iter = match.fun(iter)
			param.values = apply(obj$mcmchist,2,iter)
			param.values = array(param.values,c(ifelse(is.matrix(param.values),nrow(param.values),1),ncol(obj$mcmchist)))
			colnames(param.values) = colnames(obj$mcmchist)
			iter.idx = rep(NA, nrow(param.values))
			for(N in 1:nrow(param.values)){
				iter.idx[N] = sample(which(abs(obj$mcmchist[,"Nsuper"]-param.values[N,"Nsuper"])==min(abs(obj$mcmchist[,"Nsuper"]-param.values[N,"Nsuper"]))),1)	
			}
			
			
# Compute activity centers for each iteration of the chain
			centers= matrix(obj$Sout[iter.idx,]*obj$zout[iter.idx,], nrow=length(iter.idx),ncol=ncol(obj$Sout))
			gridchain = matrix(nrow=nrow(centers),ncol=nrow(obj$statespace))
	
			for (k in 1:nrow(centers)){
				for (j in 1:nrow(obj$statespace)){
					gridchain[k,j] = sum(centers[k,]==j)
				}
			}
			
			n.animals.iter = gridchain
# These lines select the location of the activity centers from the iteration
# that is closest to the desired total number of animals
# In case of a tie, the selection is made randomly from the equivalent candidates
			# Nsuper.iter = c(apply(matrix(rowSums(gridchain),ncol=1),2,iter))
			# n.animals.iter = matrix(NA, nrow=nrow(param.values), ncol = ncol(gridchain))
			# for (N in 1:length(Nsuper.iter)){
				# n.animals.iter[N,] = gridchain[which(abs(rowSums(gridchain)-Nsuper.iter[N])==min(abs(rowSums(gridchain)-Nsuper.iter[N])))[sample(sum(abs(rowSums(gridchain)-Nsuper.iter[N])==min(abs(rowSums(gridchain)-Nsuper.iter[N]))), 1)],]
			# }	
			
			# n.animals.iter = array(n.animals.iter,c(ifelse(is.matrix(n.animals.iter), nrow(n.animals.iter),1),ncol(gridchain)))
		}
	}else{
	
	# If iter is a numeric giving which iterations of the chain to work with...
	if (any(is.numeric(iter))){
		param.values = obj$mcmchist[iter,]
		param.values = array(param.values,c(ifelse(is.matrix(param.values),nrow(param.values),1),ncol(obj$mcmchist)))
		colnames(param.values) = colnames(obj$mcmchist)
		# Compute activity centers for each iteration of the chain
		centers= matrix(obj$Sout[iter,]*obj$zout[iter,], nrow=length(iter),ncol=ncol(obj$Sout))
		gridchain = matrix(nrow=nrow(centers),ncol=nrow(obj$statespace))

		for (k in 1:nrow(centers)){
			for (j in 1:nrow(obj$statespace)){
				gridchain[k,j] = sum(centers[k,]==j)
			}
		}
		
		n.animals.iter = gridchain
	}
	# Finally, iter can specify all values from the MCMC chain
	# I use this as the null/default option
	if (any(c(iter =="all",is.null(iter)))){
		param.values = obj$mcmchist
		
		# Compute activity centers for each iteration of the chain
			centers= (obj$Sout*obj$zout)
			gridchain = matrix(nrow=nrow(centers),ncol=nrow(obj$statespace))
	
			for (k in 1:nrow(centers)){
				for (j in 1:nrow(obj$statespace)){
					gridchain[k,j] = sum(centers[k,]==j)
				}
			}
			
		n.animals.iter = gridchain
	}
	}
	# String together necessary info to be passed to internal function (below)
	inputs = list("obj"=obj,"param.values"=param.values, "n.animals.iter"=n.animals.iter,"SO"=SO, "Mb"=Mb, "Mbvalue"=Mbvalue, "Msex"=Msex, "Msexsigma"=Msexsigma, "Xsex"=Xsex, "Mss"=Mss,"Xd"=Xd,"Meff"=Meff, "Xeff" = Xeff, "scalein"=scalein)
	
	# postProb calculates the effective areas, population sizes and densities 
	# for given parameter values, locations of activity centers, and covariates
	postProb = function(i,inputs){
		obj = inputs$obj
		param.values = inputs$param.values
		n.animals.iter = inputs$n.animals.iter
		SO = inputs$SO
		Mb = inputs$Mb
		Mbvalue = inputs$Mbvalue
		Msex = inputs$Msex
		Msexsigma = inputs$Msexsigma
		Xsex = inputs$Xsex
		Mss = inputs$Mss
		Xd =inputs$Xd
		Meff = inputs$Meff
		Xeff = inputs$Xeff
		scalein = inputs$scalein
		
		
	cat(paste('Processing iteration',i,"of",nrow(param.values),sep=" "),fill=TRUE)

	# Calculate sigma and baseline detection probability
	# Use weighted mean when no/NULL Xsex specified  
	if (is.null(Xsex)){
		sigma <- weighted.mean(c(param.values[i,1],param.values[i,3]),c(1-param.values[i,"psi.sex"],param.values[i,"psi.sex"]))
		# Calculate baseline detection probability
		# Again, I use a weighted avg for sex-based differences
		loglam0 =(param.values[i,"loglam0"] + Msex*param.values[i,"psi.sex"]*param.values[i,"beta.sex"])
	} else { # When Xsex is specified calculate exposure probability for given sex
		sigma <- weighted.mean(c(param.values[i,1],param.values[i,3]),c(1-Xsex,Xsex))
		# Calculate baseline detection probability
		# Again, I use a weighted avg for sex-based differences
		loglam0 =(param.values[i,"loglam0"] + Msex*Xsex*param.values[i,"beta.sex"])	
	}
	
	# Reconstruct the trap locations on the original scale
	ss.x <- sort(unique(obj$statespace$X_coord))
	ss.y <- rev(sort(unique(obj$statespace$Y_coord)))
	coord.scale <- ((obj$Gunscaled[,1]-min(obj$Gunscaled[,1]))/(obj$G[,1]-min(obj$G[,1])))[nrow(obj$Gunscaled)]
	traplocs.utm = data.frame(t((t(as.matrix(obj$traplocs))-apply(obj$G,2,min))*coord.scale + apply(obj$Gunscaled,2,min)))
	
	
	# Create matrix to store the probability of capture in any trap given the 
	# location of activity center
	prob.anycap <- matrix(NA, nrow=length(ss.y), ncol = length(ss.x))
		
		for (x in ss.x){ # For each x coord of statespace...
		  for (y in ss.y){ # For each y coord of statespace...
			# Distance to all traps		
		    temp.dist <- sqrt((traplocs.utm[,1]-x)^2+(traplocs.utm[,2]-y)^2) # Find distance from central node
		    # Compute the linear predictor components
		    lp.eff =  ifelse(Meff==0,0,param.values[i,"beta1(effort)"]*Xeff)
		    lp.behav = ifelse(Mb==0,0,Mbvalue*param.values[i,"beta.behave"])
		    lp.dens = ifelse(Mss==0,0,(Xd[obj$statespace$X_coord==x&obj$statespace$Y_coord==y]*param.values[i,"beta.density"]-(log(sum(exp(Xd*param.values[i,"beta.density"]))))))
		    # Add all the lps, convert to probability of capture in a trap
		    prob.cap <-1 - exp(-exp(loglam0-sigma*(temp.dist/coord.scale)^(2*param.values[i,"theta"])+lp.eff+lp.behav+lp.dens))
		    # Store probability of capture in ANY trap 
		    prob.anycap[which(ss.y==y), which(ss.x==x)] <- 1- prod(1-prob.cap)^SO
		  }
		}
		# Find Resolution of statespace
		ss.res = c(unique(round(as.numeric(names(table(diff(sort(ss.x))))))),unique(round(as.numeric(names(table(diff(sort(ss.y))))))))
		prob.rast = raster(prob.anycap, xmn = min(obj$statespace$X_coord)-ss.res[1]/2, xmx=max(obj$statespace$X_coord)+ss.res[1]/2, ymn=min(obj$statespace$Y_coord)-ss.res[2]/2, ymx=max(obj$statespace$Y_coord)+ss.res[2]/2)
		res(prob.rast) = ss.res
		n.animalsr.iter = raster(nrows = length(unique(obj$statespace$Y_coord)), ncols = length(unique(obj$statespace$X_coord)),xmn = min(obj$statespace$X_coord)-ss.res[1]/2, xmx=max(obj$statespace$X_coord)+ss.res[1]/2, ymn=min(obj$statespace$Y_coord)-ss.res[2]/2, ymx=max(obj$statespace$Y_coord)+ss.res[2]/2)
		res(n.animalsr.iter) = ss.res
		
		ss.sp <- SpatialPointsDataFrame(obj$statespace[,1:2],data=data.frame('n.animals'=n.animals.iter[i,]))
		# Making abundance raster
		n.animalsr.iter <- rasterize(ss.sp, n.animalsr.iter, 'n.animals')
		# Calculate density scaling factor
		# Effective area
		area.iter <- sum(prob.anycap)*(prod(ss.res/scalein))
		popcontrib.iter <- n.animalsr.iter*prob.rast
		# Effective number of exposed individuals
		ngrid.iter <- cellStats(popcontrib.iter,'sum')
		# Density within the effective area violates assumption that
		# Density is uniform acrosss statespace used to calculate ESA
		# Compute density with scaling
		#density.iter <- ngrid.iter/area.iter *(scaleout/scalein)
		out1 = list("chain"=c(param.values[i,], "area"=area.iter,"Nexpected"=ngrid.iter),"prob.anycap"=prob.anycap)
		return(out1)
	}

# If using snowfall for multicore computations, useful for many interations
	if (useSnowfall){
		require(snowfall)
		sfInit(parallel=TRUE, cpus=nprocs,type=con.type)
		sfLibrary(sp)
		sfLibrary(raster)
		sfExport("postProb")
		
		out1 = sfLapply(1:nrow(param.values),postProb,inputs)
		sfStop()
	} else { # Otherwise series computations using lapply
		out1 = lapply(1:nrow(param.values),postProb,inputs)
	}

# Re-arrange output
	params = t(sapply(out1,"[[",1) )
	probs = sapply(out1,"[[",2)
# Return the updated mcmchist and 
# the corresponding exposure probabilities (can be mapped)	
	return(list("mcmchist" = params, "prob.cap"=probs))
	
}