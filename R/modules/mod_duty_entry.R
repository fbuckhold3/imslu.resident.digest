# mod_duty_entry.R ─ thin passthrough to amiontools::mod_duty_hour_page
#
# The full composition (calendar + confirm form + summary chart) now lives
# in amiontools (promoted 2026-09-19) — this file just supplies this app's
# own token/URL sourcing convention, matching imslu.ind.dash's copy so the
# two stay identical without either one hand-duplicating the composition.

mod_duty_entry_ui <- function(id) {
  amiontools::mod_duty_hour_page_ui(id)
}

mod_duty_entry_server <- function(id, resident_id) {
  amiontools::mod_duty_hour_page_server(
    id, resident_id = resident_id,
    rdm_token  = app_config$rdm_token,
    redcap_url = app_config$redcap_url
  )
}
