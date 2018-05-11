<img src="https://raw.githubusercontent.com/jonocarroll/opr/master/tools/1password_logo.svg">

# opr

Interface with the [1Password](https://1password.com/) CLI tool `op`.

1Password is yet to provide a native Linux client. 1PasswordX (a Chrome plugin) works well, but requires you to launch 
chrome if you simply want to extract a password (say, for using another program). They do however provide a CLI tool 
(not an API) in the form of `op`.

## Installation

You can install the development version of `opr` from [GitHub] with:

``` r
remotes::install_github("jonocarroll/opr")
```

or

``` r
devtools::install_github("jonocarroll/opr")
```

## Dependency

`opr` depends on the 1Password CLI tool (available for most platforms), `op`. You can download it here: https://app-updates.agilebits.com/product_history/CLI 

Once `op` is installed you can use this package to communicate with 1Password using `R`.

## Example Usage

The first time you use `op` you need to provide three pieces of information:

 - the URL you use to log in to 1Password (e.g. `my.1password.com`),
 - the email address you use to log in to 1Password,
 - your [Secret Key](https://support.1password.com/secret-key/).
 
 These are provided to `setup_op` as
 
 ```r
 setup_op(URL = "my.1password.com",
          email = "notme@jcarroll.com.au",
          secret_key = "A3-XXXXXX-XXXXXX-XXXXX-XXXXX-XXXXX-XXXXX")
 ```

You will be prompted for your [Master Password](https://support.1password.com/forgot-master-password/) 
in a `getPass` masked password entry box. 

<img src="https://raw.githubusercontent.com/jonocarroll/opr/master/tools/getpass.png">

This is at no point stored, even in a temporary variable.

`setup_op` then performs the following actions:

 - signs you in to your 1Password account, 
 - stores a link to a session token (a hash, valid for 30 minutes) in an environment variable,
 - sets an `option` `OP_SUBDOMAIN` pointing to the environment variable name. 

Once this is done, you no longer need to use this function for this subdomain; you can now simply use 
`signin()` (optionally with a subdomain other than `"my"`) which will only prompt you for your [Master Password](https://support.1password.com/forgot-master-password/), the remaining information being extracted from the 
secure storage managed by `op`.

Once authenticated, you can list all of your saved items

```r
list_items()
```

search these for a given title

```r
find_item("Twitter")
```

and retrieve the username/password for an item (if unique)

```r
get_item("Twitter")
```

If not uniquely specified by a title, `op` will return hashes matching each of the items, and these can be used 
to retrieve a specific item.

For security, the password is not output, rather it is displayed in a HTML panel in the Viewer, from which the
username and password can be copied. For added security, the password is not visible until the mouse pointer is 
hovering over it.

<img src="https://raw.githubusercontent.com/jonocarroll/opr/master/tools/password.png" border="5">

Once you are finished with your session, you can sign out with

```r
signout()
```
