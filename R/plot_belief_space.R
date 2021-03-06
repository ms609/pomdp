# FIXME: Add belief points

#' Plot a 2D or 3D Projection of the Belief Space
#' 
#' Plots the optimal action, the node in the policy graph or the reward for a
#' given set of belief points on a line (2D) or on a ternary plot (3D). If no
#' points are given, points are sampled using a regular arrangement or randomly
#' from the (projected) belief space.
#' 
#' 
#' @param model a solved POMDP.
#' @param projection a vector with state IDs or names to project on. Allowed
#' are projections on two or three states. \code{NULL} uses the first two or
#' three states.
#' @param epoch display this epoch.
#' @param sample a matrix with belief points as rows or a character string
#' specifying the \code{method} used for \code{sample_belief_space}.
#' @param n number of points sampled.
#' @param what what to plot.
#' @param legend logical; add a legend? If the legend is covered by the plot then you
#' need to increase the plotting region of the plotting device.
#' @param pch plotting symbols.
#' @param col plotting colors.
#' @param ...  additional arguments are passed on to \code{plot} for 2D or
#' \code{TerneryPlot} for 3D.
#' @return Returns invisibly the sampled points.
#' @author Michael Hahsler
#' @seealso \code{\link{sample_belief_space}}
#' @keywords hplot
#' @examples
#' 
#' # two-state POMDP
#' data("Tiger")
#' sol <- solve_POMDP(Tiger)
#' 
#' plot_belief_space(sol)
#' plot_belief_space(sol, n = 10)
#' plot_belief_space(sol, n = 10, sample = "random")
#' 
#' # plot the belief points used by the grid-based solver
#' plot_belief_space(sol, sample = sol$solution$belief_states)
#' 
#' # plot different measures
#' plot_belief_space(sol, what = "pg_node")
#' plot_belief_space(sol, what = "reward")
#' 
#' # three-state POMDP
#' # Note: If the plotting region is too small then the legend might run into the plot 
#' data("Three_doors")
#' sol <- solve_POMDP(Three_doors)
#' sol
#' 
#' plot_belief_space(sol)
#' plot_belief_space(sol, sample = "random")
#' plot_belief_space(sol, what = "pg_node")
#' plot_belief_space(sol, what = "reward")
#' 
#' # plot the belief points used by the grid-based solver
#' plot_belief_space(sol, sample = sol$solution$belief_states)
#' 
#' # plot the belief points obtained using simulated trajectories (we use n = 50 to save time). 
#' plot_belief_space(sol, sample = simulate_POMDP(Three_doors, n = 50, horizon = 100, 
#'   random_actions = TRUE, visited_beliefs = TRUE))
#'
#' @export
plot_belief_space <- function(model, projection = NULL, epoch = 1, sample = "regular", n = 100, 
  what = c("action", "pg_node", "reward"), legend = TRUE, pch = 20, col = NULL, ...) {
  
  # sample: a matrix with belief points or a character string passed on to sample_belief_space as method.
  # E.g., "regular", "random", ...
  
  what <- match.arg(what)
  if(is.null(projection)) projection <- 1:min(length(model$model$states), 3)
  
  if(is.character(sample)) sample <-  sample_belief_space(model, projection = projection, 
    n = n, method = sample) 
  else {
  # a given sample needs to be projected
    sample[,-projection] <- 0
    sample <- sample[rowSums(sample) > 0,, drop = FALSE]
    sample <- sweep(sample, MARGIN = 1, STATS = rowSums(sample), FUN = "/")
  }
  
  val <- reward(model, belief = sample, epoch = epoch)[[what]]
   
  # col ... palette used for legend
  # cols ... colors for all points
  if(is.factor(val)) { # actions and pg_node are factor
    col <- .get_colors_descrete(length(levels(val)), col)
    cols <- col[as.integer(val)]
  } else {
    col <- .get_colors_cont(seq(0,1, length.out = 11), col)
    cols <- .get_colors_cont(val, col)
  }
  
  sample <- sample[, projection]
  ### remove points that have only 0 in the projection
  sample <- sample[rowSums(sample) != 0,]
    
  if(length(projection) == 3) {
    Ternary::TernaryPlot(
      alab=paste(colnames(sample)[1], "\u2192"), 
      blab=paste(colnames(sample)[2], "\u2192"), 
      clab=paste("\u2190", colnames(sample)[3]), 
      grid.lines=10, grid.lty='dotted',
      grid.minor.lines=1, grid.minor.lty='dotted', ...)  
    
    Ternary::TernaryPoints(sample, pch = pch, col = cols)
    
   # if(random) Ternary::TernaryPoints(belief, pch = pch, col = cols)
   # else {
   #   values <- rbind(
   #     x = attr(p$belief, "TernaryTriangleCenters")["x",], 
   #     y = attr(p$belief, "TernaryTriangleCenters")["y",], 
   #     z = val, 
   #     down = attr(p$belief, "TernaryTriangleCenters")["triDown",]) 
   #   Ternary::ColourTernary(values, spectrum = col)
   # }
    
  } else if(length(projection) == 2) {
    args <-  list(...)
    if(is.null(args$ylim))
      plot(NA, 
        xlim = c(0,1), ylim = c(0,4),
        axes = FALSE, xlab = NA, ylab = NA, ...)
    else
      plot(NA, 
        xlim = c(0,1),
        axes = FALSE, xlab = NA, ylab = NA, ...)
     
    points(sample[,1], rep(0, times = nrow(sample)), col = cols, pch = pch) 
    
    axis(1, at = c(0,1), labels = colnames(sample), xaxs = "i")
    axis(1, at = .5, .5) 
    
  } else stop("projection needs to be 2d or 3d.")
  
  if(legend) 
    if(is.factor(val)) 
      legend("topright", legend = levels(val), 
        pch = pch, 
        col = col, 
        bty = "n", 
        title = what,
        xpd = FALSE) # no clipping     
  else{
    legend("topright",
      legend = round(c(max(val), rep(NA, 9), min(val)), 2),
      fill = rev(col),
      border = NA,
      y.intersp = .5,
      bty = "n", 
      title = what, 
      xpd = FALSE) # no clipping     
  }
 
  invisible(list(belief = sample, val = val)) 
}

