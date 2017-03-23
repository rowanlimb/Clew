#Copyright (c) 2017 BT Plc (www.btplc.com)
#
#You should have received a copy of the MIT license along with Clew.
#If not, see https://opensource.org/licenses/MIT

tabBox.tabpanel.QueueWaitObj = new.env()

qwmycolors <- c("#4DAF4A", "#000000", "#E41A1C")
names(qwmycolors) <- c("SUCCEEDED","KILLED","FAILED")

hist_hosts <- config$mr_jobhist_host_list
hist_ports <- config$mr_jobhist_port_list
mynumclusters <- config$num_clusters
nodeNameList <- config$cluster_name_list

qwgetAndParseHistData <- function(clusterIndex, states) {
   states <- paste(states, collapse = ',')
   if(is.null(states) || states == "") states = 'All'
   if(states == 'All') {
      query <- paste0('http://',hist_hosts[clusterIndex],':',hist_ports[clusterIndex],'/ws/v1/history/mapreduce/jobs/')
   }
   else {
      query <- paste0('http://',hist_hosts[clusterIndex],':',hist_ports[clusterIndex],'/ws/v1/history/mapreduce/jobs/?state=',states)
   }
   data <- fromJSON(query)
   if(length(data)>0) {
      data <- data$jobs$job
      return(data)
   }
   else {return(NULL)}
}

qwhist_data <- reactivePoll(60000,session,
              checkFunc = function() {
                Sys.time()
              },
              valueFunc = function() {
                lapply(1:mynumclusters, function(i) {
                     x <- qwgetAndParseHistData(i,input[[paste0("tabBox.QueueWait.State_radioGroup",i)]])
                     if(!is.null(x)) {
                       x$elapsedTime <- ((x$finishTime - x$startTime)/(60*1000))
                       x$waitTime <- ((x$startTime - x$submitTime)/(60*1000))
                       x$startTime <- as.POSIXct(x$startTime/1000, origin="1970-01-01")
                       x$finishTime <- as.POSIXct(x$finishTime/1000, origin="1970-01-01")
                       x$submitTime <- as.POSIXct(x$submitTime/1000, origin="1970-01-01")

                       x <- x[rev(order(x$startTime)),]
      
                     }
                     x
                })
              })

get_qwplot_output_list <- function() {
   ad <- qwhist_data()
   #Create list of plot objects
   qwhistplot_output_list <- lapply(1:mynumclusters, function(i) {
      plotname <- paste("qwaitplot", i, sep="")
      plot_output_object <- plotlyOutput(plotname)
      plot_output_object <- renderPlotly({
         states <- input[[paste0("tabBox.QueueWait.State_radioGroup",i)]]
         states <- paste(states, collapse = ",")

         appName <- input[[paste0("tabBox.QueueWait.appName_text",i)]]

         pd <- ad[[i]]

         if(!is.null(pd) && nrow(pd)>0) {

           pd <- pd[grep(appName,pd$name,ignore.case = TRUE),]
           if(nrow(pd)>0) {
             if(states == 'All') {
               if(length(unique(pd$state))==1) {
                 colorPal <- c(qwmycolors[pd$state[1]])
               }
               else colorPal <- qwmycolors
             }
             else {
               colorPal = c(qwmycolors[states])
             }

             plot_ly(pd, x = ~submitTime, y = ~waitTime, text="mins", color = ~state, colors = colorPal, key = ~id,  mode = "markers", type="scatter") %>%
             layout(dragmode = "select", xaxis = list(title = "Submit Time"), yaxis = list(title = "Time spent waiting (mins)"), showlegend=TRUE)
           }
           else {
             plot_ly()
           }
         }
         else {
           plot_ly()
         }
       #end of renderplotly
      })
   })

  return(qwhistplot_output_list)

}

output$qwait_selection<- renderUI({
   lapply(1:mynumclusters, function(i) {
      box(
         title = nodeNameList[i], width = 5, solidHeader = TRUE, status = "primary",
         column(2, textInput(paste0("tabBox.QueueWait.appName_text",i), label="App name")),
         radioButtons(paste0("tabBox.QueueWait.State_radioGroup",i), label = "States", inline = TRUE,
            choices = list("All" = 'All', "Succeeded" = 'SUCCEEDED', "Killed" = 'KILLED', "Failed" = 'FAILED'),
            selected = 'All')
      )
   })
})

observe({
   output$tabBox.QueueWait.plot <- renderUI({

      uilist <- get_qwplot_output_list()
      #Place plot objects in a box layout (plots side by side)
      lapply(1:mynumclusters, function(i) {
         box(
            title = nodeNameList[i], width = 5, solidHeader = TRUE, status = "primary",
            uilist[i]
         )
      })
   })
})

