# mod_eval_summary.R ─ Evaluations & Feedback section
#
# Read-only counts + nudges. Nothing for the resident to enter here:
#   - Evaluations RECEIVED (faculty/fellows evaluating the resident, via
#     resident.assessment's `assessment` instrument) — this is feedback
#     about them, no entry action makes sense, but a link out to the live
#     resident.assessment app (Fred, 2026-09-16) lets the resident hand a
#     supervising faculty member a direct link to go complete one — that
#     app is where FACULTY log in and evaluate RESIDENTS, the opposite
#     direction from "Evaluate a Faculty Member" below.
#   - Evaluations the resident has COMPLETED of faculty and peer reviews
#     both get a count + a "not done this week yet" nudge here, but the
#     actual entry is elsewhere on this same page — the Evaluate a Faculty
#     Member section (mod_faculty_entry.R, promoted from ind.dash) and the
#     Peer Review section (mod_peer_entry.R). No ind.dash link for either —
#     everything actionable lives in this one app, per Fred's call
#     (2026-09-16).

# FACULTY-facing tool where they log in and evaluate RESIDENTS — separate
# live app, not built or promoted here. A resident shares this link with a
# supervising faculty member to prompt an evaluation.
.RESIDENT_ASSESSMENT_URL <- "https://fbuckhold3-imslu-resident-assessment.share.connect.posit.cloud"

mod_eval_summary_ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("body"))
}

mod_eval_summary_server <- function(id, resident_id) {
  moduleServer(id, function(input, output, session) {

    stats <- reactive({
      req(resident_id())
      rid <- resident_id()
      received <- gmed::count_recent_instances(
        rdm_token = app_config$rdm_token, redcap_url = app_config$redcap_url,
        record_id = rid, instrument = "assessment", date_field = "ass_date", days = 7)
      completed_2wk <- gmed::count_recent_instances(
        rdm_token = app_config$rdm_token, redcap_url = app_config$redcap_url,
        record_id = rid, instrument = "faculty_evaluation", date_field = "fac_eval_date", days = 14)
      completed_1wk <- gmed::count_recent_instances(
        rdm_token = app_config$rdm_token, redcap_url = app_config$redcap_url,
        record_id = rid, instrument = "faculty_evaluation", date_field = "fac_eval_date", days = 7)
      peer <- amiontools::peer_count_completed_recent(
        evaluator_id = rid, redcap_url = app_config$redcap_url, rdm_token = app_config$rdm_token,
        days = 14)
      peer_1wk <- amiontools::peer_count_completed_recent(
        evaluator_id = rid, redcap_url = app_config$redcap_url, rdm_token = app_config$rdm_token,
        days = 7)
      list(received = received, completed_2wk = completed_2wk,
           completed_done_this_week = completed_1wk$n > 0,
           peer = peer, peer_done_this_week = peer_1wk$n > 0)
    })

    .stat_card <- function(number, label, sub = NULL) {
      roundsui::roundsui_card(
        class = "text-center",
        div(style = "font-size:1.8rem; font-weight:700; color:var(--roundsui-accent); line-height:1.1;",
            number),
        div(style = "font-size:0.78rem; color:var(--roundsui-ink-muted); margin-top:4px;", label),
        if (!is.null(sub)) div(style = "font-size:0.75rem; color:var(--roundsui-warning); margin-top:2px;", sub)
      )
    }

    output$body <- renderUI({
      s <- stats()
      tagList(
        div(class = "row g-3 mb-3",
          div(class = "col-sm-4", .stat_card(s$received$n, "Evaluations Received — Past Week")),
          div(class = "col-sm-4", .stat_card(s$completed_2wk$n, "Faculty Evals You've Completed — Last 2 Weeks",
                if (!s$completed_done_this_week) "None yet this week")),
          div(class = "col-sm-4", .stat_card(s$peer$n, "Peer Reviews You've Completed — Last 2 Weeks",
                if (!s$peer_done_this_week) "None yet this week"))
        ),
        p(style = "color:var(--roundsui-ink-muted); font-size:0.85rem;",
          "Getting evaluated regularly matters — if the count on the left looks low, ",
          "consider asking a supervising faculty member for feedback this week."),
        div(class = "mb-3",
          tags$a(href = .RESIDENT_ASSESSMENT_URL, target = "_blank",
                 class = "btn btn-sm btn-outline-primary",
                 tags$i(class = "bi bi-box-arrow-up-right me-1"),
                 "Share Evaluation Link with a Faculty Member")),
        if (!s$completed_done_this_week)
          p(style = "color:var(--roundsui-ink-muted); font-size:0.85rem;",
            "Haven't evaluated a faculty member this week? See the ",
            tags$strong("Evaluate a Faculty Member"), " section below."),
        if (!s$peer_done_this_week)
          p(style = "color:var(--roundsui-ink-muted); font-size:0.85rem;",
            "Haven't done a peer review this week? See the ",
            tags$strong("Peer Review"), " section below.")
      )
    })
  })
}
