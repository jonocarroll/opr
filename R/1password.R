get_token_name <- function() {

  subdomain <- getOption("OP_SUBDOMAIN")
  if (is.null(subdomain)) subdomain <- "my"

  paste0("OP_SESSION_", subdomain)

}



setup_op <- function(URL = "my.1password.com",
                     email = NULL,
                     secret_key = NULL) {

  # op signin example.1password.com wendy_appleseed@example.com A3-XXXXXX-XXXXXX-XXXXX-XXXXX-XXXXX-XXXXX

  ## ensure that op is present and working
  check_has_op()

  if (!grepl("^.+@.+\\..+$", email)) stop("email does not appear to be a valid email address")
  if (grepl("[ ]", email)) stop("email does not appear to be a valid email address")
  if (!grepl("^.+\\..+\\..+$", URL)) stop("URL does not appear to be valid")
  if (grepl("[ ]", URL)) stop("URL does not appear to be valid")
  if (!identical(length(strsplit(secret_key, "-")[[1]]), 7L)) stop("secret_key does not appear to be valid")

  subdomain <- sub("\\..+\\..+$", "", URL)

  ## attempt to login, asking for master password
  ## this is not saved to even a temporary variable
  signin_ret <- suppressWarnings(
    system(
      paste(
        "echo",
        getPass::getPass("Master Password"),
        "| op signin ", URL, email, secret_key, "--output=raw"
      ),
      intern = TRUE
    )
  )

  ## login_ret should have 43 characters and no spaces
  stopifnot(nchar(signin_ret) == 43 && !grepl(" ", signin_ret))

  message(paste0("Signin successful. Your subdomain is ", subdomain))
  options("OP_SUBDOMAIN" = subdomain)

  ## set the environment variable to the returned login token
  do.call(Sys.setenv, setNames(list(signin_ret), paste0("OP_SESSION_", subdomain)))

  message(paste0("Signin token saved to environment variable OP_SESSION_", subdomain))
  message("This function does not need to be run again. You can now use `signin()`")
  message("This session will be valid for 30 minutes")

  ## return the token invisibly.
  ## this is not the actual login and
  ## is ephemeral anyway. it will be
  ## invalid in 30 minutes
  return(invisible(signin_ret))

}

#' Check if 1Password CLI app op is available/working
#'
#' @md
#' @param version version of `op` to test for the presence of
#'
#' @return `NULL`, invisibly. This function is called to check for the presence
#'   of `op` and will fail if it is not found with the specified version.
#' @export
check_has_op <- function(version = "0.4") {
  stat <- suppressWarnings(system("op --version", intern = TRUE))
  if (!identical(stat[1], version)) {
    stop(
      paste0(
        "1Password CLI program 'op' version ", version, " is required.
       Download it from here:
       https://app-updates.agilebits.com/product_history/CLI"
      ), call. = FALSE
    )
  }
  return(invisible(NULL))
}

#' Attempt to sign in to an authenticated op session
#'
#' @md
#' @param subdomain domain for logging into 1Password. This can be found in the
#'   URL you use to login via a web interface, e.g. for
#'   `my.1password.com/signin` the subdomain is `my`, which is set as default.
#'
#' @details Requests the 1Password Master Password. At no point is this saved to
#'   even a temporary variable. This is only required for signin, after which a
#'   session token will be used to communicate with 1Password. The session token
#'   is validated on the server and lasts 30 minutes, after which you will again
#'   need to sign in.
#'
#'   The session token is not the actual hash, but merely a reference to an
#'   encrypted token in the user's home directory (in e.g. `~/.op/config`).
#'
#'   This sets an environment variable `OP_SESSION_X` (where `X` is the subdomain)
#'   and an [option] `OP_SUBDOMAIN`.
#'
#' @return if successful, the login token, invisibly.
#' @export
signin <- function(subdomain = "my") {

  ## ensure that op is present and working
  check_has_op()

  ## attempt to login, asking for master password
  ## this is not saved to even a temporary variable
  login_ret <- suppressWarnings(
    system(
      paste0(
        "echo ",
        getPass::getPass("Master Password"),
        " | op signin ", subdomain, " --output=raw"
      ),
      intern = TRUE
    )
  )

  ## login_ret should have 43 characters and no spaces
  stopifnot(nchar(login_ret) == 43 && !grepl(" ", login_ret))

  message(paste0("Signin successful. Your subdomain is ", subdomain))
  message("This session will be valid for 30 minutes")
  options("OP_SUBDOMAIN" = subdomain)

  ## set the environment variable to the returned login token
  do.call(Sys.setenv, setNames(list(signin_ret), paste0("OP_SESSION_", subdomain)))
  message(paste0("Signin token saved to environment variable OP_SESSION_", subdomain))

  ## return the token invisibly.
  ## this is not the actual login and
  ## is ephemeral anyway. it will be
  ## invalid in 30 minutes
  return(invisible(login_ret))
}

signout <- function() {

  suppressWarnings(
    system("op signout", intern = FALSE, wait = FALSE)
  )

}

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

#' Show the username and password for a given 1Password item
#'
#' @param account 1Password item being presented
#' @param username username
#' @param password password, to be hidden until hovered over. See Details.
#'
#' @details The username and password will be compiled into a HTML page which
#'   will be presented in the Viewer pane (if available). This allows copying
#'   the data but does not present it to the session in a way which wil be
#'   recorded.
#'
#' @return `NULL`, invisibly.
#' @noRd
#' @keywords internal
show_password <- function(account, username, password) {
  htmltools::html_print(
    htmltools::HTML(paste0(
      '
<style>
#hover-content {
    display:none;
}
#parent:hover #hover-content {
    display:block;
}
</style>
<div id="parent">',
      "<b><u>", account, "</u></b><br /><br />",
      "<b>user:</b><br /> ", username, '<br /><br /><b>password:</b>
     <div id="hover-content">',
      password,
      "    </div>\n</div>"
    ))
  )
  return(invisible(NULL))
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
