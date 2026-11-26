# =============================================================================
# AIRWATCH 2026 - Air Quality Intelligence & Analytics Platform
# app.R : entry point. Open this file in RStudio and press "Run App".
#
# What this file does:
#   1. loads packages and the helper scripts in R/ and modules/
#   2. builds the page layout (fixed sidebar + header + hidden tab pages)
#   3. creates ONE shared data store that every module reads from
# =============================================================================

library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(lubridate)
library(plotly)
library(DT)

# ---- Load helper scripts (order matters: config first) -----------------------
for (f in c("config.R", "data_cleaning.R", "data_validation.R", "analysis.R", "visualization.R")) {
  source(file.path("R", f), local = FALSE)
}
for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) source(f, local = FALSE)

# ---- Navigation definition ---------------------------------------------------
# id = tab value, label = text in the sidebar, icon = Lucide icon name
NAV <- list(
  list(section = "OVERVIEW", items = list(
    list(id = "dashboard",  label = "Dashboard",         icon = "layout-dashboard"),
    list(id = "monitoring", label = "Latest Monitoring", icon = "activity"))),
  list(section = "ANALYTICS", items = list(
    list(id = "hourly",     label = "Hourly Analysis",        icon = "clock"),
    list(id = "trends",     label = "Daily & Monthly Trends", icon = "calendar-range"),
    list(id = "pollutants", label = "Pollutant Analysis",     icon = "flask-conical"),
    list(id = "location",   label = "Location Analysis",      icon = "map-pin"))),
  list(section = "INTELLIGENCE", items = list(
    list(id = "prediction", label = "AQI Prediction",      icon = "trending-up"),
    list(id = "alerts",     label = "Pollution Alerts",    icon = "triangle-alert"),
    list(id = "reports",    label = "Statistical Reports", icon = "sigma"))),
  list(section = "SYSTEM", items = list(
    list(id = "dataset",    label = "Dataset Management", icon = "database"),
    list(id = "about",      label = "About Project",      icon = "info")))
)

# Lucide icons are loaded from a CDN as inline <i data-lucide> tags.
nav_link <- function(item) {
  tags$a(
    href = "#", class = "aw-nav-link", `data-tab` = item$id,
    onclick = sprintf("Shiny.setInputValue('nav', '%s', {priority: 'event'}); return false;", item$id),
    tags$i(`data-lucide` = item$icon), tags$span(item$label)
  )
}
sidebar_ui <- tags$aside(
  class = "aw-sidebar", id = "aw-sidebar",
  div(class = "aw-brand",
      div(class = "aw-logo", tags$i(`data-lucide` = "wind")),
      div(div(class = "aw-brand-name", "AIRWATCH 2026"),
          div(class = "aw-brand-tag", "Breathe Smarter. Analyze Better."))),
  lapply(NAV, function(sec) tagList(div(class = "aw-nav-section", sec$section), lapply(sec$items, nav_link))),
  div(class = "aw-sidebar-foot", "Dataset-based historical analysis")
)

header_ui <- tags$header(
  class = "aw-header",
  tags$button(class = "aw-icon-btn aw-menu-btn", onclick = "document.body.classList.toggle('sidebar-open')",
              tags$i(`data-lucide` = "menu")),
  div(div(class = "aw-page-title", textOutput("page_title", inline = TRUE)),
      div(class = "aw-page-sub", textOutput("data_badge", inline = TRUE))),
  div(class = "aw-header-right",
      tags$button(class = "aw-icon-btn", id = "theme-toggle", title = "Toggle light / dark",
                  onclick = "toggleTheme()", tags$i(`data-lucide` = "sun-moon")))
)

# ---- UI ----------------------------------------------------------------------
ui <- tagList(
  tags$head(
    tags$title("AIRWATCH 2026"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"),
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$script(src = "https://unpkg.com/lucide@latest"),
    tags$script(src = "app.js")
  ),
  div(class = "aw-shell",
      sidebar_ui,
      div(class = "aw-main",
          header_ui,
          div(class = "aw-content",
              tabsetPanel(
                id = "main_tabs", type = "hidden",
                tabPanelBody("dashboard",  dashboardUI("dashboard")),
                tabPanelBody("monitoring", monitoringUI("monitoring")),
                tabPanelBody("hourly",     hourlyUI("hourly")),
                tabPanelBody("trends",     trendsUI("trends")),
                tabPanelBody("pollutants", pollutantsUI("pollutants")),
                tabPanelBody("location",   locationUI("location")),
                tabPanelBody("prediction", predictionUI("prediction")),
                tabPanelBody("alerts",     alertsUI("alerts")),
                tabPanelBody("reports",    reportsUI("reports")),
                tabPanelBody("dataset",    datasetUI("dataset")),
                tabPanelBody("about",      aboutUI("about"))
              ))),
      div(class = "aw-overlay", onclick = "document.body.classList.remove('sidebar-open')"))
)

# ---- Server ------------------------------------------------------------------
server <- function(input, output, session) {

  # Shared data store. Modules receive this object and read store$data / store$report.
  store <- reactiveValues(data = NULL, report = NULL, source = "none")

  # Load the project dataset on start-up (data/air_quality_2026.csv)
  default <- tryCatch(load_default_dataset(), error = function(e) NULL)
  if (!is.null(default)) {
    store$data <- default$data; store$report <- default$report
    store$source <- "data/air_quality_2026.csv"
  }

  # Sidebar navigation: JS sets input$nav, we switch the hidden tab and highlight.
  observeEvent(input$nav, {
    updateTabsetPanel(session, "main_tabs", selected = input$nav)
    session$sendCustomMessage("setActiveNav", input$nav)
    session$sendCustomMessage("closeSidebar", TRUE)
  })
  observe(session$sendCustomMessage("setActiveNav", "dashboard"))

  titles <- unlist(lapply(NAV, function(s) lapply(s$items, function(i) setNames(i$label, i$id))))
  output$page_title <- renderText({ t <- titles[[if (is.null(input$nav)) "dashboard" else input$nav]]; t })
  output$data_badge <- renderText({
    if (is.null(store$data)) "No dataset loaded - open Dataset Management to upload one"
    else sprintf("%s | %s to %s | %s records",
                 basename(store$source), format(store$report$date_min, "%d %b %Y"),
                 format(store$report$date_max, "%d %b %Y"), format(nrow(store$data), big.mark = ","))
  })

  # Start every module
  dashboardServer("dashboard", store)
  monitoringServer("monitoring", store)
  hourlyServer("hourly", store)
  trendsServer("trends", store)
  pollutantsServer("pollutants", store)
  locationServer("location", store)
  predictionServer("prediction", store)
  alertsServer("alerts", store)
  reportsServer("reports", store)
  datasetServer("dataset", store)
  aboutServer("about")
}

shinyApp(ui, server)
