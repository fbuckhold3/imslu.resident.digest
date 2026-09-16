# mod_faculty_entry.R ─ Faculty Evaluation section
# Thin pass-through to gmed::mod_faculty_eval_ui/server — the PGY chart,
# faculty search, multi-step rating form, and pending-faculty queue all
# live there, shared with imslu.ind.dash. This app only supplies the
# rdm_data() shape that module expects, via gmed::load_rdm_for_resident()
# (the same generic per-resident loader ind.dash's own Phase 3 uses) —
# no separate pull needed.

mod_faculty_entry_ui <- function(id) {
  ns <- NS(id)
  gmed::mod_faculty_eval_ui(ns("faculty_eval"))
}

mod_faculty_entry_server <- function(id, resident_id) {
  moduleServer(id, function(input, output, session) {
    rdm_data_r <- reactive({
      req(resident_id())
      gmed::load_rdm_for_resident(rdm_token = app_config$rdm_token,
                                  redcap_url = app_config$redcap_url,
                                  record_id  = resident_id(),
                                  raw_or_label = "raw")
    })

    gmed::mod_faculty_eval_server(
      "faculty_eval",
      rdm_data         = rdm_data_r,
      resident_id      = resident_id,
      faculty_roster_r = reactive(faculty_roster_store),
      rdm_token        = app_config$rdm_token,
      redcap_url       = app_config$redcap_url,
      fac_token        = app_config$fac_token
    )
  })
}
