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

#' Retrieve the environment variable name
#'
#' Idenfities the current environment variable name by
#' inspecting `getOption("OP_SUBDOMAIN")` which is set on
#' signin.
#'
#' @md
#' @export
get_token_name <- function() {

  subdomain <- getOption("OP_SUBDOMAIN")
  if (is.null(subdomain)) subdomain <- "my"

  if (is.null(Sys.getenv(paste0("OP_SESSION_", subdomain)))) {
    stop(paste0("OP_SESSION_", subdomain, " environment variable empty"))
  }

  paste0("OP_SESSION_", subdomain)

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
