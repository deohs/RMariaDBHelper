# RMariaDBHelper

This package contains helper functions to make RMariaDB easier to use. The 
intention is to allow you to work with database tables almost as easily as 
you could work with dataframes. Normally, when using databases in R, you
have to manage the connection to the database each time you use it. This 
can become tedious. This package can alleviate much of that drudgery.

With this package, you can...

- interact with database tables without explicitly connecting to the database
- enter your database password only once when first connecting (implicitly)
- use functions which are very similar to those you would use with dataframes

## Installation

You can install the development version from [GitHub](https://github.com/deohs/RMariaDBHelper) with:


```r
# install.packages("devtools")
devtools::install_github("deohs/RMariaDBHelper")
```

Or, if you prefer using [pacman](https://github.com/trinker/pacman):


```r
if (!require(pacman)) install.packages('pacman', repos = 'https://cloud.r-project.org')
pacman::p_load_gh("deohs/RMariaDBHelper")
```

## Example Usage

See [RMariaDBHelperExampleUsage.R](inst/extscripts/RMariaDBHelperExampleUsage.R) 
or the online documentation for this package as found in the R help browser.

## Notes

- This package is to be used with a MariaDB database configured previously.
- The package is only supported for use on Linux systems.
- For a more mature and feature-rich package, see [databaser](https://github.com/skgrange/databaser).
