#Copyright (c) 2017 BT Plc (www.btplc.com)
#
#You should have received a copy of the MIT license along with Clew.
#If not, see https://opensource.org/licenses/MIT

tabBox.tabpanel.MetricsObj = new.env()


hostList <- config$yarn_rm_host_list
portList <- config$yarn_rm_port_list
numclusters <- config$num_clusters
nodeNameList <- config$cluster_name_list

output$tabBox.Metrics.metrics <- renderUI({
   if(length(hostList) == numclusters && length(portList) == numclusters) {

     yarn_metrics = list()
     for(i in 1:numclusters) {
        metricsjson <- paste0('http://',hostList[i],':',portList[i],'/ws/v1/cluster/metrics')
        metrics_data <- fromJSON(metricsjson)$clusterMetrics
        d <- as.data.frame(metrics_data,row.names="")
        names(d) <- gsub("apps", "", names(d))
        yarn_metrics[[i]] <- d
     }

     lapply(1:numclusters, function(i) {
        box(
           title = nodeNameList[i], width = 5, solidHeader = TRUE, status = "primary",
           valueBox(yarn_metrics[[i]][1,"Submitted"],"Submitted", color = "aqua"),
           valueBox(yarn_metrics[[i]][1,"Completed"], "Completed", color="yellow"),
           valueBox(yarn_metrics[[i]][1,"Pending"], "Pending", color="light-blue"),
           valueBox(yarn_metrics[[i]][1,"Running"], "Running", color="green"),
           valueBox(yarn_metrics[[i]][1,"Failed"],"Failed",color="red"),
           valueBox(yarn_metrics[[i]][1,"Killed"],"Killed",color="navy"),
           infoBox("Total MB",yarn_metrics[[i]][1,"totalMB"],icon = icon("tachometer"),color="teal"),
           infoBox("Available MB",yarn_metrics[[i]][1,"availableMB"],icon = icon("tachometer"),color="teal"),
           infoBox("Allocated MB",yarn_metrics[[i]][1,"allocatedMB"],icon = icon("tachometer"),color="teal"),
           infoBox("Reserved MB",yarn_metrics[[i]][1,"reservedMB"],icon = icon("tachometer"),color="teal"),
           infoBox("Total Virtual Cores",yarn_metrics[[i]][1,"totalVirtualCores"],icon = icon("tachometer"),color="aqua"),
           infoBox("Available Virtual Cores",yarn_metrics[[i]][1,"availableVirtualCores"],icon = icon("tachometer"),color="aqua"),
           infoBox("Allocated Virtual Cores",yarn_metrics[[i]][1,"allocatedVirtualCores"],icon = icon("tachometer"),color="aqua"),
           infoBox("Reserved Virtual Cores",yarn_metrics[[i]][1,"reservedVirtualCores"],icon = icon("tachometer"),color="aqua"),
           infoBox("Allocated Containers",yarn_metrics[[i]][1,"containersAllocated"],icon = icon("tachometer"),color="orange"),
           infoBox("Reserved Containers",yarn_metrics[[i]][1,"containersReserved"],icon = icon("tachometer"),color="orange"),
           infoBox("Pending Containers",yarn_metrics[[i]][1,"containersPending"],icon = icon("tachometer"),color="orange"),
           infoBox("Total Nodes",yarn_metrics[[i]][1,"totalNodes"],icon = icon("tachometer"),color="navy"),
           infoBox("Active Nodes",yarn_metrics[[i]][1,"activeNodes"],icon = icon("tachometer"),color="navy"),
           infoBox("Unhealthy Nodes",yarn_metrics[[i]][1,"unhealthyNodes"],icon = icon("tachometer"),color="navy"),
           infoBox("Rebooted Nodes",yarn_metrics[[i]][1,"rebootedNodes"],icon = icon("tachometer"),color="navy"),
           infoBox("Lost Nodes",yarn_metrics[[i]][1,"lostNodes"],icon = icon("tachometer"),color="navy"),
           infoBox("Decommissioned Nodes",yarn_metrics[[i]][1,"decommissionedNodes"],icon = icon("tachometer"),color="navy")
        )
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
})

