setup_op <- function(URL = "my.1password.com",
                     email = NULL,
                     secret_key = NULL) {

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
  do.call(Sys.setenv, stats::setNames(list(signin_ret), paste0("OP_SESSION_", subdomain)))

  message(paste0("Signin token saved to environment variable OP_SESSION_", subdomain))
  message("This function does not need to be run again. You can now use `signin()`")
  message("This session will be valid for 30 minutes")

  ## return the token invisibly.
  ## this is not the actual login and
  ## is ephemeral anyway. it will be
  ## invalid in 30 minutes
  return(invisible(signin_ret))

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
  signin_ret <- suppressWarnings(
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
  stopifnot(nchar(signin_ret) == 43 && !grepl(" ", signin_ret))

  message(paste0("Signin successful. Your subdomain is ", subdomain))
  message("This session will be valid for 30 minutes")
  options("OP_SUBDOMAIN" = subdomain)

  ## set the environment variable to the returned login token
  do.call(Sys.setenv, stats::setNames(list(signin_ret), paste0("OP_SESSION_", subdomain)))
  message(paste0("Signin token saved to environment variable OP_SESSION_", subdomain))

  ## return the token invisibly.
  ## this is not the actual login and
  ## is ephemeral anyway. it will be
  ## invalid in 30 minutes
  return(invisible(signin_ret))
}

signout <- function() {

  suppressWarnings(
    system("op signout", intern = FALSE, wait = FALSE)
  )

}
