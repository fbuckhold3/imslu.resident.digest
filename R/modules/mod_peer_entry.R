# mod_peer_entry.R ─ Peer Review section
# Thin pass-through to amiontools::mod_peer_review_entry_ui/server — all the
# real logic (search/quick-pick, rating form, results reveal) lives there,
# shared with imslu.ind.dash.

mod_peer_entry_ui <- function(id) {
  ns <- NS(id)
  amiontools::mod_peer_review_entry_ui(ns("peer"))
}

mod_peer_entry_server <- function(id, resident_id, all_residents_r) {
  moduleServer(id, function(input, output, session) {
    amiontools::mod_peer_review_entry_server(
      "peer",
      resident_id     = resident_id,
      all_residents_r = all_residents_r,
      rdm_token       = app_config$rdm_token,
      redcap_url      = app_config$redcap_url
    )
  })
}
