#' List all 1Password items (titles)
#'
#' @return a character vector of 1Password item titles
#' @export
list_items <- function() {

  ## ensure that op is present and working
  check_has_op()

  ## request list from server
  list_ret <- suppressWarnings(
    system(
      paste0(
        "echo ",
        Sys.getenv(get_token_name()),
        "| op list items"
      ),
      intern = TRUE
    )
  )
  stopifnot(!attr(list_ret, "status") == 145) # not authorised

  ## extract titles
  jsonlite::fromJSON(list_ret, flatten = TRUE)$overview.title
}

#' Find a 1Password item matching a name
#'
#' @param name a name to seach for within 1Password item titles
#'
#' @return a character vector of 1Password item titles matching `name`
#' @export
#'
#' @examples \dontrun{
#' find_item("Twitter")}
find_item <- function(name) {

  ## ensure that op is present and working
  check_has_op()

  ## collect all items
  items <- list_items()

  ## search for name within titles
  grep(name, items, ignore.case = TRUE, value = TRUE)
}

#' Retrieve a 1Password item by name
#'
#' @md
#' @param name name of item to retrieve. See Details.
#'
#' @details If `name` is not unique the shell process will return the available
#'   unique hashes which _are_ unique and can be used as `name` arguments in a
#'   further call.
#'
#' @return the input username for the given item
#' @export
#'
#' @examples \dontrun{
#' get_item("Twitter")}
get_item <- function(name) {

  ## ensure that op is present and working
  check_has_op()

  item <- suppressWarnings(
    system(
      paste0(
        "echo ",
        Sys.getenv(get_token_name()),
        "| op get item \"", name, "\""
      ),
      intern = TRUE
    )
  )
  if (!identical(substr(item, 1, 6), '{\"uuid')) stop("Failed to retrieve item", call. = FALSE)
  itemd <- jsonlite::fromJSON(item, flatten = TRUE)

  unameid <- which(itemd$details$fields$designation == "username")
  pwordid <- which(itemd$details$fields$designation == "password")

  uname <- itemd$details$fields$value[unameid]
  pword <- itemd$details$fields$value[pwordid]

  message("hover to reveal password")
  show_password(name, uname, pword)

  return(invisible(uname))
}
