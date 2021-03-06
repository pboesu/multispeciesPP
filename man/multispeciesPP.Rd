\name{multispeciesPP}
\alias{multispeciesPP}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
  Fit multispecies proportional bias models.
}
\description{
  Fit the model described in the Proportional Bias Model paper.
}
\usage{
multispeciesPP(sdm.formula, bias.formula, PA, PO, BG, species = names(PO), species.PA = species, species.PO = species, quadrat.size = 1, region.size = 1, start = NULL, inverse.hessian = FALSE, penalty.l2.sdm = 0.1, penalty.l2.bias = 0.1, penalty.l2.intercept = 1e-04, weights = rep(1, n.species * nrow(x)), control = list())
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{sdm.formula}{
    Formula for dependence of the species process on environmental covariates
  }
  \item{bias.formula}{
    Formula for dependence of the observer bias on covariates
  }
  \item{PA}{
    Presence-absence data, as a data frame
  }
  \item{PO}{
    Presence-only data, as a list of data frames whose names are the species
  }
  \item{BG}{
    Background data, as a data frame
  }
  \item{species}{
    Names of the species
  }
  \item{species.PA}{
    Species contributing PA data
  }
  \item{species.PO}{
    Species contributing PO data
  }
  \item{quadrat.size}{
    Size of presence-absence quadrats
  }
  \item{region.size}{
    Size of study region
  }
  \item{start}{
    Optional argument giving initial coefficients.  These should be in
    standardized form; i.e. they should correspond to a model with the
    covariates centered and scaled.
  }
  \item{inverse.hessian}{
    Not currently used
  }
  \item{penalty.l2.sdm}{
    L2 penalty on coefficients for the species intensity
  }
  \item{penalty.l2.bias}{
    L2 penalty on coefficients for the bias
  }
  \item{penalty.l2.intercept}{
    L2 penalty on the intercepts
  }
  \item{weights}{
    Observation weights
  }
  \item{control}{
    Analogous to \code{control} for \code{glm.fit}
  }
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
  William Fithian
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (sdm.formula, bias.formula, PA, PO, BG, species = names(PO),
    species.PA = species, species.PO = species, quadrat.size = 1,
    region.size = 1, start = NULL, inverse.hessian = FALSE, penalty.l2.sdm = 0.1,
    penalty.l2.bias = 0.1, penalty.l2.intercept = 1e-04, weights = rep(1,
        n.species * nrow(x)), control = list())
{
    control <- do.call("glm.control", control)
    species <- union(species.PO, species.PA)
    sdm.formula <- update(sdm.formula, ~. + 1)
    bias.formula <- update(bias.formula, ~. - 1)
    sdm.mf <- model.frame(sdm.formula, data = BG)
    bias.mf <- model.frame(bias.formula, data = BG)
    sdm.BG.model.matrix <- model.matrix(terms(sdm.mf), BG)
    sdm.means <- c(0, apply(sdm.BG.model.matrix[, -1, drop = FALSE],
        2, mean))
    sdm.BG.model.matrix <- sweep(sdm.BG.model.matrix, 2, sdm.means,
        "-")
    sdm.sds <- c(1, apply(sdm.BG.model.matrix[, -1, drop = FALSE],
        2, sd))
    sdm.BG.model.matrix <- sweep(sdm.BG.model.matrix, 2, sdm.sds,
        "/")
    sdm.standardize <- function(mat) sweep(sweep(mat, 2, sdm.means,
        "-"), 2, sdm.sds, "/")
    bias.BG.model.matrix <- model.matrix(terms(bias.mf), BG)
    bias.means <- apply(bias.BG.model.matrix, 2, mean)
    bias.BG.model.matrix <- sweep(bias.BG.model.matrix, 2, bias.means,
        "-")
    bias.sds <- apply(bias.BG.model.matrix, 2, sd)
    bias.BG.model.matrix <- sweep(bias.BG.model.matrix, 2, bias.sds,
        "/")
    bias.standardize <- function(mat) sweep(sweep(mat, 2, bias.means,
        "-"), 2, bias.sds, "/")
    BG.good.rows <- intersect(rownames(sdm.BG.model.matrix),
        rownames(bias.BG.model.matrix))
    sdm.PA.model.matrix <- sdm.standardize(model.matrix(terms(sdm.mf),
        PA))
    PA.good.rows <- rownames(sdm.PA.model.matrix)
    if (!is.null(species.PO)) {
        sdm.PO.model.matrices <- lapply(as.list(species.PO),
            function(sp) sdm.standardize(model.matrix(terms(sdm.mf),
                PO[[sp]])))
        names(sdm.PO.model.matrices) <- species.PO
        bias.PO.model.matrices <- lapply(as.list(species.PO),
            function(sp) bias.standardize(model.matrix(terms(bias.mf),
                PO[[sp]])))
        names(bias.PO.model.matrices) <- species.PO
        PO.good.rows <- lapply(as.list(species.PO), function(sp) intersect(rownames(sdm.PO.model.matrices[[sp]]),
            rownames(bias.PO.model.matrices[[sp]])))
        names(PO.good.rows) <- species.PO
    }
    n.species <- length(species)
    p.sdm <- ncol(sdm.BG.model.matrix) - 1
    p.bias <- ncol(bias.BG.model.matrix)
    sdm.margins.ab <- matrix(0, n.species, p.sdm + 1, dimnames = list(species,
        colnames(sdm.BG.model.matrix)))
    sdm.margins.gamma <- matrix(0, n.species, 1, dimnames = list(species,
        "isPO"))
    bias.margins <- matrix(0, 1, p.bias, dimnames = list(NULL,
        colnames(bias.BG.model.matrix)))
    for (sp in species.PO) {
        k <- match(sp, species)
        sdm.margins.ab[k, ] <- colSums(sdm.PO.model.matrices[[sp]][PO.good.rows[[sp]],
            , drop = FALSE])
        sdm.margins.gamma[k, ] <- length(PO.good.rows[[sp]])
        bias.margins <- bias.margins + colSums(bias.PO.model.matrices[[sp]][PO.good.rows[[sp]],
            , drop = FALSE])
    }
    abcd.from.all.coef <- function(all.coef) {
        sdm.coef <- matrix(all.coef[1:(n.species * (p.sdm + 2))],
            p.sdm + 2, n.species)
        alpha <- sdm.coef[1, ]
        beta <- t(sdm.coef[2:(p.sdm + 1), , drop = FALSE])
        gamma <- sdm.coef[p.sdm + 2, ]
        delta <- all.coef[-(1:(n.species * (p.sdm + 2)))]
        names(alpha) <- names(gamma) <- species
        colnames(beta) <- colnames(sdm.margins.ab)[-1]
        rownames(beta) <- species
        names(delta) <- colnames(bias.BG.model.matrix)
        return(list(alpha = alpha, beta = beta, gamma = gamma,
            delta = delta))
    }
    all.coef.from.abcd <- function(alpha, beta, gamma, delta) {
        c(rbind(alpha, beta, gamma), delta)
    }
    n.PA <- length(PA.good.rows)
    n.BG <- length(BG.good.rows)
    subsamp.PA.offset <- 0
    subsamp.BG.offset <- 0
    n.sites <- n.BG + n.PA
    x <- cbind(rbind(sdm.margins.ab, 0, sdm.PA.model.matrix[PA.good.rows,
        , drop = FALSE], sdm.BG.model.matrix[BG.good.rows, ,
        drop = FALSE]), c(sdm.margins.gamma, rep(0:1, c(1 + n.PA,
        n.BG))))
    x <- rbind(x, diag(sqrt(c(penalty.l2.intercept, rep(penalty.l2.sdm,
        p.sdm), penalty.l2.intercept))), matrix(0, p.bias, p.sdm +
        2))
    z <- rbind(matrix(0, n.species, p.bias), bias.margins, matrix(0,
        n.PA, p.bias), bias.BG.model.matrix[BG.good.rows, , drop = FALSE],
        matrix(0, p.sdm + 2, p.bias), sqrt(penalty.l2.bias/n.species) *
            diag(p.bias))
    y <- rep(0, nrow(x) * n.species)
    offset <- rep(0, nrow(x) * n.species)
    for (k in 1:n.species) {
        yk <- rep(0, nrow(x))
        yk[1:n.species] <- 1 * (1:n.species == k)
        yk[1 + n.species] <- 1 * (1 == k)
        if (species[k] \%in\% species.PA) {
            yk[1 + n.species + (1:n.PA)] <- PA[PA.good.rows,
                species[k]]
        }
        else {
            yk[1 + n.species + (1:n.PA)] <- NA
        }
        if (species[k] \%in\% species.PO) {
            yk[1 + n.species + n.PA + (1:n.BG)] <- 0
        }
        else {
            yk[1 + n.species + n.PA + (1:n.BG)] <- NA
        }
        yk[1 + n.species + n.sites + (1:(p.sdm + 2 + p.bias))] <- 0
        y[(k - 1) * nrow(x) + 1:nrow(x)] <- yk
        offk <- rep(0, nrow(x))
        offk[1 + n.species + (1:n.PA)] <- log(quadrat.size)
        offk[1 + n.species + n.PA + (1:n.BG)] <- log(region.size) -
            log(n.BG)
        offset[(k - 1) * nrow(x) + 1:nrow(x)] <- offk
    }
    which.PA <- (2 + n.species):(1 + n.species + n.PA) + rep((0:(n.species -
        1)) * nrow(x), each = n.PA)
    which.BG <- (2 + n.species + n.PA):(1 + n.species + n.PA +
        n.BG) + rep((0:(n.species - 1)) * nrow(x), each = n.BG)
    if (is.null(start)) {
        start.alpha <- start.gamma <- rep(0, n.species)
        for (k in 1:n.species) {
            if ((species[k] \%in\% species.PA) && sum(!is.na(PA[PA.good.rows,
                species[k]]) > 0))
                start.alpha[k] <- log((1 + sum(PA[PA.good.rows,
                  species[k]], na.rm = TRUE))/n.PA/quadrat.size)
            if (species[k] \%in\% species.PO)
                start.gamma[k] <- log1p(sdm.margins.gamma[k,
                  ]) - start.alpha[k] - log(region.size)
        }
        start <- all.coef.from.abcd(start.alpha, matrix(0, p.sdm,
            n.species), start.gamma, rep(0, p.bias))
    }
    fit <- block.glm.fit(x, z, y, weights = weights, start = start,
        offset = offset, families = list(linear(), binomial(link = "cloglog"),
            poisson(), gaussian()), row.families = rep(rep(1:4,
            c(1 + n.species, n.PA, n.BG, p.sdm + p.bias + 2)),
            n.species), control = control)
    all.coef <- fit$coefficients
    eta <- fit$linear.predictors
    mu <- fit$fitted.values
    names(all.coef)[1:(n.species * (p.sdm + 2))] <- paste(rep(species,
        each = p.sdm + 2), c(colnames(sdm.BG.model.matrix)[1:(p.sdm +
        1)], "isPO"), sep = ":")
    names(all.coef)[-(1:(n.species * (p.sdm + 2)))] <- paste("isPO:",
        colnames(bias.BG.model.matrix), sep = "")
    std.errs <- fit$fit$std.errs
    names(std.errs) <- names(all.coef)
    species.coef <- matrix(all.coef[1:(n.species * (p.sdm + 2))],
        p.sdm + 2, n.species, dimnames = list(c(colnames(sdm.margins.ab),
            "isPO"), species))
    bias.coef <- all.coef[-(1:(n.species * (p.sdm + 2)))]
    names(bias.coef) <- colnames(bias.BG.model.matrix)
    fit.PA <- linear.fit.PA <- matrix(NA, nrow(PA), length(species),
        dimnames = list(dimnames(PA)[[1]], species))
    linear.fit.PA[PA.good.rows, ] <- eta[which.PA]
    fit.PA[PA.good.rows, ] <- mu[which.PA]
    fit.BG <- linear.fit.BG <- bias.fit.BG <- linear.bias.fit.BG <- matrix(NA,
        nrow(BG), length(species), dimnames = list(dimnames(BG)[[1]],
            species))
    linear.fit.BG[BG.good.rows, ] <- matrix(eta[which.BG], ncol = n.species) +
        log(n.BG) - log(region.size)
    fit.BG[BG.good.rows, ] <- matrix(mu[which.BG], ncol = n.species) *
        n.BG/region.size
    linear.bias.fit.BG[BG.good.rows, ] <- c(bias.BG.model.matrix[BG.good.rows,
        , drop = FALSE] \%*\% bias.coef)
    bias.fit.BG[BG.good.rows, ] <- exp(linear.bias.fit.BG[BG.good.rows,
        ])
    fitted.sdm.margins.gamma <- colSums(fit.BG[BG.good.rows,
        , drop = FALSE]) * region.size/n.BG
    fitted.bias.margins <- colSums(t(fit.BG[BG.good.rows, species.PO,
        drop = FALSE]) \%*\% bias.BG.model.matrix[BG.good.rows,
        , drop = FALSE] * region.size/n.BG)
    score.check.gamma <- fitted.sdm.margins.gamma - sdm.margins.gamma +
        penalty.l2.intercept * species.coef[p.sdm + 2, ]
    score.check.gamma <- score.check.gamma[species \%in\% species.PO]
    score.check.bias <- fitted.bias.margins - bias.margins +
        penalty.l2.bias * bias.coef
    if (length(score.check.gamma) > 0)
        stopifnot(mean((score.check.gamma/fit$deviance)^2) <
            control$epsilon)
    stopifnot(mean((score.check.bias/fit$deviance)^2) < control$epsilon)
    sd.normalizer <- c(rep(c(sdm.sds, 1), n.species), bias.sds)
    unstandardized.coef <- all.coef/sd.normalizer
    gamma.adjust <- sum(unstandardized.coef[-(1:(n.species *
        (p.sdm + 2)))] * bias.means)
    for (k in 1:n.species) {
        jk <- (p.sdm + 2) * (k - 1) + 1:(p.sdm + 1)
        coef.block <- unstandardized.coef[jk]
        unstandardized.coef[jk[1]] <- coef.block[1] - sum(coef.block[-1] *
            sdm.means[-1])
        unstandardized.coef[jk[1] + p.sdm + 1] <- unstandardized.coef[jk[1] +
            p.sdm + 1] - gamma.adjust
    }
    unstandardized.species.coef <- matrix(unstandardized.coef[1:(n.species *
        (p.sdm + 2))], p.sdm + 2, n.species, dimnames = list(c(colnames(sdm.margins.ab),
        "isPO"), species))
    unstandardized.bias.coef <- unstandardized.coef[-(1:(n.species *
        (p.sdm + 2)))]
    names(unstandardized.bias.coef) <- colnames(bias.BG.model.matrix)
    tr <- list(sdm.formula = sdm.formula, bias.formula = bias.formula,
        normalized.species.coef = species.coef, normalized.bias.coef = bias.coef,
        normalized.all.coef = all.coef, normalized.std.errs = std.errs,
        all.coef = unstandardized.coef, std.errs = std.errs/sd.normalizer,
        species.coef = unstandardized.species.coef, bias.coef = unstandardized.bias.coef,
        linear.fit.PA = linear.fit.PA, fit.PA = fit.PA, linear.bias.fit.BG = linear.bias.fit.BG,
        bias.fit.BG = bias.fit.BG, linear.fit.BG = linear.fit.BG,
        fit.BG = fit.BG)
    class(tr) <- c("multispeciesPP", "list")
    tr
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
