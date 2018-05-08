# sudo apt install libgpgme11-dev to install gpg on linux

has_op <- function(version = "0.4") {
  stat <- suppressWarnings(system("op --version", intern = TRUE))
  if(!identical(stat[1], version)) {
    stop(
      paste0(
  "1Password CLI program 'op' version ", version, " is required.
       Download it from here: 
       https://app-updates.agilebits.com/product_history/CLI"), call. = FALSE
)
  }
}

## attempt to signin
signin <- function() {
  
  ## attempt to login, asking for master password
  ## this is not saved to even a temporary variable
  login_ret <- suppressWarnings(
    system(
      paste0("echo ", 
             getPass::getPass("Master Password"),
             " | op signin my --output=raw"),
      intern = TRUE)
  )
  
  ## login_ret should have 43 characters and no spaces
  stopifnot(nchar(login_ret) == 43 && !grepl(" ", login_ret))
 
  ## set the environment variable to the returned login token 
  Sys.setenv("OP_SESSION_my" = login_ret)
  
  ## return the token invisibly.
  ## this is not the actual login and 
  ## is ephemeral anyway. it will be 
  ## invalid in 30 minutes
  return(invisible(login_ret))
  
}

list_items <- function() {
  list_ret <- suppressWarnings(
    system(
      paste0("echo ", 
             Sys.getenv("OP_SESSION_my"), 
             "| op list items"), 
      intern = TRUE
    )
  )
  stopifnot(!attr(list_ret, "status") == 145) # not authorised
  jsonlite::fromJSON(list_ret, flatten = TRUE)$overview.title
}

find_item <- function(name) {
  items <- list_items()
  grep(name, items, ignore.case = TRUE, value = TRUE)
}

show_password <- function(account, username, password) {
  htmltools::html_print(
    htmltools::HTML(paste0('
<style>
#hover-content {
    display:none;
} 
#parent:hover #hover-content {
    display:block;
}
</style>
<div id="parent">',
     '<b><u>', account, '</u></b><br /><br />',
     '<b>user:</b><br /> ', username, '<br /><br /><b>password:</b>
     <div id="hover-content">',
         password,
'    </div>
</div>')
    )
  )
  return(invisible(NULL))
}

get_item <- function(name) {
  
  item <- suppressWarnings(
    system(
      paste0("echo ", 
             Sys.getenv("OP_SESSION_my"), 
             "| op get item \"", name, "\""), 
      intern = TRUE)
  )
  if(!identical(substr(item, 1, 6), '{\"uuid')) stop("Failed to retrieve item", call. = FALSE)
  itemd <- jsonlite::fromJSON(item, flatten = TRUE)
  
  unameid <- which(itemd$details$fields$designation == "username")
  pwordid <- which(itemd$details$fields$designation == "password")
  
  uname <- itemd$details$fields$value[unameid]
  pword <- itemd$details$fields$value[pwordid]
  
  message("hover to reveal password")
  show_password(name, uname, pword)
  
  return(invisible(uname))
  
}

