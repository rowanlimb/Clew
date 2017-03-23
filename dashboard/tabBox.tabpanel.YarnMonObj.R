#Copyright (c) 2017 BT Plc (www.btplc.com)
#
#You should have received a copy of the MIT license along with Clew.
#If not, see https://opensource.org/licenses/MIT

library(plotly)
library(shinydashboard)
library(jsonlite)
library(tidyr)
library(shiny)


tabBox.tabpanel.YarnMonObj = new.env()

getColourforThreshold <- function(param,threshold1,threshold2) {
  if ( param > threshold1 ) {
    config::get("yarn_alert_colour")
  }
  else if (param > threshold2 ) {
    config::get("yarn_warn_colour")
  }
  else {
    config::get("yarn_ok_colour")
  }
}

hostList <- config$yarn_rm_host_list
portList <- config$yarn_rm_port_list
numclusters <- config$num_clusters

nodeNameList <- config$cluster_name_list

#main function to call all display function
tabBox.tabpanel.YarnMonObj$displayData <- function()
{
  
  tabBox.tabpanel.YarnMonObj$CurrentStatus()
}


tabBox.tabpanel.YarnMonObj$CurrentStatus <- function()
{
  if(length(hostList) == numclusters && length(portList) == numclusters) {
    yarn_currentarray = list()
    yarn_appspendingcols = c()
    yarn_resmemcols = c()
    yarn_pendingcontainerscols = c()
    yarn_unhealthynodescols = c()
    yarn_lostnodescols = c()

    for(i in 1:numclusters) {
      host <- hostList[i]
      port <- portList[i]

      if(is.null(host) || is.null(port)) return()
      metricsjson <- paste0("http://",host,":",port,"/ws/v1/cluster/metrics")
      metrics_data <- fromJSON(metricsjson)$clusterMetrics
      yarn_currentarray[[i]] = data.frame(metrics_data)

      yarn_appspendingcols[i] <- getColourforThreshold(
        yarn_currentarray[[i]][1,"appsPending"],
        config$yarn_apps_pending_alert_threshold,
        config$yarn_apps_pending_warn_threshold
      )
      yarn_resmemcols[i] <- getColourforThreshold(
        yarn_currentarray[[i]][1,"reservedMB"],
        config$yarn_memreserved_alert_threshold,
        config$yarn_memreserved_warn_threshold
      )
      yarn_pendingcontainerscols[i] <- getColourforThreshold(
        yarn_currentarray[[i]][1,"containersPending"],
        config$yarn_containers_pending_alert_threshold,
        config$yarn_containers_pending_warn_threshold
      )
      yarn_unhealthynodescols[i] <- getColourforThreshold(
        yarn_currentarray[[i]][1,"unhealthyNodes"],
        config$yarn_unhealthynodes_alert_threshold,
        config$yarn_unhealthynodes_warn_threshold
      )
      yarn_lostnodescols[i] <- getColourforThreshold(
        yarn_currentarray[[i]][1,"lostNodes"],
        config$yarn_lostnodes_alert_threshold,
        config$yarn_lostnodes_warn_threshold
      )
  
    }

    output$tabBox.YarnMon.yarn <- renderUI({
      lapply(1:numclusters, function(i) {
        box(
          title = nodeNameList[i], width = 5, solidHeader = TRUE, status = "primary",
          valueBox(yarn_currentarray[[i]][1,"appsRunning"],"Apps Running", color = config$yarn_ok_colour, width=6),
          valueBox(yarn_currentarray[[i]][1,"appsPending"],"Apps Pending", color = yarn_appspendingcols[i], width=6),
          valueBox(yarn_currentarray[[i]][1,"reservedMB"],"Reserved MB",color=yarn_resmemcols[i],width=6),
          valueBox(yarn_currentarray[[i]][1,"containersPending"],"Pending Containers",color=yarn_pendingcontainerscols[i],width=6),
          valueBox(yarn_currentarray[[i]][1,"unhealthyNodes"],"Unhealthy Nodes",color=yarn_unhealthynodescols[i],width=6),
          valueBox(yarn_currentarray[[i]][1,"lostNodes"],"Lost Nodes",color=yarn_lostnodescols[i],width=6)
       )
      })
    })

  }
  else {
    output$tabBox.YarnMon.yarn <- renderUI({
        box(
          title = "Error in configuration. Number of clusters does not match Yarn host/port setting. Please contact your Administrator", width = 5, solidHeader = TRUE, status = "danger",
          br()
        )
    })
  }  
}
