#Copyright (c) 2017 BT Plc (www.btplc.com)
#
#You should have received a copy of the MIT license along with Clew.
#If not, see https://opensource.org/licenses/MIT

library(shinydashboard)
library(DT)
library(plotly)
library(shinyBS)

tags$script(type="text/javascript","
 $(document).ready(function() {
   Shiny.addCustomMessageHandler('testmessage',
     function(message) {
       alert(JSON.stringify(message));
   });
 });
")

header <- dashboardHeader(
  title = config::get("dashboard_title")
)

sidebar <- dashboardSidebar(
)

body <- dashboardBody(
  
  tags$style(type="text/css",
             ".recalculating { opacity: 1.0; }"
  ),
  
  fluidRow(
    bsAlert("configAlert"),
    width = 12
  ),
  
  fluidRow(
    tabBox(id='tabset1', width=12,
       tabPanel("Dashboard",
          fluidRow(
             box(
                title="Hive latency", width=2,solidHeader = TRUE, status = "primary",
                h5("Time to connect to the Hive meta-store before a query starts running.")
             ),
             uiOutput("tabBox.dash.hivelat")
          ),
          fluidRow(
             box(
                title="YARN Status",width=2,solidHeader = TRUE, status = "primary",
                h5("Main indicators of cluster activity and health in YARN")
             ),
             uiOutput("tabBox.YarnMon.yarn")
          )
       ),
       tabPanel("Metrics",
          fluidRow(
             uiOutput("tabBox.Metrics.metrics")
          )
       ),
       tabPanel("History Server",
          fluidRow(
             uiOutput("history_selection")
          ),
          fluidRow(
             uiOutput("tabBox.HistServer.plot")
          )
       ),
       tabPanel("Wait Time",
          fluidRow(
             uiOutput("qwait_selection")
          ),
          fluidRow(
             uiOutput("tabBox.QueueWait.plot")
          )
       ),
       tabPanel("Beeline Latency",
          h4("Latency plots"),
          fluidRow(
             uiOutput("tabBox.BeelineLatency.plots")
          ),
          h4("Heatmaps"),
          fluidRow(
             uiOutput("tabBox.BeelineLatency.hmplots")
          )
       )
     )
   )
)

dashboardPage(header, sidebar, body)


