# MainzellisteConnectoR
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


#' @title Get a pseudonym for a value
#' @description Get a pseudonym for a value
#' @param MAINZELLISTE_BASE_URL (Optional, String)
#'   The URL to your Mainzelliste API.
#'   E.g. 'https://ml.hospital.de'.
#' @param MAINZELLISTE_API_KEY (Optional, String)
#'   The API key which is allowed to access the Mainzelliste.
#' @param MAINZELLISTE_FIELDNAME (Optional, String) The name of
#'   the field to use for the Mainzelliste. Specified in the ML-config.
#' @param mainzelliste_fieldvalue (String) The actual value to pseudonymized.
#' @param from_env (Optional, Boolean, Default = `TRUE`) If true, the
#'   connection parameters `MAINZELLISTE_BASE_URL`, `MAINZELLISTE_API_KEY` and
#'   `MAINZELLISTE_FIELDNAME` are read from the environment
#'   and can therefore be left empty when calling this function.
#' @param error_is_na (Boolean, optional, default = FALSE) If there is an
#'   error while creating the pseudonym or while converting the pseudonym to
#'   a real value, should the result be `NA` instead of an error?
#' @param skip_na (Boolean, optional, default = TRUE) Should NAs in the input
#'   data be skipped (the result for them will also be NA)?
#'
#' @return (vector) All pseudonyms for the input values.
#' @export
#'
pseudonymize <-
  function(mainzelliste_fieldvalue,
           MAINZELLISTE_BASE_URL = NULL,
           MAINZELLISTE_API_KEY = NULL,
           MAINZELLISTE_FIELDNAME = NULL,
           from_env = TRUE,
           error_is_na = FALSE,
           skip_na = TRUE) {
    if (from_env) {
      MAINZELLISTE_BASE_URL <- Sys.getenv("MAINZELLISTE_BASE_URL")
      MAINZELLISTE_API_KEY <- Sys.getenv("MAINZELLISTE_API_KEY")
      MAINZELLISTE_FIELDNAME <- Sys.getenv("MAINZELLISTE_FIELDNAME")
    }

    if (rapportools::is.empty(MAINZELLISTE_BASE_URL) ||
        rapportools::is.empty(MAINZELLISTE_API_KEY) ||
        rapportools::is.empty(MAINZELLISTE_FIELDNAME)) {
      DIZutils::feedback(
        print_this = paste0(
          "One of the connection parameters for the Mainzelliste is empty.",
          " Please fix."
        ),
        type = "Error",
        findme = "a35b593df7"
      )
      stop("See error above")
    }

    res <- sapply(
      X = mainzelliste_fieldvalue,
      FUN = function(x) {
        return(
          pseudonymize_single(
            MAINZELLISTE_BASE_URL = MAINZELLISTE_BASE_URL,
            MAINZELLISTE_API_KEY = MAINZELLISTE_API_KEY,
            MAINZELLISTE_FIELDNAME = MAINZELLISTE_FIELDNAME,
            mainzelliste_fieldvalue = x,
            error_is_na = error_is_na,
            skip_na = skip_na
          )
        )
      }
    )
    return(res)
  }

pseudonymize_single <- function(MAINZELLISTE_BASE_URL,
                                MAINZELLISTE_API_KEY,
                                MAINZELLISTE_FIELDNAME,
                                mainzelliste_fieldvalue,
                                error_is_na,
                                skip_na) {
  if (skip_na && is.na(mainzelliste_fieldvalue)) {
    return(NA)
  }

  ## Remove last '/':
  MAINZELLISTE_BASE_URL <-
    DIZutils::clean_path_name(pathname = MAINZELLISTE_BASE_URL, remove.slash = TRUE)

  MAINZELLISTE_SESSION_URL <- "/sessions"
  MAINZELLISTE_TOKEN_URL <- "/tokens"
  MAINZELLISTE_PATIENT_URL <- "/patients"

  ## Result array:
  res <- list("success" = 0, "value" = "")

  ## First, create a new session on the Mainzelliste server
  out <- tryCatch({
    url <- paste0(MAINZELLISTE_BASE_URL, MAINZELLISTE_SESSION_URL)
    response <-
      httr::POST(url = url,
                 httr::add_headers("mainzellisteApiKey" = MAINZELLISTE_API_KEY))
    # httr::content(response, as = "text")
    session_id <- httr::content(response)[["sessionId"]]
  },
  error = function(cond) {
    msg <- "Couldn't create a session_id"
    DIZutils::feedback(print_this = msg,
                       type = "Error",
                       findme = "0cf6d9ded8")
    res[["success"]] <- -1
    res[["error_msg"]] <- msg
  })


  # Second, create a token with the eligibility to add a user
  if (res[["success"]] != -1) {
    # Don't do anything if there already is/was an error
    out <- tryCatch({
      token_request <- list("type" = "addPatient",
                            "data" = NULL)
      payload = jsonlite::toJSON(token_request, auto_unbox = T)

      url = paste0(
        MAINZELLISTE_BASE_URL,
        MAINZELLISTE_SESSION_URL,
        "/",
        session_id,
        MAINZELLISTE_TOKEN_URL
      )
      response <-
        httr::POST(
          url = url,
          httr::add_headers(
            "mainzellisteApiKey" = MAINZELLISTE_API_KEY,
            "Content-Type" = "application/json"
          ),
          body = payload
        )
      # httr::content(response, as = "text")
      token_id <- httr::content(response)[["tokenId"]]
    },
    error = function(cond) {
      msg <- "Couldn't create a token_id"
      DIZutils::feedback(print_this = msg,
                         type = "Error",
                         findme = "f24e7c7425")
      res[["success"]] <- -1
      res[["error_msg"]] <- msg
    })
  }

  # Third, get the pseudonym for the data:
  if (res[["success"]] != -1) {
    # Don't do anything if there already is/was an error
    out <- tryCatch({
      token_request <- list()
      token_request[[MAINZELLISTE_FIELDNAME]] <-
        mainzelliste_fieldvalue
      token_request[["sureness"]] <- "false"

      payload <- jsonlite::toJSON(token_request, auto_unbox = T)

      url = paste0(MAINZELLISTE_BASE_URL,
                   MAINZELLISTE_PATIENT_URL,
                   "?tokenId=",
                   token_id)
      response <-
        httr::POST(
          url = url,
          httr::add_headers("Content-Type" = "application/x-www-form-urlencoded"),
          body = token_request,
          encode = "form"
        )
      # httr::content(response, as = "text")
      value <- httr::content(response)[["newId"]]

      if (nchar(value) > 0) {
        res[["success"]] <- 1
        res[["value"]] <- value
      } else {
        res[["success"]] <- -1
        res[["error_msg"]] <- "The received value is empty"
      }
    },
    error = function(cond) {
      msg <- "Couldn't receive a value for the pseudonym"
      DIZutils::feedback(print_this = msg,
                         type = "Error",
                         findme = "08ade930ba")
      res[["success"]] <- -1
      res[["error_msg"]] <- msg
    })
  }
  if (res[["success"]] == 1) {
    return(res[["value"]])
  } else {
    if (error_is_na) {
      type = "Warning"
    } else {
      type = "Error"
    }
    DIZutils::feedback(
      print_this = paste0(
        "Couldn't pseudonymize '",
        mainzelliste_fieldvalue,
        "'",
        res[["error_msg"]]
      ),
      type = type,
      findme = "6057e877e5"
    )
    if (error_is_na) {
      return(NA)
    } else {
      stop("See error above")
    }
  }
}
