# Author: Robert J. Hijmans
# Date :  September 2011
# Version 1.0
# Licence GPL v3



.adjacentUD <- function(x, cells, ngb) {
	# ngb should be a matrix with 
	# one and only one cell with value 0 (the focal cell), 
	# at least one cell with value 1 (the adjacent cells)
	# cells with other values are ignored (not considered adjacent)
	rs <- res(x)

	rn <- raster(ngb)
	center <- which(values(rn)==0)
	rc <- rowFromCell(rn, center)
	cc <- colFromCell(rn, center)
	
	xngb <- yngb <- ngb
	xngb[] <- rep(1:ncol(ngb), each=nrow(ngb)) - cc 
	yngb[] <- rep(nrow(ngb):1, ncol(ngb)) - (nrow(ngb)-rc+1)
	ngb[ngb != 1] <- NA
	xngb <- as.vector( xngb * rs[1] * ngb)
	yngb <- as.vector( yngb * rs[2] * ngb)
	
	xy <- xyFromCell(x, cells)
	x <- apply(xy[,1,drop=FALSE], 1, function(z) z + xngb )
	y <- apply(xy[,2,drop=FALSE], 1, function(z) z + yngb )

	c(as.vector(x), as.vector(y))
}


adjacent <- function(x, cells, directions=4, pairs=FALSE, target=NULL, sorted=FALSE) {

	if (is.character(directions)) { directions <- tolower(directions) }

	x <- raster(x)
	r <- res(x)
	xy <- xyFromCell(x, cells)

	mat <- FALSE
	if (is.matrix(directions)) {
		stopifnot(length(which(directions==0)) == 1)
		stopifnot(length(which(directions==1)) > 0)
		
		d <- .adjacentUD(x, cells, directions)
		
		directions <- length(directions)
		mat <- TRUE
		
	} else if (directions==4) {
		d <- c(xy[,1]-r[1], xy[,1]+r[1], xy[,1], xy[,1], xy[,2], xy[,2], xy[,2]+r[2], xy[,2]-r[2])
		
	} else if (directions==8) {
		d <- c(rep(xy[,1]-r[1], 3), rep(xy[,1]+r[1],3), xy[,1], xy[,1],
				rep(c(xy[,2]+r[2], xy[,2], xy[,2]-r[2]), 2), xy[,2]+r[2], xy[,2]-r[2])

	} else if (directions==16) {
		r2 <- r * 2
		d <- c(rep(xy[,1]-r2[1], 2), rep(xy[,1]+r2[1], 2),
			rep(xy[,1]-r[1], 5), rep(xy[,1]+r[1], 5),
			xy[,1], xy[,1], 
							
			rep(c(xy[,2]+r[2], xy[,2]-r[2]), 2),
			rep(c(xy[,2]+r2[2], xy[,2]+r[2], xy[,2], xy[,2]-r[2], xy[,2]-r2[2]), 2),
			xy[,2]+r[2], xy[,2]-r[2])
							
							
	} else if (directions=='bishop') {
		d <- c(rep(xy[,1]-r[1], 2), rep(xy[,1]+r[1],2), rep(c(xy[,2]+r[2], xy[,2]-r[2]), 2))
		directions <- 4 # to make pairs
		
	} else {
		stop('directions should be one of: 4, 8, 16, "bishop", or a matrix')
	}
	
	d <- matrix(d, ncol=2)
	if (.isGlobalLonLat(x)) {
		# normalize longitude to -180..180
		d[,1] <- (d[,1] + 180) %% 360 - 180
	}
	
	if (pairs) {
		if (mat) {
			cells <- rep(cells, each=directions)		
		} else {
			cells <- rep(cells, directions)
		}
		d <- na.omit(cbind(cells, cellFromXY(x, d)))
		attr(d, 'na.action') <- NULL
		colnames(d) <- c('from', 'to')
		if (! is.null(target)) {
			d <- d[d[,2] %in% target, ]
		}
		if (sorted) {
			d <- d[order(d[,1], d[,2]),]
		}
	} else {
		d <- as.vector(unique(na.omit(cellFromXY(x, d))))
		if (! is.null(target)) {
			d <- intersect(d, target)
		}
		if (sorted) {
			d <- sort(d)
		}
	}
	d
}
