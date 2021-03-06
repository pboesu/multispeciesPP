\name{predict.multispeciesPP}
\alias{predict.multispeciesPP}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
  Predict species intensities or biased species intensities based on a
  multispeciesPP model.
}
\description{
  Predict species intensities or biased species intensities based on a
  multispeciesPP model.
}
\usage{
predict(object, newdata, sdm = TRUE, bias = FALSE, species = colnames(object$fit.PA), dispersion = NULL, terms = NULL, na.action = na.pass, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{object}{
%%     ~~Describe \code{object} here~~
}
  \item{newdata}{
%%     ~~Describe \code{newdata} here~~
}
  \item{sdm}{
%%     ~~Describe \code{sdm} here~~
}
  \item{bias}{
%%     ~~Describe \code{bias} here~~
}
  \item{species}{
%%     ~~Describe \code{species} here~~
}
  \item{dispersion}{
%%     ~~Describe \code{dispersion} here~~
}
  \item{terms}{
%%     ~~Describe \code{terms} here~~
}
  \item{na.action}{
%%     ~~Describe \code{na.action} here~~
}
  \item{\dots}{
%%     ~~Describe \code{\dots} here~~
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
function (object, newdata, sdm = TRUE, bias = FALSE, species = colnames(object$fit.PA),
    dispersion = NULL, terms = NULL, na.action = na.pass, ...)
{
    na.act <- object$na.action
    object$na.action <- NULL
    pred <- matrix(0, nrow(newdata), length(species), dimnames = list(rownames(newdata),
        species))
    if (sdm) {
        sdm.mat <- model.matrix(object$sdm.formula, newdata)
        good.rows <- row.names(sdm.mat)
        pred[!(row.names(pred) \%in\% good.rows), ] <- NA
        pred[good.rows, ] <- sdm.mat \%*\% object$species.coef[-nrow(object$species.coef),
            species]
    }
    if (bias) {
        bias.mat <- model.matrix(object$bias.formula, newdata)
        good.rows <- rownames(bias.mat)
        pred[!(row.names(pred) \%in\% good.rows), ] <- NA
        pred[good.rows, ] <- pred[good.rows, ] + bias.mat[good.rows,
            ] \%*\% object$bias.coef
        pred <- pred + rep(object$species.coef["isPO", species],
            each = nrow(pred))
    }
    pred
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
