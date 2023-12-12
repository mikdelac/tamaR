# app.R
library(shiny)
library(tamaR)



# Define Server logic
#server <- function(input, output, session) {
  
  # Instantiate an object of Tama class (prepares a tamagotchi)
  guizmo = Tama()

  # Launch the real-time emulation
  guizmo$run()

  data(p2)
#  guizmo$display()

 
  # Launch the Shiny GUI
  guizmo$shiny(p2)


# Run the application 
#shinyApp(ui = ui, server = server)
