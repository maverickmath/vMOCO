#install.packages("shiny")
#install.packages("shinydashboard")
#install.packages("plotly")
#install.packages("DT")


library(shiny)
library(shinydashboard)
library(plotly)
library(DT)




ui <- dashboardPage(
  dashboardHeader(title = "onlinemoco visualizer"),
  dashboardSidebar(
    sidebarMenu(id = "sidebar",
                menuItem("Data", tabName = "data", icon = icon("th")),
                menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
                fileInput("file1", "Choose CSV File",
                          accept = c(
                            "text/csv",
                            "text/comma-separated-values,text/plain",
                            ".csv")
                )
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "dashboard",
              fluidRow(
                tabBox(
                  title = "Inputs", width = 4,
                  # The id lets us use input$tabset1 on the server to find the current tab
                  id = "tabset1", height = "250px",
                  tabPanel("z1",
                           "Select a range for criterion values:",
                           sliderInput("slider1", "z1:", 1, 100, value = c(1,100), dragRange = TRUE)
                  ),
                  tabPanel("z2",
                           "Select a range for criterion values:",
                           sliderInput("slider2", "z2:", 1, 100, value = c(1,100), dragRange = TRUE)
                  ),
                  tabPanel("z3",
                           "Select a range for criterion values:",
                           sliderInput("slider3", "z3:", 1, 100, value = c(1,100), dragRange = TRUE)
                  )
                ),
                valueBoxOutput(width = 4, "numOfObjectives"),
                valueBoxOutput(width = 4, "numOfPoints")
              ),
              fluidRow(
                box(
                  title = "Scatter Plot: Filtered Points", status = "success", solidHeader = TRUE,
                  collapsible = TRUE,
                  selectInput("scatterPlotSelect1", "Select 2 or 3 criteria:",
                              c("z1", "z2", "z3"), selected = c("z1", "z2", "z3"), multiple = TRUE
                  ),
                  plotlyOutput("plot1")
                ),
                box(
                  title = "Parallel Coordinates Plot: Filtered Points", status = "warning", solidHeader = TRUE,
                  collapsible = TRUE,
                  plotlyOutput("plot2")
                )
              ),
              fluidRow(
                box(title = "Filtered Points", width = 6, DT::dataTableOutput("tableFiltered")),
                box(
                  title = "Scatter Plot: Selected Points", width = 6, status = "success", solidHeader = TRUE,
                  collapsible = TRUE,
                  plotlyOutput("plot11")
                ),
                box(
                  title = "Parallel Coordinates Plot: Selected Points", width = 6, status = "warning", solidHeader = TRUE,
                  collapsible = TRUE,
                  plotlyOutput("plot21")
                )
              )
      ),
      tabItem(tabName = "data",
              DT::dataTableOutput("table")
              
      )
    )
  )
)

server <- function(input, output, session) {
  output$table <- DT::renderDataTable({
    inFile <- input$file1
    
    if (is.null(inFile))
      return(NULL)
    
    ndpoints <-read.csv(inFile$datapath, header = TRUE, sep = ",")
    
    # render value boxes
    nobj = ncol(ndpoints)
    npoints = nrow(ndpoints)
    
    output$numOfObjectives <- renderValueBox({
      valueBox(nobj, "criteria", icon = icon("arrows"), color = "red")
    })
    output$numOfPoints <- renderValueBox({
      valueBox(npoints, "nondominated points", icon = icon("archive"), color = "blue")
    })
    
    # update the slider input box
    updateSliderInput(session, "slider1", 
                      min = min(ndpoints$z1, na.rm = TRUE),
                      max = max(ndpoints$z1, na.rm = TRUE),
                      value = c(min,max)
    )
    updateSliderInput(session, "slider2", 
                      min = min(ndpoints$z2, na.rm = TRUE),
                      max = max(ndpoints$z2, na.rm = TRUE),
                      value = c(min,max)
    )
    updateSliderInput(session, "slider3", 
                      min = min(ndpoints$z3, na.rm = TRUE),
                      max = max(ndpoints$z3, na.rm = TRUE),
                      value = c(min,max)
    )
    
    # render list of points
    output$tableFiltered <- DT::renderDataTable({
      filtered_points <- ndpoints[which(ndpoints$z1 >= input$slider1[1]
                                        & ndpoints$z1 <= input$slider1[2]
                                        & ndpoints$z2 >= input$slider2[1]
                                        & ndpoints$z2 <= input$slider2[2]
                                        & ndpoints$z3 >= input$slider3[1]
                                        & ndpoints$z3 <= input$slider3[2]),]
    })
    
    
    # render scatter plot1
    output$plot1 <- renderPlotly({
      filtered_points <- ndpoints[which(ndpoints$z1 >= input$slider1[1]
                                        & ndpoints$z1 <= input$slider1[2]
                                        & ndpoints$z2 >= input$slider2[1]
                                        & ndpoints$z2 <= input$slider2[2]
                                        & ndpoints$z3 >= input$slider3[1]
                                        & ndpoints$z3 <= input$slider3[2]),]
      s = input$tableFiltered_rows_selected
      selected_points <- filtered_points[s,]
      if(NROW(input$scatterPlotSelect1) < 2 | NROW(input$scatterPlotSelect1) > 3  )
        return (NULL)
      else if(NROW(input$scatterPlotSelect1) ==2){
        if((input$scatterPlotSelect1[1]=="z1" & input$scatterPlotSelect1[2]=="z2")|
           (input$scatterPlotSelect1[1]=="z2" & input$scatterPlotSelect1[2]=="z1")){
          p <- plot_ly(filtered_points, x = ~z1, y = ~z2, color = ~z3) %>%
            add_markers() %>%
            layout(scene = list(xaxis = list(title = 'z1'),
                                yaxis = list(title = 'z2')))
          return (p)
        }
        if((input$scatterPlotSelect1[1]=="z1" & input$scatterPlotSelect1[2]=="z3")|
           (input$scatterPlotSelect1[1]=="z3" & input$scatterPlotSelect1[2]=="z1")){
          p <- plot_ly(filtered_points, x = ~z1, y = ~z3, color = ~z2) %>%
            add_markers() %>%
            layout(scene = list(xaxis = list(title = 'z1'),
                                yaxis = list(title = 'z3')))
          return (p)
        }
        if((input$scatterPlotSelect1[1]=="z2" & input$scatterPlotSelect1[2]=="z3")|
           (input$scatterPlotSelect1[1]=="z3" & input$scatterPlotSelect1[2]=="z2")){
          p <- plot_ly(filtered_points, x = ~z2, y = ~z3, color = ~z1) %>%
            add_markers() %>%
            layout(scene = list(xaxis = list(title = 'z2'),
                                yaxis = list(title = 'z3')))
          return (p)
        }
      } 
      else {
        p <- plot_ly(filtered_points, x = ~z1, y = ~z2, z = ~z3) %>%
          add_markers() %>%
          layout(scene = list(xaxis = list(title = 'z1'),
                              yaxis = list(title = 'z2'),
                              zaxis = list(title = 'z3')))
        return (p)
      }
    })
    
    # render scatter plot11
    output$plot11 <- renderPlotly({
      filtered_points <- ndpoints[which(ndpoints$z1 >= input$slider1[1]
                                        & ndpoints$z1 <= input$slider1[2]
                                        & ndpoints$z2 >= input$slider2[1]
                                        & ndpoints$z2 <= input$slider2[2]
                                        & ndpoints$z3 >= input$slider3[1]
                                        & ndpoints$z3 <= input$slider3[2]),]
      s = input$tableFiltered_rows_selected
      selected_points <- filtered_points[s,]
      if(NROW(input$scatterPlotSelect1) < 2 | NROW(input$scatterPlotSelect1) > 3  )
        return (NULL)
      else if(NROW(input$scatterPlotSelect1) ==2){
        if((input$scatterPlotSelect1[1]=="z1" & input$scatterPlotSelect1[2]=="z2")|
           (input$scatterPlotSelect1[1]=="z2" & input$scatterPlotSelect1[2]=="z1")){
          p <- plot_ly(selected_points, x = ~z1, y = ~z2) %>%
            add_markers() %>%
            layout(scene = list(xaxis = list(title = 'z1'),
                                yaxis = list(title = 'z2')))
          return (p)
        }
        if((input$scatterPlotSelect1[1]=="z1" & input$scatterPlotSelect1[2]=="z3")|
           (input$scatterPlotSelect1[1]=="z3" & input$scatterPlotSelect1[2]=="z1")){
          p <- plot_ly(selected_points, x = ~z1, y = ~z3) %>%
            add_markers() %>%
            layout(scene = list(xaxis = list(title = 'z1'),
                                yaxis = list(title = 'z3')))
          return (p)
        }
        if((input$scatterPlotSelect1[1]=="z2" & input$scatterPlotSelect1[2]=="z3")|
           (input$scatterPlotSelect1[1]=="z3" & input$scatterPlotSelect1[2]=="z2")){
          p <- plot_ly(selected_points, x = ~z2, y = ~z3) %>%
            add_markers() %>%
            layout(scene = list(xaxis = list(title = 'z2'),
                                yaxis = list(title = 'z3')))
          return (p)
        }
      } 
      else {
        p <- plot_ly(selected_points, x = ~z1, y = ~z2, z = ~z3) %>%
          add_markers() %>%
          layout(scene = list(xaxis = list(title = 'z1'),
                              yaxis = list(title = 'z2'),
                              zaxis = list(title = 'z3')))
        return (p)
      }
    })
    
    # render parallel coordinates plot2
    output$plot2 <- renderPlotly({
      filtered_points <- ndpoints[which(ndpoints$z1 >= input$slider1[1]
                                        & ndpoints$z1 <= input$slider1[2]
                                        & ndpoints$z2 >= input$slider2[1]
                                        & ndpoints$z2 <= input$slider2[2]
                                        & ndpoints$z3 >= input$slider3[1]
                                        & ndpoints$z3 <= input$slider3[2]),]
      s = input$tableFiltered_rows_selected
      selected_points <- filtered_points[s,]
      p <- plot_ly(type = 'parcoords', line = list(color = 'light-blue'),
                   dimensions = list(
                     list(range = c(input$slider1[1],input$slider1[2]),
                          label = 'z1', values = filtered_points$z1),
                     list(range = c(input$slider2[1],input$slider2[2]),
                          label = 'z2', values = filtered_points$z2),
                     list(range = c(input$slider3[1],input$slider3[2]),
                          label = 'z3', values = filtered_points$z3)
                   )
      )
      return (p)
    })
    
    # render parallel coordinates plot21
    output$plot21 <- renderPlotly({
      filtered_points <- ndpoints[which(ndpoints$z1 >= input$slider1[1]
                                        & ndpoints$z1 <= input$slider1[2]
                                        & ndpoints$z2 >= input$slider2[1]
                                        & ndpoints$z2 <= input$slider2[2]
                                        & ndpoints$z3 >= input$slider3[1]
                                        & ndpoints$z3 <= input$slider3[2]),]
      s = input$tableFiltered_rows_selected
      selected_points <- filtered_points[s,]
      p <- plot_ly(type = 'parcoords', line = list(color = 'navy'),
                   dimensions = list(
                     list(range = c(input$slider1[1],input$slider1[2]),
                          label = 'z1', values = selected_points$z1),
                     list(range = c(input$slider2[1],input$slider2[2]),
                          label = 'z2', values = selected_points$z2),
                     list(range = c(input$slider3[1],input$slider3[2]),
                          label = 'z3', values = selected_points$z3)
                   )
      )
      return (p)
    })
    
    return (ndpoints)
  })
  
}

shinyApp(ui,server)