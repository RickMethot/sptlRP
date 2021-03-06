## Revamp of FISH 559 HW3 for Spatial Refpts Paper
## M S Kapur 2020 Summer kapurm@uw.edu

rm(list = ls())
  options(scipen = 0)
  require(ggplot2, quietly = T)
  require(reshape)
  require(dplyr, quietly = T)
  require(here)
  require(ggsidekick)
  
  
## load data and introduce some demographic variation among areas
  dat0 <- read.table(here("R","HOME3.txt"), header = T)
    narea = 3
  nages = 21
  steep = 0.5
  dat <- array(NA, dim = c(nages,ncol(dat0),narea)) ## placeholder
    
## first area is original
    dat[,,1:3] <- as.matrix(dat0)
## second area, both sexes grow 15% larger, but with same fertility schedule
      dat[,3:4,2] <- dat[,3:4,1]*1.5
## third area, productive at early age
    dat[1:18,2,3] <- dat[4:21,2,1]
    dat[18:20,2,3] <- dat[18,2,3]
    

    
    
    
    doNage <- function(X = X_ija, ## input movement matrix
                       indat = dat, ## with bio info'
                       s = 1, ## F = 1, M = 2
                       Fv = rep(0,narea),
                       M = 0.15) {
      N_ai <- Z_ai <- B_ai <- SB_ai<- matrix(NA, nrow = nages, ncol = narea) ## placeholder
      
      for(a in 1:nages){
        if(a == 1) N_ai[a,] <- 0.5 ## inits
        for(i in 1:narea){
          Z_ai[a,i] <- M + indat[a,s+4,i]*Fv[i] ## female selex for now (cols 5:6)
          
          if(a > 1  & a < max(nages)) {
            pLeave = NCome = 0
            for(j in 1:narea){
              if(i != j){
                pLeave = pLeave + X_ija[i,j,a-1]
                NCome = NCome + X_ija[j,i,a-1]*N_ai[a-1,j]
                # if(is.na(NCome)) stop("NA NCOME at",a,i,j,"\n")
              } # end i != j
            } # end subareas j
            N_ai[a,i] <- ((1-pLeave)* N_ai[a-1,i] +NCome)*exp(-Z_ai[a-1,i])
            # if(is.na(N_ai[a,i])) stop("NA NAI at",a,i,"\n")
          } ## end age < maxage
          if(a == max(nages)) N_ai[a,i] <-  N_ai[a-1,i]*exp(-Z_ai[a-1,i])/(1- exp(-Z_ai[a,i]))
        } # end ages
        B_ai[a,i] <- N_ai[a,i]*indat[a,s+2,i] ## weight in 3 and 4 col
        if(s == 1){
          SB_ai[a,i]  <- NA
          SB_ai[a,i]  <- B_ai[a,i]*indat[a,1,i]
        } 
        B_i <- sum(B_ai[,i])
        SB_i <- sum(SB_ai[,i])
      } ## end subareas i
      return(cbind(N_ai,Z_ai,sum(B_i), sum(SB_i)))
    }
    
## returns area-specific N@age and Z@age
 
                  
                  
                  doYPR <-function( Fv= rep(0.2,narea), M = 0.15 ) {
                    ypr_sa <- array(NA, dim = c(1,2,narea)) ## each sex by area
                    ypr_a <- matrix(NA, nrow = 1, ncol = narea) ## each  area
                    ypr  <- NA  ## total
                    for(i in 1:narea){
                      for(s in 1:2){ ## loop sexes
                        wt <- dat[,s+2,i] ## cols 2 & 3
                        nzmat <-  doNage(s = s, Fv = Fv) ## expects 3 FV values
                        n_a <- nzmat[,i]
                        z_a <- nzmat[,i+3]
## Baranov
                        ypr_sa[1,s,i] <- sum(wt*(( dat[,s+4,i]*Fv[i])/z_a)*n_a*(1-exp(-z_a)))
                      } ## end sexes
                        ypr_a[i] <- sum(ypr_sa[1,,i])
                    } ## end areas
                      ypr <- sum(ypr_a)
                      return(list(ypr_sa,ypr_a,ypr))
                  }
                
                
                
                
                getAB <- function(SRR = 1, h = steep, R0 = 1, gam = 1){
                  sbpr0 <- NULL
                  for(i in 1:narea){
## always calculate at F = 0
                    sbpr0[i] <-   sum(dat[,2,i] * doNage(Fv = rep(0, narea))[,i]) 
                    alpha <- sbpr0[i]*((1-h)/(4*h))
                    beta <- (5*h-1)/(4*h*R0) 
                  }
#list(dat$Sel.f., dat$Sel.m.)[[1]])[, 1])
# if(SRR == 1){ 
## bev-hold
                  
# } else  if(SRR == 2){
#   alpha <- exp(log(5*h)/0.8)/sbpr0
#   beta <- log(5*h)/(0.8*sbpr0*R0)
# } else   if(SRR == 3){
#   alpha <- 1/sbpr0
#   beta <- (5*h-1)/(1 - 0.2^gam) 
# }
                  return(c("alpha" = alpha, "beta" = beta))
                }
                
                doSRR <- function( SRR = 1,Fv =rep(0,narea), h = steep, gam = 1, R0 = 1, S0 = 0.6739975){
                  sumSBPR <- R <- NULL
                  for(i in 1:narea){
                    
## get s-tilde
                    sumSBPR[i] <- sum(dat[,2,i]*doNage(Fv = Fv))
# sumSBPR[i] <- sum(dat[,2,i]*doNage(s = 1, Fv =  Fv)[,i])
# sumSBPR <- sum(sbpr)
# if(SRR == 1){ ## bevholt
# um(doNage(s = 1, Fv = Fv)[,i+9])#
                      ab <- getAB(SRR = 1, h = steep)
                      R[i] <- ( sumSBPR[i] - ab[1] )/(ab[2] *   sumSBPR[i]) ## Equation 9
                    rm(ab)
# } else if(SRR == 2){ ## ricker
#   ab <- getAB(SRR = 2, h = steep)
#   R <- log(ab[1]*sumSBPR)/(ab[2]*sumSBPR) ## Question 1A
# } else if(SRR == 3){ ## Pella
#   ab <- getAB(SRR = 3, h = steep)
#   R <- (S0/sumSBPR) * (1 - (1 - ab[1] * sumSBPR)/(ab[2] * ab[1] * sumSBPR))^(1/gam) ## Question 1B
}
                    return(list('rec' = as.numeric(R),'spawnbio' = sumSBPR))
                  }
                  
                  doYield <- function(ypr, R){
                    yield_a <- yield_tot <- NULL
                    for(i in 1:narea){
                      yield_a[i] <- ypr[i]*R[i]
                    }
                    yield_tot <- sum(yield_a)
                      return(list(yield_a,yield_tot))
                  } 
                  
                  


doNage <- function(X = X_ija, ## input movement matrix
                     indat = dat, ## with bio info'
                     s = 1, ## F = 1, M = 2
                     Fv = rep(0,narea),
                       M = 0.15) {
  N_ai <- Z_ai <- B_ai <- SB_ai<- matrix(NA, nrow = nages, ncol = narea) ## placeholder
  
  for(a in 1:nages){
    if(a == 1) N_ai[a,] <- 0.5 ## inits
      for(i in 1:narea){
        Z_ai[a,i] <- M + indat[a,s+4,i]*Fv[i] ## female selex for now (cols 5:6)
          
          if(a > 1  & a < max(nages)) {
            pLeave = NCome = 0
            for(j in 1:narea){
              if(i != j){
                pLeave = pLeave + X_ija[i,j,a-1]
                NCome = NCome + X_ija[j,i,a-1]*N_ai[a-1,j]
# if(is.na(NCome)) stop("NA NCOME at",a,i,j,"\n")
              } # end i != j
            } # end subareas j
              N_ai[a,i] <- ((1-pLeave)* N_ai[a-1,i] +NCome)*exp(-Z_ai[a-1,i])
# if(is.na(N_ai[a,i])) stop("NA NAI at",a,i,"\n")
          } ## end age < maxage
            if(a == max(nages)) N_ai[a,i] <-  N_ai[a-1,i]*exp(-Z_ai[a-1,i])/(1- exp(-Z_ai[a,i]))
              B_ai[a,i] <- N_ai[a,i]*indat[a,s+2,i] ## weight in 3 and 4 col
              if(s == 1){
                SB_ai[a,i]  <- NA
                SB_ai[a,i]  <- B_ai[a,i]*indat[a,1,i]
              }
      } # end 
  } ## end 
    return(cbind(N_ai,Z_ai, B_ai, SB_ai))
}