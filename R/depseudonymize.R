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


#' @title Convert a pseudonym back to its input value.
#' @description Convert a pseudonym back to its input value.
#' @inheritParams pseudonymize
#' @param mainzelliste_fieldvalue (String) The actual value to de-pseudonymized.
#'
#' @return (vector) All pseudonyms for the input values.
#' @export
#'
depseudonymize <-
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
          depseudonymize_single(
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


depseudonymize_single <- function(MAINZELLISTE_BASE_URL,
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
                       findme = "a6bd65b3fc")
    res[["success"]] <- -1
    res[["error_msg"]] <- msg
  })


  # Second, create a token with the eligibility to read a user
  if (res[["success"]] != -1) {
    # Don't do anything if there already is/was an error
    out <- tryCatch({
      token_request <- list(
        "type" = "readPatients",
        "data" = list(
          "searchIds" = list(
            list("idType" = "pid",
                 "idString" = mainzelliste_fieldvalue)
          ),
          "resultFields" = list(MAINZELLISTE_FIELDNAME),
          "resultIds" = list("pid")
        )
      )
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
      token_id <- jsonlite::fromJSON(httr::content(
        x = response,
        as = "text",
        encoding = "UTF-8"
      ))[["tokenId"]]
    },
    error = function(cond) {
      msg <- "Couldn't create a token_id"
      DIZutils::feedback(print_this = msg,
                         type = "Error",
                         findme = "9ef2391636")
      res[["success"]] <- -1
      res[["error_msg"]] <- msg
    })
  }

  # Third, get the data for the pseudonym
  if (res[["success"]] != -1) {
    # Don't do anything if there already is/was an error
    out <- tryCatch({
      url = paste0(MAINZELLISTE_BASE_URL,
                   MAINZELLISTE_PATIENT_URL,
                   "?tokenId=",
                   token_id)
      response <- httr::GET(url = url)
      # httr::content(x = response)
      value <-
        httr::content(response)[[1]][["fields"]][[MAINZELLISTE_FIELDNAME]]

      if (nchar(value) > 0) {
        res[["success"]] <- 1
        res["value"] <- value
      } else {
        res[["success"]] <- -1
        res[["error_msg"]] <- "The received value is empty"
      }
    },
    error = function(cond) {
      msg <- "Couldn't receive a value for the pseudonym"
      DIZutils::feedback(print_this = msg,
                         type = "Error",
                         findme = "7fd515ed96")
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
        "Couldn't depseudonymize '",
        mainzelliste_fieldvalue,
        "': ",
        res[["error_msg"]]
      ),
      type = type,
      findme = "fbccd250bc"
    )
    if (error_is_na) {
      return(NA)
    } else {
      stop("See error above")
    }
  }
}
