#Copyright (c) 2017 BT Plc (www.btplc.com)
#
#You should have received a copy of the MIT license along with Clew.
#If not, see https://opensource.org/licenses/MIT

tabBox.tabpanel.DashboardObj = new.env()

tableList <- config$mysql_latency_table_list

current_alertThreshold <- config$hive_currentlatency_alert_threshold
current_alertColour <- config$hive_currentlatency_alert_colour
current_warnThreshold <- config$hive_currentlatency_warn_threshold
current_warnColour <- config$hive_currentlatency_warn_colour
current_okColour <- config$hive_currentlatency_ok_colour

max_alertThreshold <- config$hive_maxlatency_alert_threshold
max_alertColour <- config$hive_maxlatency_alert_colour
max_warnThreshold <- config$hive_maxlatency_warn_threshold
max_warnColour <- config$hive_maxlatency_warn_colour
max_okColour <- config$hive_maxlatency_ok_colour

numclusters <- config$num_clusters
nodeNameList <- config$cluster_name_list

#main function to call all display function
tabBox.tabpanel.DashboardObj$displayData <- function()
{
  tabBox.tabpanel.DashboardObj$InstantHiveLatency()
}


tabBox.tabpanel.DashboardObj$InstantHiveLatency <- function() {
  
  if (length(tableList) == numclusters ) {
     hldb  <- dbConnect(RMySQL::MySQL(), group = config$mysql_option_group)
     hivecurrlatencyarray = c()
     hivecurrdatearray = c()
     hivecurrcolarray = c()

     hivemaxlatencyarray = c()
     hivemaxdatearray = c()
     hivemaxcolarray = c()

     for(i in 1:numclusters) {
       query <- dbGetQuery(hldb, paste0("SELECT * FROM ", tableList[i], " order by date desc limit 12"))

       hivecurrlatencyarray[i] = query$latency[1]
       hivecurrdatearray[i] = query$date[1]

       if (hivecurrlatencyarray[i]>current_alertThreshold){
          hivecurrcolarray[i]=current_alertColour
       }
       else if (hivecurrlatencyarray[i]>current_warnThreshold){
          hivecurrcolarray[i]=current_warnColour
       }
       else{
          hivecurrcolarray[i]=current_okColour
       }

       hivemaxlatencyarray[i] = max(query$latency)
       hivemaxdatearray[i] = query$date[query$latency==hivemaxlatencyarray[i]][1]

       if (hivemaxlatencyarray[i]>max_alertThreshold){
          hivemaxcolarray[i]=max_alertColour
       }
       else if (hivemaxlatencyarray[i]>max_warnThreshold){
          hivemaxcolarray[i]=max_warnColour
       }
       else{
          hivemaxcolarray[i]=max_okColour
       }

     }
 
     dbDisconnect(hldb)

     output$tabBox.dash.hivelat <- renderUI({
        lapply(1:numclusters, function(i) {
           box(
              title = nodeNameList[i], width = 5, solidHeader = TRUE, status = "primary",
              valueBox(paste0(round(hivecurrlatencyarray[i],2),"s") , paste0("Latency at ",hivecurrdatearray[i]),color = hivecurrcolarray[i], icon=icon("time", lib = "glyphicon")),
              valueBox(paste0(round(hivemaxlatencyarray[i],2),"s") , paste0("Max Latency at ",hivemaxdatearray[i]),color = hivemaxcolarray[i], icon=icon("time", lib = "glyphicon"))
           )
        })
     })

  }

}
  
