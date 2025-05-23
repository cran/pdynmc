
#####################################################
###	Version information
#####################################################

###
###	Starting point
###

#	AhnSchmidt_Nonlinear_2017-11-07.R

#	split into different functions as of code version
#	AhnSchmidt_Nonlinear_2019-04-08.R


















############################################################################################################
### Standard specification tests (Wald, Hansen J-Test, Arellano and Bond serial correlation test)
############################################################################################################












#' Wald Test.
#'
#' \code{wald.fct} computes F test statistics and corresponding p-values for
#'    `pdynmc` objects.
#'
#' The three available null hypothesis are: All time dummies are jointly zero,
#'    all slope coefficients are jointly zero, all times dummies and slope
#'    coefficients are jointly zero.
#'
#' @param object An object of class `pdynmc`.
#' @param param A character string that denotes the null hypothesis. Choices are
#'    time.dum (i.e., all time dummies are jointly zero), slope (i.e., all slope
#'    coefficients are jointly zero), and all (i.e., all dummies and slope
#'    coefficients are jointly zero).
#' @return An object of class `htest` which contains the F test statistic and
#'    corresponding p-value for the tested null hypothesis.
#'
#' @export
#' @importFrom MASS ginv
#' @importFrom Matrix crossprod
#' @importFrom Matrix tcrossprod
#' @importFrom Matrix t
#' @importFrom stats pchisq
#'
#' @seealso
#'
#' \code{\link{pdynmc}} for fitting a linear dynamic panel data model.
#'
#'
#' @examples
#' ## Load data
#' data(ABdata, package = "pdynmc")
#' dat <- ABdata
#' dat[,c(4:7)] <- log(dat[,c(4:7)])
#' dat <- dat[c(140:0), ]
#'
#' ## Code example
#' m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#' wald.fct(param = "all", m1)
#'
#' \donttest{
#' ## Load data
#'  data(ABdata, package = "pdynmc")
#'  dat <- ABdata
#'  dat[,c(4:7)] <- log(dat[,c(4:7)])
#'
#' ## Further code example
#'  m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#'  wald.fct(m1, param = "all")
#' }
#'
#'
wald.fct 		<- function(
 object
 ,param
){

  if(!inherits(object, what = "pdynmc")){
    stop("Use only with \"pdynmc\" objects.")
  }

  if(param == "all"){
    params <- "time dummy and/or slope coefficient"
  } else{
    if(param == "time.dum"){
      params <- "time dummy"
    } else{
      if(param == "slope"){
        params <- "slope coefficient"
      }
    }
  }

  coef.est				<- ifelse((sapply(get(paste("step", object$iter, sep = ""), object$par.optim), FUN = is.na)),
						yes = get(paste("step", object$iter, sep = ""), object$par.clForm),
						no = get(paste("step", object$iter, sep = ""), object$par.optim) )
  dat.na				<- object$data$dat.na
  varname.y				<- object$data$varname.y
  varname.reg.estParam		<- object$data$varnames.reg
  varname.dum			<- object$data$varnames.dum
  vcov.est				<- get(paste("step", object$iter, sep = ""), object$vcov)
  estimation			<- object$data$estimation
  n					<- object$data$n
  Time					<- object$data$Time
  n.inst				<- object$data$n.inst
  Szero.j				<- get(paste("step", object$iter, sep = ""), object$residuals.int)



  K.tot		<- length(coef.est)
  if(length(varname.dum) > 1){
    K.t			<- length(varname.dum)
  } else{
    if(varname.dum == "no time dummies"){
      K.t     <- 0
    } else{
      K.t     <- 1
    }
  }

  if(param == "time.dum"){
    start		<- K.tot - K.t + 1
    end		<- K.tot
  }
  if(param == "slope"){
    start		<- 1
    end		<- K.tot - K.t
  }
  if(param == "all"){
    start		<- 1
    end		<- K.tot
  }

  coef.hat		<- coef.est[start:end]
  vcov.hat		<- vcov.est[start:end, start:end]

  if(object$data$estimation == "onestep"){
#    w.stat		<- n*crossprod(coef.hat, tcrossprod(MASS::ginv(vcov.hat), t(coef.hat)) ) *
#				(as.vector(crossprod(do.call(res.1s_temp, what = "c"), do.call(Szero.j, what = "c"), na.rm = TRUE) /(n*Time - sum(n.inst)+7)))						#[M:] Stata results with different dof-correction
    w.stat		<- n * Matrix::crossprod(coef.hat, Matrix::tcrossprod(MASS::ginv(as.matrix(vcov.hat)), Matrix::t(coef.hat)) ) *
				(as.vector(Matrix::crossprod(do.call(Szero.j, what = "c"))) /(sum(!is.na(dat.na[, varname.y])) - sum(n.inst)))		#[M:] Adjusted dof-correction (for missing observations)
  } else{
    w.stat		<- crossprod(coef.hat, tcrossprod(MASS::ginv(as.matrix(vcov.hat)), t(coef.hat)) )
  }

  names(w.stat)	<- "chisq"
  dof			<- length(coef.hat)
  names(dof)	<- "df"
  pval		<- stats::pchisq(w.stat, df = dof, lower.tail = FALSE)
  wald		<- list(statistic = w.stat, p.value = pval, parameter = dof, method = "Wald test"
				,data.name = paste(object$iter, "step GMM Estimation", sep = "")
				,alternative = paste("at least one ",  params," is not equal to zero", sep = "")
				)
  class(wald) <- "htest"
  return(wald)
}



















































#' Hansen J-Test.
#'
#' \code{jtest.fct} tests the validity of the overidentifying restrictions.
#'
#' The null hypothesis is that the overidentifying restrictions are valid.
#'    The test statistic is computed as proposed by
#'    \insertCite{Han1982large;textual}{pdynmc}. As noted by
#'    \insertCite{Bow2002testing;textual}{pdynmc} and
#'    \insertCite{Win2005;textual}{pdynmc}
#'    the test statistic is weakened by many instruments.
#'
#' @param object An object of class `pdynmc`.
#' @return An object of class `htest` which contains the Hansen J-test statistic
#'    and corresponding p-value for the null hypothesis that the overidentifying
#'    restrictions are valid.
#'
#' @export
#' @importFrom Matrix crossprod
#' @importFrom stats pchisq
#' @importFrom Rdpack reprompt
#'
#' @seealso
#'
#' \code{\link{pdynmc}} for fitting a linear dynamic panel data model.
#'
#' @references
#' \insertAllCited{}
#'
#'
#' @examples
#' ## Load data
#' data(ABdata, package = "pdynmc")
#' dat <- ABdata
#' dat[,c(4:7)] <- log(dat[,c(4:7)])
#' dat <- dat[c(140:0), ]
#'
#' ## Code example
#' m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#' jtest.fct(m1)
#'
#' \donttest{
#' ## Load data
#'  data(ABdata, package = "pdynmc")
#'  dat <- ABdata
#'  dat[,c(4:7)] <- log(dat[,c(4:7)])
#'
#' ## Further code example
#'  m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#'  jtest.fct(m1)
#' }
#'
#'
jtest.fct		<- function(
 object
){

  if(!inherits(object, what = "pdynmc")){
    stop("Use only with \"pdynmc\" objects.")
  }

  coef.est	    <- ifelse((sapply(get(paste("step", object$iter, sep = ""), object$par.optim), FUN = is.na)), yes = get(paste("step", object$iter, sep = ""), object$par.clForm), no = get(paste("step", object$iter, sep = ""), object$par.optim) )
  Szero.j		    <- get(paste("step", object$iter, sep = ""), object$residuals.int)
  Z.temp		    <- object$data$Z.temp
  stderr.type   <- object$data$stderr.type
  n.inst		    <- object$data$n.inst

  if(object$data$estimation == "onestep" && stderr.type == "corrected"){
    W.j			  <- object$w.mat[[2]]
    warning("Hansen J-Test statistic is inconsistent when error terms are non-spherical.")
  } else{
    W.j			  <- get(paste("step", object$iter, sep = ""), object$w.mat)
    Szero.j		<- get(paste("step", object$iter, sep = ""), object$residuals.int)
  }


  K.tot			<- length(coef.est)
  N				  <- length(do.call(what = "c", Szero.j))
  tzu				<- as.numeric(Reduce("+", mapply(function(x,y) Matrix::crossprod(x,y), Z.temp, Szero.j, SIMPLIFY = FALSE)))
  stat			<- as.numeric(Matrix::crossprod(tzu, Matrix::crossprod(W.j, tzu)))
  names(stat)		<- "chisq"
  p				      <- sum(n.inst)
  param			    <- p - K.tot
  names(param)	<- "df"
  method			  <- "J-Test of Hansen"
  pval			    <- stats::pchisq(stat, df = param, lower.tail = FALSE)
  jtest			    <- list(statistic = stat, p.value = pval, parameter = param, method = method
					            ,data.name = paste(object$iter, "step GMM Estimation", sep = "")
					            ,alternative = paste("overidentifying restrictions invalid", sep = "")
					            )
  class(jtest)		<- "htest"
  return(jtest)
}



















#' Sargan test.
#'
#' \code{sargan.fct} tests the validity of the overidentifying restrictions.
#'
#' The null hypothesis is that the overidentifying restrictions are valid.
#'    The test statistic is computed as proposed by
#'    \insertCite{Sar1958estimation;textual}{pdynmc}. As noted by
#'    \insertCite{Bow2002testing;textual}{pdynmc} and
#'    \insertCite{Win2005;textual}{pdynmc},
#'    the test statistic is weakened by many instruments and inconsistent
#'    in the presence of heteroscedasticity according to
#'    \insertCite{Roo2009StJ;textual}{pdynmc}.
#'
#' @param object An object of class `pdynmc`.
#' @return An object of class `htest` which contains the Sargan test statistic
#'    and corresponding p-value for the null hypothesis that the overidentifying
#'    restrictions are valid.
#'
#' @export
#' @importFrom Matrix crossprod
#' @importFrom stats pchisq
#' @importFrom Rdpack reprompt
#'
#' @seealso
#'
#' \code{\link{pdynmc}} for fitting a linear dynamic panel data model.
#'
#' @references
#'
#' \insertAllCited{}
#'
#'
#' @examples
#' ## Load data
#' data(ABdata, package = "pdynmc")
#' dat <- ABdata
#' dat[,c(4:7)] <- log(dat[,c(4:7)])
#' dat <- dat[c(140:0), ]
#'
#' ## Code example
#' m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#' sargan.fct(m1)
#'
#' \donttest{
#' ## Load data
#'  data(ABdata, package = "pdynmc")
#'  dat <- ABdata
#'  dat[,c(4:7)] <- log(dat[,c(4:7)])
#'
#' ## Further code example
#'  m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#'  sargan.fct(m1)
#' }
#'
#'
sargan.fct 		<- function(
    object
){

  if(all(class(object) != "pdynmc")) stop("Object needs to be of class 'pdynmc'")

  estimation  <- object$data$estimation
  coef.est		<- ifelse((sapply(get(paste("step", object$iter, sep = ""), object$par.optim), FUN = is.na)), yes = get(paste("step", object$iter, sep = ""), object$par.clForm), no = get(paste("step", object$iter, sep = ""), object$par.optim) )
  Szero.j     <- get(paste("step", object$iter, sep = ""), object$residuals.int)
  Z.temp      <- object$data$Z.temp
  n.inst		  <- object$data$n.inst

  W.j			    <- object$w.mat[[1]]

  K.tot		  <- length(coef.est)
  N			    <- length(do.call(what = "c", Szero.j))
  tzu			  <- Reduce("+", mapply(function(x,y) Matrix::crossprod(x,y), Z.temp, Szero.j, SIMPLIFY = FALSE))
  stat		  <- as.numeric(Matrix::crossprod(tzu, Matrix::crossprod(W.j, tzu)))
  names(stat)	  <- "chisq"
  p			        <- sum(n.inst)
  param		      <- p - K.tot
  names(param)	<- "df"
  method		    <- "Sargan Test"
  pval		      <- stats::pchisq(stat, df = param, lower.tail = FALSE)
  sargan		    <- list(statistic = stat, p.value = pval, parameter = param, method = method,
                      data.name = paste(object$iter, "step GMM Estimation; H0: overidentifying restrictions valid", sep = "")
  )
  class(sargan)	<- "htest"
  return(sargan)
}


























#' Arellano and Bond Serial Correlation Test.
#'
#' \code{mtest.pdynmc} Methods to test for serial correlation in the error terms
#'    for objects of class `pdynmc`.
#'
#' The null hypothesis is that there is no serial correlation of a
#'    particular order. The test statistic is computed as proposed by
#'    \insertCite{AreBon1991;textual}{pdynmc} and
#'    \insertCite{Are2003;textual}{pdynmc}.
#'
#' @param object An object of class `pdynmc`.
#' @param order A number denoting the order of serial correlation to test for
#'    (defaults to `2`).
#' @param ... further arguments.
#'
#' @return An object of class `htest` which contains the Arellano and Bond m test
#'    statistic and corresponding p-value for the null hypothesis that there is no
#'    serial correlation of the given order.
#'
#' @export
#' @importFrom Matrix crossprod
#' @importFrom Matrix tcrossprod
#' @importFrom Matrix t
#' @importFrom stats pnorm
#' @importFrom Rdpack reprompt
#'
#' @seealso
#'
#' \code{\link{pdynmc}} for fitting a linear dynamic panel data model.
#'
#' @references
#' \insertAllCited{}
#'
#'
#' @examples
#' ## Load data
#' data(ABdata, package = "pdynmc")
#' dat <- ABdata
#' dat[,c(4:7)] <- log(dat[,c(4:7)])
#' dat <- dat[c(140:0), ]
#'
#' ## Code example
#' m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#' mtest.fct(m1, order = 2)
#'
#' \donttest{
#' ## Load data
#'  data(ABdata, package = "pdynmc")
#'  dat <- ABdata
#'  dat[,c(4:7)] <- log(dat[,c(4:7)])
#'
#' ## Further code example
#'  m1 <- pdynmc(dat = dat, varname.i = "firm", varname.t = "year",
#'     use.mc.diff = TRUE, use.mc.lev = FALSE, use.mc.nonlin = FALSE,
#'     include.y = TRUE, varname.y = "emp", lagTerms.y = 2,
#'     fur.con = TRUE, fur.con.diff = TRUE, fur.con.lev = FALSE,
#'     varname.reg.fur = c("wage", "capital", "output"), lagTerms.reg.fur = c(1,2,2),
#'     include.dum = TRUE, dum.diff = TRUE, dum.lev = FALSE, varname.dum = "year",
#'     w.mat = "iid.err", std.err = "corrected", estimation = "onestep",
#'     opt.meth = "none")
#'  mtest.fct(m1, order = 2)
#' }
#'
#'
mtest.fct 		<- function(
 object
 ,order = 2
 ,...
){

  if(!inherits(object, what = "pdynmc")){
    stop("Use only with \"pdynmc\" objects.")
  }

  estimation    <- object$data$estimation
  Szero.j       <- get(paste("step", object$iter, sep = ""), object$residuals.int)
  Z.temp        <- object$data$Z.temp
  vcov.est      <- get(paste("step", object$iter, sep = ""), object$vcov)
  W.j           <- get(paste("step", object$iter, sep = ""), object$w.mat)
  stderr.type   <- object$data$stderr.type
  std.err       <- get(paste("step", object$iter, sep = ""), object$stderr)
#  n.inst        <- object$data$n.inst
  varname.y     <- object$data$varname.y
  varname.reg   <- object$data$varnames.reg
  varname.dum   <- object$data$varnames.dum
  dat.clF.temp  <- rapply(lapply(object$dat.clF, FUN = as.matrix), function(x) ifelse(is.na(x), 0, x), how = "replace")
  n.obs				  <- nrow(object$data$dat.na) - sum(is.na(object$data$dat.na[, varname.y]))
  u.hat.m_o     <- lapply(Szero.j, function(x) c(rep(0, times = order), x[1:(length(x) - order)]))
  tZX           <- Reduce("+", mapply(function(x, y) Matrix::crossprod(x,y), Z.temp, dat.clF.temp, SIMPLIFY = FALSE))

  if(estimation == "onestep"){

    if(stderr.type == "unadjusted"){
      H_i           <- 0.5*object$H_i * as.numeric((1/(n.obs - length(object$coefficients))) * Reduce("+", mapply(function(x) Matrix::crossprod(x,x), Szero.j, SIMPLIFY = FALSE)))
      A             <- object$w.mat[[1]]
      M.inv         <- solve(Matrix::crossprod(tZX, Matrix::crossprod(A, tZX)))

      tu.m_oHu.m_o  <- Reduce("+", mapply(function(x) Matrix::crossprod(x, Matrix::crossprod(H_i, x)), u.hat.m_o, SIMPLIFY = FALSE))
      tZHu.m_o      <- Reduce("+", mapply(function(x, y) Matrix::crossprod(x, Matrix::crossprod(H_i, y)), Z.temp, u.hat.m_o, SIMPLIFY = FALSE))
    }

    if(stderr.type == "corrected"){
      H_1i          <- 0.5*object$H_i * as.numeric((1/(n.obs - length(object$coefficients))) * Reduce("+", mapply(function(x) Matrix::crossprod(x,x), Szero.j, SIMPLIFY = FALSE)))
      A             <- object$w.mat[[1]]
      M.inv         <- solve(Matrix::crossprod(tZX, Matrix::crossprod(A, tZX)))
      H_i           <- Reduce("+", mapply(function(x) Matrix::tcrossprod(x,x), Szero.j, SIMPLIFY = FALSE)) * as.numeric((1/(n.obs - length(object$coefficients))) * Reduce("+", mapply(function(x) Matrix::crossprod(x,x), Szero.j, SIMPLIFY = FALSE)))
      A_2N          <- object$w.mat[[2]]

      tu.m_oHu.m_o  <- Reduce("+", mapply(function(x,y) Matrix::crossprod(x, Matrix::crossprod(Matrix::tcrossprod(y,y), x)), u.hat.m_o, Szero.j, SIMPLIFY = FALSE))
      tZHu.m_o      <- Reduce("+", mapply(function(x,y,z) Matrix::crossprod(x, Matrix::crossprod(Matrix::tcrossprod(z,z), y)), Z.temp, u.hat.m_o, Szero.j, SIMPLIFY = FALSE))
      }

  }

  if(estimation != "onestep"){
    H_i             <- Reduce("+", mapply(function(x) Matrix::tcrossprod(x,x), Szero.j, SIMPLIFY = FALSE))
    A               <- W.j
    M.inv           <- solve(Matrix::crossprod(tZX, Matrix::crossprod(A, tZX)))

    tu.m_oHu.m_o    <- Reduce("+", mapply(function(x,y) Matrix::crossprod(x, Matrix::crossprod(Matrix::tcrossprod(y,y), x)), u.hat.m_o, Szero.j, SIMPLIFY = FALSE))
    tZHu.m_o        <- Reduce("+", mapply(function(x,y,z) Matrix::crossprod(x, Matrix::crossprod(Matrix::tcrossprod(z,z), y)), Z.temp, u.hat.m_o, Szero.j, SIMPLIFY = FALSE))
  }

  tu.m_oX         <- Reduce("+", mapply(function(x, y) Matrix::crossprod(x, y), u.hat.m_o, dat.clF.temp, SIMPLIFY = FALSE))
  frac.num        <- Reduce("+", mapply(function(x, y) crossprod(x, y), u.hat.m_o, Szero.j, SIMPLIFY = FALSE))
  frac.denom.sq   <- (as.numeric(tu.m_oHu.m_o -
                                 2 * Matrix::crossprod(Matrix::t(tu.m_oX),
                                                       Matrix::crossprod(M.inv, Matrix::crossprod(tZX, Matrix::tcrossprod(A, Matrix::t(tZHu.m_o))))) +
                                 Matrix::crossprod(Matrix::t(tu.m_oX), Matrix::tcrossprod(vcov.est, tu.m_oX))))
  if (frac.denom.sq < 0) {
    frac.denom <- sqrt(abs(frac.denom.sq))
    warning("Absolute value of denominator of test statistic was used in the computation.")
  } else {
    frac.denom <- sqrt(frac.denom.sq)
  }
  stat <- frac.num/frac.denom
  names(stat) <- "normal"
  pval <- 2 * stats::pnorm(abs(stat), lower.tail = FALSE)
  mtest <- list(statistic = stat, p.value = pval,
                method = paste("Arellano and Bond (1991) serial correlation test of degree",
                              order), data.name = paste(object$iter, "step GMM Estimation", sep = ""),
                alternative = paste("serial correlation of order ", order, " in the error terms", sep = ""))
  class(mtest) <- "htest"
  return(mtest)
}















