# MainzellisteConnectoR

<!-- badges: start -->
[![codecov](https://codecov.io/gh/joundso/mainzelliste-connector/branch/master/graph/badge.svg)](https://codecov.io/gh/joundso/mainzelliste-connector)
[![pipeline status](https://git.uk-erlangen.de/mik-diz/mik-diz-tea/r-packages/mainzelliste-connector/badges/master/pipeline.svg)](https://git.uk-erlangen.de/mik-diz/mik-diz-tea/r-packages/mainzelliste-connector/commits/master)
[![coverage report](https://git.uk-erlangen.de/mik-diz/mik-diz-tea/r-packages/mainzelliste-connector/badges/master/coverage.svg)](https://git.uk-erlangen.de/mik-diz/mik-diz-tea/r-packages/mainzelliste-connector/commits/master)
[![CRAN Status Badge](https://www.r-pkg.org/badges/version-ago/MainzellisteConnectoR)](https://cran.r-project.org/package=MainzellisteConnectoR)
[![Cran Checks](https://cranchecks.info/badges/worst/MainzellisteConnectoR)](https://cran.r-project.org/web/checks/check_results_MainzellisteConnectoR.html)
<!-- badges: end -->

The R package `MainzellisteConnectoR` provides utility functions used to access a running Mainzelliste-Instance.

## Installation

<!---
You can install `MainzellisteConnectoR` directly from CRAN:

```r
install.packages("MainzellisteConnectoR")
```
-->

The development version can be installed using

```r
install.packages("devtools")
devtools::install_github("joundso/mainzelliste-connector", ref = "development")
```

## Basic functions

### Pseudonymize a value(set)

#### Without setting the environment variables

```R
res <- MainzellisteConnectoR::pseudonymize(
  MAINZELLISTE_BASE_URL = "https://your-organization.org",
  MAINZELLISTE_API_KEY = "123456789abcdef",
  MAINZELLISTE_FIELDNAME = "ishid",
  mainzelliste_fieldvalue = c(123, 456, "abc")
)

## Result (e.g.):
res
#       123        456        abc
# "000C30WP" "T4ECWT4Q" "Y2FAYH5D"
```

#### With setting the environment variables

Simply fill a `.env` file:

```sh
## Save this e.g. as '.env'
MAINZELLISTE_BASE_URL=https://your-organization.org
MAINZELLISTE_API_KEY=123456789abcdef
MAINZELLISTE_FIELDNAME=ishid
```

then read in the file and assign all variables to the environment:

```R
## Read in the '.env' file:
DIZutils::set_env_vars(env_file = "./.env")

## And use the smaller function call:
res <- MainzellisteConnectoR::pseudonymize(
  mainzelliste_fieldvalue = c(123, 456, "abc"),
  from_env = TRUE
)

## Result (e.g.):
res
#       123        456        abc
# "000C30WP" "T4ECWT4Q" "Y2FAYH5D"
```

#### Accessing the result

```R
## Result (e.g.):
res
#       123        456        abc
# "000C30WP" "T4ECWT4Q" "Y2FAYH5D"

## The result is a named list and can be accessed like this:
## Access the element with the name "123" (and receive a single-item-list):
res["123"]
# Result:
#        123 
#  "000C30WP"

## Access the element with the name "123" (and receive a string):
res[["123"]]
# Result:
# "000C30WP"

## Access the first element (and receive a string):
res[[1]]
# Result:
# "000C30WP"
```

### De-Pseudonymize a value(set)

This is exactly the same like pseudonymizing, but use `MainzellisteConnectoR::depseudonymize` instead of `MainzellisteConnectoR::pseudonymize`.

## More Infos

* About the Mainzelliste in its [Repo](https://bitbucket.org/medicalinformatics/mainzelliste/src/master) or its [Wiki](https://bitbucket.org/medicalinformatics/mainzelliste/wiki/Home)
* About MIRACUM: <https://www.miracum.org/>
* About the Medical Informatics Initiative: <https://www.medizininformatik-initiative.de/index.php/de>
