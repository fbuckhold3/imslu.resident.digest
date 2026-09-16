# server.R ─ imslu.resident.digest
#
# Auth (gmed's shared access-code module, same as every other app in this
# ecosystem) then a single page of 5 stacked sections. `?section=<id>` in
# the URL opens the matching section on load — same
# session$clientData$url_search / parseQueryString() pattern ind.dash's
# server.R already uses for its `?code=` auto-fill.

server <- function(input, output, session) {

  values <- reactiveValues(authenticated = FALSE, resident = NULL)

  auth_result <- gmed::mod_auth_server(
    id = "auth",
    residents_r = reactive(residents_store)
  )

  observeEvent(auth_result(), {
    res <- auth_result()
    req(isTRUE(res$success))
    values$authenticated <- TRUE
    values$resident <- res$resident_info
  })

  observeEvent(input$sign_out, {
    values$authenticated <- FALSE
    values$resident <- NULL
  })

  resident_id <- reactive({
    req(values$resident)
    values$resident$record_id
  })

  all_residents <- reactive({
    req(values$authenticated)
    residents_store
  })

  # Requested-open section from the email's per-section links
  # (?section=duty_hours / attendance / evaluations / peer_review / scholarship).
  requested_section <- reactive({
    req(values$authenticated)
    query <- parseQueryString(session$clientData$url_search)
    sec <- query[["section"]]
    valid <- c("duty_hours", "attendance", "evaluations", "faculty_eval", "peer_review", "scholarship")
    if (!is.null(sec) && sec %in% valid) sec else "duty_hours"
  })

  mod_duty_entry_server(        "duty_hours",  resident_id = resident_id)
  mod_attendance_entry_server(  "attendance",  resident_id = resident_id)
  mod_eval_summary_server(      "evaluations", resident_id = resident_id)
  mod_faculty_entry_server(     "faculty_eval", resident_id = resident_id)
  mod_peer_entry_server(        "peer_review", resident_id = resident_id, all_residents_r = all_residents)
  mod_scholarship_section_server("scholarship", resident_id = resident_id)

  output$main_view <- renderUI({
    if (!values$authenticated) {
      return(gmed::mod_auth_ui("auth", app_title = "Weekly Resident Review",
                               app_subtitle = "Internal Medicine Residency"))
    }

    res         <- values$resident
    res_name    <- if (!is.null(res[["name"]])) res[["name"]] else "Resident"
    res_level   <- res[["Level"]]
    access_code <- res[["access_code"]]
    coach_code  <- res[["coach"]]
    coach_name  <- if (!is.null(coach_code) && !is.na(coach_code) && nzchar(as.character(coach_code)))
                     gmed::get_coach_name_from_code(coach_code) else NULL

    tagList(
      div(class = "d-flex justify-content-between align-items-start mb-3 flex-wrap gap-2",
        roundsui::roundsui_resident_panel(
          resident_name = res_name, level = res_level,
          coach = coach_name, access_code = access_code
        ),
        tags$button(class = "btn btn-sm btn-outline-danger",
          onclick = "Shiny.setInputValue('sign_out', Math.random(), {priority:'event'})",
          tags$i(class = "bi bi-box-arrow-right me-1"), "Sign Out")
      ),
      tags$p(class = "mb-4", style = "color:var(--roundsui-ink-muted); font-size:0.95rem; max-width:720px;",
        "As the week wraps up, take a few minutes to review and update the information below — ",
        "confirm your duty hours, log any conference attendance you missed, and check in on your evaluations."),
      bslib::accordion(
        id = "sections", open = requested_section(),
        bslib::accordion_panel("Duty Hours", value = "duty_hours",
                               icon = tags$i(class = "bi bi-clock"),
                               mod_duty_entry_ui("duty_hours")),
        bslib::accordion_panel("Noon Conference Attendance", value = "attendance",
                               icon = tags$i(class = "bi bi-calendar-check"),
                               mod_attendance_entry_ui("attendance")),
        bslib::accordion_panel("Evaluations & Feedback", value = "evaluations",
                               icon = tags$i(class = "bi bi-clipboard2-check"),
                               mod_eval_summary_ui("evaluations")),
        bslib::accordion_panel("Evaluate a Faculty Member", value = "faculty_eval",
                               icon = tags$i(class = "bi bi-person-badge"),
                               mod_faculty_entry_ui("faculty_eval")),
        bslib::accordion_panel("Peer Review", value = "peer_review",
                               icon = tags$i(class = "bi bi-people"),
                               mod_peer_entry_ui("peer_review")),
        bslib::accordion_panel("Scholarship", value = "scholarship",
                               icon = tags$i(class = "bi bi-journal-bookmark"),
                               mod_scholarship_section_ui("scholarship"))
      )
    )
  })
}
