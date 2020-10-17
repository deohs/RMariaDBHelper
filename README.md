# RMariaDBHelper

Helper functions to make RMariaDB easier to use

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
