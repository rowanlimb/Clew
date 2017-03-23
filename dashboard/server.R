#Copyright (c) 2017 BT Plc (www.btplc.com)
#
#You should have received a copy of the MIT license along with Clew.
#If not, see https://opensource.org/licenses/MIT

library(jsonlite)
library(shiny)
library(visNetwork)
library(plyr)
library(ggplot2)
library(lubridate)
library(config)
library(RMySQL)
library(shinyBS)

if(file.exists("config.yml")) {
  config <- config::get(use_parent=FALSE)
}

server <- function(input, output, session) {
  
  source("config_utils.R", local = TRUE)
  chk <- config_utils$checkConfig()
  
  if(chk==0) {
  
  source("tabBox.tabpanel.DashboardObj.R",local = TRUE)
  source("tabBox.tabpanel.MetricsObj.R",local=TRUE)
  source("tabBox.tabpanel.YarnMonObj.R",local=TRUE)
  source("tabBox.tabpanel.HistServerObj.R",local=TRUE)
  source("tabBox.tabpanel.QueueWaitObj.R",local=TRUE)
  source("tabBox.tabpanel.BeelineLatencyObj.R",local=TRUE)

  
  observe({
    tabBox.tabpanel.DashboardObj$displayData()
  })
  
  observe({
    tabBox.tabpanel.YarnMonObj$displayData()
  })
  
  observe({
    tabBox.tabpanel.BeelineLatencyObj$displayData()
  })
  
  }
  else {
    msg <- if(chk<0) {"Config file is missing."} else {
        if(chk==1) {"There is 1 config error."} else {paste("There are",chk,"config errors.")}
      }
    msg <- paste(msg,"Please contact your Administrator.")
    createAlert(session, "configAlert", "exampleAlert", title = "Oops",
                content = msg, append = FALSE, style="danger",dismiss = FALSE)
  }
  

}


