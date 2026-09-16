# mod_scholarship_entry.R ─ Scholarship section
# Thin pass-through to gmed::mod_scholarship_entry_ui/server — the ERAS
# entry form itself lives there, shared with imslu.ind.dash. This app only
# adds the small REDCap pull `existing_data` needs (next-instance number,
# most-meaningful cap, collection-picker labels) and a one-line count of
# what's already on file, so the section isn't just a bare button — a
# read-only, single-form pull, not the full scholarship view/edit/CV-export
# machinery ind.dash has (out of scope here; this section is "add new
# scholarship", not manage your whole portfolio — do that in ind.dash).
#
# Local wrapper functions are named mod_scholarship_SECTION_* (not
# mod_scholarship_entry_* — that name is gmed::mod_scholarship_entry_*'s
# own, and global.R's library(gmed) plus this file's source() both define
# top-level functions, so an exact name match here was needless collision
# risk, not just an unclear read — renamed 2026-09-16.

.pull_scholarship_rows <- function(record_id) {
  tryCatch({
    resp <- httr::POST(
      app_config$redcap_url,
      body = list(
        token = app_config$rdm_token, content = "record", action = "export",
        format = "json", type = "flat",
        records     = as.character(record_id),
        `forms[0]`  = "scholarship",
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
          dat$redcap_repeat_instrument == "scholarship", , drop = FALSE]
  }, error = function(e) data.frame())
}

mod_scholarship_section_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$p(class = "small text-muted", style = "margin-bottom: 12px;",
      "Add new scholarly work — including noon conference, PCEC, or afternoon-school ",
      "presentations, or anything else worth recording. Manage or edit past entries in ",
      "the full dashboard."),
    uiOutput(ns("count_summary")),
    gmed::mod_scholarship_entry_ui(ns("entry"))
  )
}

mod_scholarship_section_server <- function(id, resident_id) {
  moduleServer(id, function(input, output, session) {
    refresh <- reactiveVal(0)

    existing <- reactive({
      refresh()
      req(resident_id())
      .pull_scholarship_rows(resident_id())
    })

    output$count_summary <- renderUI({
      n <- nrow(existing())
      div(class = "mb-3",
        style = "font-size:1.4rem; font-weight:700; color:var(--roundsui-accent);",
        n,
        tags$span(style = "font-size:0.78rem; font-weight:400; color:var(--roundsui-ink-muted); margin-left:6px;",
          if (n == 1) "scholarly work on file" else "scholarly works on file")
      )
    })

    saved <- gmed::mod_scholarship_entry_server(
      "entry",
      resident_id   = resident_id,
      existing_data = existing,
      redcap_url    = app_config$redcap_url,
      rdm_token     = app_config$rdm_token
    )

    # A save only updates gmed's own internal saved_row() reactive, not
    # this module's `existing` pull — bump `refresh` so the count above
    # (and existing_data, for the collection-picker/most-meaningful-cap)
    # reflect a just-added entry without waiting for a full page reload.
    observeEvent(saved(), refresh(refresh() + 1), ignoreNULL = TRUE)
  })
}
