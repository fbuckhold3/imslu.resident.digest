# ui.R ─ imslu.resident.digest
# Thin shell: a login screen (gmed's shared auth module), then one page of
# stacked sections after sign-in. `?section=<id>` in the URL (set by the
# email's per-section links) opens that section on load — see the
# `session$clientData$url_search` handling in server.R.
#
# roundsui shell ("Ward Notes" — same visual system ind.dash's own
# roundsui-integration-test branch uses), with gmed's CSS ALSO loaded
# alongside it — same dual-loading pattern ind.dash's ui.R already
# establishes, since gmed's mod_auth_ui/mod_faculty_eval/etc. still read
# --gmed-*/--ssm-* custom properties directly (roundsui's --roundsui-*
# tokens don't collide, by design — see roundsui's theme.R header).
# This app applies roundsui at the shell/header level (page wrapper,
# resident panel, this app's own stat cards) — the shared entry modules
# promoted from ind.dash (duty hours, attendance, faculty eval, peer
# review, scholarship) keep their existing gmed/SSM styling as-is; a full
# recolor of those is a separate, larger task, same "app-by-app" rollout
# already in progress elsewhere in this ecosystem.

ui <- roundsui::roundsui_page(
  title = "Weekly Resident Review",

  useShinyjs(),

  gmed::load_gmed_styles(),

  tags$head(
    tags$link(
      rel  = "stylesheet",
      href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    )
  ),

  uiOutput("main_view")
)
