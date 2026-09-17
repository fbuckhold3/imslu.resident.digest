# mod_attendance_entry.R ─ Noon Conference Attendance section
# Thin pass-through to amiontools::mod_attendance_ui/server — the overview
# stats, after-the-fact entry form, and expected-attendance calendar all
# live there, shared with imslu.ind.dash. This app only supplies the
# rdm_data() shape that module expects: list(all_forms = list(questions = ...)).

.pull_questions_rows <- function(record_id) {
  tryCatch({
    resp <- httr::POST(
      app_config$redcap_url,
      body = list(
        token = app_config$rdm_token, content = "record", action = "export",
        format = "json", type = "flat",
        records     = as.character(record_id),
        `forms[0]`  = "questions",
        `fields[0]` = "record_id",
        rawOrLabel  = "raw", rawOrLabelHeaders = "raw",
        exportCheckboxLabel = "false", exportSurveyFields = "false",
        exportDataAccessGroups = "false", returnFormat = "json"
      ),
      encode = "form", httr::timeout(30)
    )
    if (httr::status_code(resp) != 200) return(data.frame())
    dat <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    if (!is.data.frame(dat) || nrow(dat) == 0) return(data.frame())
    dat[!is.na(dat$redcap_repeat_instrument) &
          dat$redcap_repeat_instrument == "questions", , drop = FALSE]
  }, error = function(e) data.frame())
}

mod_attendance_entry_ui <- function(id) {
  ns <- NS(id)
  amiontools::mod_attendance_ui(ns("attendance"))
}

mod_attendance_entry_server <- function(id, resident_id) {
  moduleServer(id, function(input, output, session) {
    rdm_data_r <- reactive({
      req(resident_id())
      list(all_forms = list(questions = .pull_questions_rows(resident_id())))
    })

    amiontools::mod_attendance_server(
      "attendance",
      rdm_data    = rdm_data_r,
      resident_id = resident_id,
      rdm_token   = app_config$rdm_token,
      redcap_url  = app_config$redcap_url
    )
  })
}
