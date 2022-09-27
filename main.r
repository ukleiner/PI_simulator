library(tibble)
library(dplyr)
library(forcats)
library(ggplot2)
library(ggforce)

se <- function(r) sd(r)/sqrt(length(r)-1)      
plot_sim <- function (out=1e2) {
  # sample inside a square
  dots <- tibble(
    x = runif(out, min=-1, max=1),
    y = runif(out, min=-1, max=1)
  ) %>% 
      mutate(circle = (x^2 + y^2) < 1, 
              corner = x >= 0 & y >= 0, 
              location = case_when(
                corner == TRUE ~ 'rect',
                circle == TRUE ~ 'circle',
                TRUE ~ 'ATR'
              )
          )

  pd <- dots %>% 
    ggplot(aes(x=x, y=y)) +
      geom_rect(aes(xmin=-1, xmax=1, ymin=-1, ymax=1), fill=NA, color='black') +
      geom_rect(aes(xmin=0, xmax=1, ymin=0, ymax=1), fill=NA, color='gray50') +
      geom_circle(aes(x0=0, y0=0, r=1), inherit.aes = FALSE) +
      geom_point(aes(color=location)) +
      coord_fixed() +
      ggtitle(paste("Estimated PI is", round(sum(dots$circle)/sum(dots$corner), 3), 'Using', out, 'points'))
  return(pd)
}
# sim w/o plotting
sim_dots <- function (out=1e2) {
  corner <- c(0)
  while (sum(corner) == 0) {
    x <- runif(out, min=-1, max=1)
    y <-  runif(out, min=-1, max=1)
    corner <- x >= 0 & y >= 0
    circle <- (x^2 + y^2) < 1
  }
  return(sum(circle)/sum(corner))
}
benchmark_sim <- function(simulations, points) {
  # make all possible combinations of simulations and points
  combs <- expand.grid(simulations, points)
  # run row[1] simulations of row[2] dots in each
  ests <- apply(combs, 1, \(row) replicate(n=row[1], sim_dots(row[2])))
  combs$means <- sapply(ests, mean)
  combs$ses <- sapply(ests, se)
  colnames(combs) <- c("reps", "pts", "mean", "se")
  data <- tibble(combs) %>% 
    mutate(points = as_factor(pts))

   p <- data %>% 
    ggplot(aes(x=reps, y=mean, group=points, color=points)) +
    geom_hline(yintercept=round(pi, 3)) +
    geom_line() +
    geom_point() #+
    # geom_errorbar(aes(ymin=mean-se, ymax=mean+se))

  return(p)
}

# prepare a simulation illustration
plot_illust <- plot_sim()
sizes <- c(10, 50, 100, 300, 500, 1000)
plot_benchmark <- benchmark_sim(sizes, sizes)

# run_sim(1e3)
# run_sim(1e4)

X11()
# ggsave("illust.png")
plot(plot_illust)
X11()
plot(plot_benchmark)
# ggsave("benchmark.png")
if (!interactive()) {
  Sys.sleep(Inf)
}
