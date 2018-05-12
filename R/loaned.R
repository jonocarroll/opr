## these functions borrowed from usethis
cat_line <- function(...) {
  cat(..., "\n", sep = "")
}

bullet <- function(lines, bullet) {
  lines <- paste0(bullet, " ", lines)
  cat_line(lines)
}

todo <- function(...) {
  bullet(paste0(...), bullet = todo_bullet())
}

todo_bullet <- function() {
  "\033[31m●\033[39m"
}
