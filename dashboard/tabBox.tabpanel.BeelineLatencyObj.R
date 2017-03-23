#Copyright (c) 2017 BT Plc (www.btplc.com)
#
#You should have received a copy of the MIT license along with Clew.
#If not, see https://opensource.org/licenses/MIT

tabBox.tabpanel.BeelineLatencyObj = new.env()

latThreshold <- config$hive_currentlatency_alert_threshold

tableList <- config$mysql_latency_table_list
numclusters <- config$num_clusters
nodeNameList <- config$cluster_name_list

mycolors <- c("#4DAF4A", "#000000", "#E41A1C")
names(mycolors) <- c("SUCCEEDED", "KILLED", "FAILED")
mycolramp <-
  colorRamp(
    c("#4a63b0", "#4daf4a", "#ffff66"),
    interpolate = "spline",
    space = "rgb",
    bias = 5
  )
hm_yaxis_props <-
  list(
    title = " ",
    showline = FALSE,
    zeroline = FALSE,
    showline = FALSE,
    showticklabels = FALSE,
    showgrid = FALSE,
    nticks = 1
  )

tabBox.tabpanel.BeelineLatencyObj$displayData <- function() {
  tabBox.tabpanel.BeelineLatencyObj$displayClusterData()
}

tabBox.tabpanel.BeelineLatencyObj$displayClusterData <- function() {
  
  if (length(tableList) > 0 && length(tableList) == numclusters) {
      #Dynamic plots for each cluster
      output$tabBox.BeelineLatency.plots <- renderUI({
         #Create list of plot objects
         plot_output_list <- lapply(1:numclusters, function(i) {
            plotname <- paste("plot", i, sep="")
            plotlyOutput(plotname)
         })
         #Place plot objects in a box layout (plots side by side)
         lapply(1:numclusters, function(i) {
            box(
               title = nodeNameList[i], width = 5, solidHeader = TRUE, status = "primary",
               plot_output_list[i]
            )
         })
      })

      #heatmap plots list
      output$tabBox.BeelineLatency.hmplots <- renderUI({
         #Create list of plot objects
         hmplot_output_list <- lapply(1:numclusters, function(i) {
            plotname <- paste("hmplot", i, sep="")
            plotlyOutput(plotname)
         })
         #Place plot objects in a box layout (plots side by side)
         lapply(1:numclusters, function(i) {
            box(
               title = nodeNameList[i], width = 5, solidHeader = TRUE, status = "primary",
               hmplot_output_list[i]
            )
         })
      })

    #mysql version
    #gets credentials and database from ~/.my.cnf
    hive_mon_db <-
      dbConnect(
        RMySQL::MySQL(),
        group = config$mysql_option_group
      )
    #Get data and call renderPlot for each plot in the list created above
    for(nc in 1:numclusters) {

    dl1a <-
      dbGetQuery(
        hive_mon_db,
        paste0(
          "SELECT cluster, date as dt, latency FROM ",
          tableList[nc],
          " where date >= date_add(curdate(), interval -8 day)"
        )
      )
    
    #beeline data is stored in local timezone, inc daylight savings
    dl1a$ts = as.POSIXct(dl1a$dt, tz = "Europe/London", format = "%Y-%m-%d %H:%M:%S")
    dl1a$dayhour <-
      paste0(format(as.POSIXlt(dl1a$ts), "%d"), "/", format(as.POSIXlt(dl1a$ts), "%H"))
    dl1a$day <- format(as.POSIXlt(dl1a$ts), "%d")
    dl1a$ym <- format(dl1a$ts, "%Y-%m-%d")
    
    if (nrow(dl1a) > 0) {
      dl1a$date <- as.POSIXct(strptime(dl1a$dt, "%Y-%m-%d"))
      
      #get first Sat or Sun in dataset

      #first check we have Sat and Sun in data....
      if(all(c('Saturday', 'Sunday') %in% weekdays(dl1a$ts))) {
         start_we <-
           min(subset(dl1a, subset = (
             weekdays(dl1a$ts) %in% c('Saturday', 'Sunday')
           ))$ts)
         #convert to lubridate time to use library's function to convert to midnight of that day
         start_we <- floor_date(start_we, "day")
         #to use shapes in plot to highlight weekends, need to use epoch times in milliseconds
         #get epoch time in millis from start_we
         we_hl_start <- as.integer(start_we) * 1000
      
         numdays_to_first_we <-
           ceiling(interval(floor_date(min(dl1a$ts), "day"), start_we) / ddays(1))
      }
      else {start_we <- NULL}
      
      dhagg <- aggregate(latency ~ dayhour + day + ym, data = dl1a, sum)
      dhagg$day <- as.factor(dhagg$day)
      dhagg$dayhour <- as.factor(dhagg$dayhour)
      
      threshdata <- dhagg[dhagg$latency > latThreshold, ]
      if (nrow(threshdata) > 0) {
        count_of_outliers_by_day <-
          aggregate(latency ~ day + ym, data = threshdata, FUN = length)
      }
      else {
        count_of_outliers_by_day <- NULL
      }
      
    }
  
        local({
          my_i <- nc
          plotname <- paste("plot", my_i, sep="")

          output[[plotname]] <- renderPlotly({
             shapes <- list()
             if(!is.null(start_we)) {
                numdays <- ceiling(interval(floor_date(min(dl1a$ts), "day"), round_date(max(dl1a$ts), "day")) / ddays(1))
                incr <- 7
                #calculate number of weekends in date range in data and draw rectangles at each weekend to highlight
                for (i in 1:(((numdays - 1) %/% 7) + 1)) {
                   #need to check if starting on a Sunday as then only one day to highlight at start, and only 6 days to start of next weekend
                   we_num <-
                   wday(as.POSIXct(we_hl_start / 1000, origin = "1970-01-01"))
                   if (i == 1 && we_num == 1) {
                      xstart = we_hl_start + ((i - 1) * incr * 24 * 3600 * 1000)
                      xend = xstart + (24 * 3600 * 1000)
                      incr <- 6
                   }
                   else {
                      xstart = we_hl_start + ((i - 1) * incr * 24 * 3600 * 1000)
                      xend = xstart + (48 * 3600 * 1000)
                      incr <- 7
                   }
                   shapes[[i]] <- list(
                     type = "rect",
                     xref = "x",
                     yref = "y",
                     x0 = xstart,
                     y0 = 0,
                     x1 = xend,
                     y1 = max(dl1a$latency) * 1.2,
                     fillcolor = "#cccccc",
                     opacity = 0.3,
                     line = list(width = 0)
                   )
                }
             } 
             plot_ly(
               dl1a,
               x = ~ dt,
               y = ~ latency,
               text = paste0("Date"),
               type = "bar"
             ) %>%
             layout(
               dragmode = "select",
               xaxis = list(
                 type = "date",
                 title = "Date",
                 tickfont = list(size = 10),
                 tickformat = "%a %d-%m-%Y"
               ),
               yaxis = list(title = "Latency (s)"),
               shapes = shapes
             )
          })

          hmplotname <- paste("hmplot", my_i, sep="")

          output[[hmplotname]] <- renderPlotly({
             if(!is.null(count_of_outliers_by_day)) {
                latency <-
                matrix(
                  data = count_of_outliers_by_day$latency,
                  nrow = 1,
                  ncol = nrow(count_of_outliers_by_day)
                )
                vals <-
                   unique(scales::rescale(c(
                   count_of_outliers_by_day$latency
                )))
                o <- order(vals, decreasing = FALSE)
                cols <-
                  scales::col_numeric(mycolramp, domain = NULL)(vals)
                colz <- setNames(data.frame(vals[o], cols[o]), NULL)
                p <-
                  plot_ly(
                    z = latency,
                    colorscale = colz,
                    x = count_of_outliers_by_day$ym,
                    y = "1",
                    type = "heatmap"
                  ) %>%
                  layout(yaxis = hm_yaxis_props, xaxis = list(title = "Date"))
             }
             else {
                p <- plot_ly(type="bar") %>%
                  layout(title=paste("No outlier data above threshold:",latThreshold))
             } 
            
             p
          })
      
        })
    } #end of cluster loop of plots
    dbDisconnect(hive_mon_db)

    #After upgrade of plotly to 4.5.2, and ggplot2 to 2.2.0, event_data is broken. Official advice is
    #to either revert or use dev version of plotly. Since not sure we need to use event_data, comment
    #out for now
    
    
  }
  else {
     
     output$tabBox.BeelineLatency.plots <- renderUI({
        box(
           title="Error in configuration. No tables specified. Please contact your Administrator",
           solidHeader = TRUE, status = "danger",
           br()
        )
      })
     
     
     output$tabBox.BeelineLatency.heatmap_plotly <-
       renderPlotly({
         
         plot_ly(type="bar") %>%
           layout(title="Error in configuration. No tables specified. Please contact your Administrator")
       })
     
   }
  
}

