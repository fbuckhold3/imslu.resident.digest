# global.R ─ imslu.resident.digest
#
# Standalone weekly-digest action app. Residents land here from a link in
# their Friday email (see imslu.email/resident_weekly_digest.qmd) to act on
# anything outstanding — confirm duty hours, log noon-conference attendance,
# do a peer review, or add new scholarship — without opening the full
# imslu.ind.dash dashboard.
#
# Deliberately thin: every domain's real logic lives in the shared packages
# (gmed, amiontools) and is composed here, the same way imslu.ind.dash
# composes it — see R/modules/*.R. This app owns almost no business logic
# of its own.

library(shiny)
library(shinyjs)
library(bslib)
library(DT)
library(dplyr)
library(httr)
library(jsonlite)
library(gmed)
library(amiontools)
library(roundsui)

# Re-read project-local .Renviron on every launch (same reasoning as
# ind.dash's global.R — R only reads it once at session startup otherwise).
local({
  proj_env <- file.path(getwd(), ".Renviron")
  if (file.exists(proj_env)) {
    readRenviron(proj_env)
    message("\U0001F501 Reloaded ", proj_env)
  }
})

app_config <- list(
  rdm_token  = Sys.getenv("RDM_TOKEN", unset = ""),
  fac_token  = Sys.getenv("FAC_TOKEN", unset = ""),
  redcap_url = Sys.getenv("REDCAP_URL", unset = "https://redcapsurvey.slu.edu/api/")
)

if (!nzchar(app_config$rdm_token)) {
  stop("No REDCap token available. Set RDM_TOKEN in .Renviron (local) ",
       "or in the deployment environment (Posit Connect).")
}

# Fingerprint + project identity probe — same pattern as ind.dash's
# global.R, so a misconfigured token/environment is obvious at startup
# rather than discovered via a confusing empty-data screen.
local({
  tok <- app_config$rdm_token
  fp  <- paste0(substr(tok, 1, 6), "…", substr(tok, nchar(tok) - 3, nchar(tok)))
  pt  <- tryCatch({
    resp <- httr::POST(
      url  = app_config$redcap_url,
      body = list(token = tok, content = "project",
                  format = "json", returnFormat = "json"),
      encode = "form", httr::timeout(10))
    if (httr::status_code(resp) == 200) {
      j <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
      paste0(j$project_title %||% "(no title)", " [id=", j$project_id %||% "?", "]")
    } else paste0("HTTP ", httr::status_code(resp))
  }, error = function(e) paste("probe failed:", e$message))
  message("\U0001F517 RDM token ", fp, " -> ", pt)
})

# Resident roster, loaded once at startup — same source mod_auth_server
# expects everywhere else in this ecosystem (needs an access_code column).
residents_store <- tryCatch(
  gmed::load_rdm_residents_only(rdm_token = app_config$rdm_token,
                                redcap_url = app_config$redcap_url),
  error = function(e) { message("Resident load failed: ", e$message); NULL }
)
if (is.null(residents_store) || nrow(residents_store) == 0) {
  stop("Could not load resident roster — check RDM_TOKEN/REDCAP_URL.")
}

# Faculty roster, for the Faculty Evaluation section's search — same
# loader/token ind.dash uses. NULL (FAC_TOKEN unset) is handled gracefully
# by mod_faculty_eval's own "Faculty roster unavailable" message, not fatal
# to app startup.
faculty_roster_store <- tryCatch(
  gmed::load_faculty_roster(fac_token = app_config$fac_token,
                            redcap_url = app_config$redcap_url),
  error = function(e) { message("Faculty roster load failed: ", e$message); NULL }
)
