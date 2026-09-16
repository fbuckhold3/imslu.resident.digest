# mod_duty_entry.R ─ Duty Hours section
#
# Identical composition to imslu.ind.dash's mod_duty_hours.R (that file is
# already fully portable — no ind.dash-specific coupling beyond
# app_config$rdm_token/redcap_url, which this app defines the same way) —
# duplicated here rather than imported because this is a plain Shiny app,
# not a package ind.dash could depend on. All the real logic lives in
# amiontools; this stays a thin composer, matching ind.dash's copy exactly
# so the two don't drift in behavior even though the file itself is
# duplicated.

mod_duty_entry_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$div(
      class = "small text-muted", style = "margin-bottom: 16px; max-width: 720px;",
      tags$p(style = "margin-bottom: 4px;",
        tags$strong("What this page does: "),
        "Your calendar and schedule below are pre-filled from Amion — your program's schedule ",
        "isn't a record of what you actually worked, just what you were assigned. Click any past ",
        "or current day to confirm it's accurate, or correct it if it isn't. Add moonlighting and ",
        "at-home chart-review time too — both count toward your duty hours."
      ),
      tags$p(style = "margin-bottom: 0;",
        "Accurate reporting matters: it's how the program and GME office track ACGME compliance, ",
        "and how excessive-hours patterns get caught before they become a problem for you."
      )
    ),
    amiontools::mod_duty_hour_calendar_ui(ns("calendar")),
    tags$hr(style = "margin: 20px 0;"),
    amiontools::mod_duty_hour_confirm_ui(ns("confirm")),
    tags$hr(style = "margin: 24px 0;"),
    amiontools::mod_duty_hour_summary_ui(ns("summary"))
  )
}

mod_duty_entry_server <- function(id, resident_id) {
  moduleServer(id, function(input, output, session) {
    refresh <- reactiveVal(0)
    selected_date <- reactiveVal(NULL)

    # Shared crosswalk/Amion fetch — one fetch per session, threaded into
    # both children below. See ind.dash's mod_duty_hours.R for the
    # "doom loop" perf bug this pattern was built to avoid.
    shared <- amiontools::use_amion_data(
      rdm_token  = app_config$rdm_token,
      redcap_url = app_config$redcap_url
    )

    entries_r <- reactive({
      refresh()
      req(resident_id())
      amiontools::pull_duty_hour_log(app_config$rdm_token, app_config$redcap_url,
                                     record_id = resident_id())
    })

    amion_blocks_r <- reactive({
      req(resident_id())
      summ <- amiontools::build_duty_hour_summary(
        rdm_token = app_config$rdm_token, redcap_url = app_config$redcap_url,
        crosswalk = shared$crosswalk(), amion = shared$amion(),
        entries = data.frame()
      )
      summ$duty_blocks |> dplyr::filter(record_id == resident_id())
    })

    amiontools::mod_duty_hour_calendar_server("calendar", resident_id = resident_id,
                                  entries_r = entries_r, amion_blocks_r = amion_blocks_r,
                                  selected_date = selected_date)
    amiontools::mod_duty_hour_confirm_server("confirm", resident_id = resident_id,
                                 entries_r = entries_r, amion_blocks_r = amion_blocks_r,
                                 refresh = refresh, selected_date = selected_date,
                                 redcap_url = app_config$redcap_url, rdm_token = app_config$rdm_token)
    amiontools::mod_duty_hour_summary_server(
      "summary",
      resident_id = resident_id,
      rdm_token   = app_config$rdm_token,
      redcap_url  = app_config$redcap_url,
      crosswalk_r = shared$crosswalk,
      amion_r     = shared$amion,
      entries_r   = entries_r
    )
  })
}
