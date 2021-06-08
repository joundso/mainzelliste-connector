# Cleanup the backend in RStudio:
cat("\014") # Clears the console (imitates CTR + L)
rm(list = ls(all.names = TRUE)) # Clears the Global Environment/variables/data
invisible(gc()) # Garbage collector/Clear unused RAM

## Start to code here:

## Load some variables to the environment:
Sys.setenv("MAINZELLISTE_BASE_URL" = "https://your-organization.org")
Sys.setenv("MAINZELLISTE_API_KEY" = "123abc")
Sys.setenv("MAINZELLISTE_FIELDNAME" = "fieldname")

## Load the variables from a file:
DIZutils::set_env_vars(env_file = "./data-raw/demo.env")
DIZutils::set_env_vars(env_file = "../mainzelliste_connector.env")

## Convert the real ids to pseudonyms:
res <-
  MainzellisteConnectoR::pseudonymize(
    mainzelliste_fieldvalue = c(123, 456, "abcd"),
    from_env = TRUE
  )

## Convert the pseudonyms back to real ids:
MainzellisteConnectoR::depseudonymize(c(as.character(res), "thisisnotyetpseudonymized"), error_is_na = T)
