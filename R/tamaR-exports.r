#' Instanciate a Tama object
#' 
#' @name Tama
#' @return
#' An object of class Tama
#' 
#' @examples
#' guizmo = Tama()
#' guizmo$run()
#' guizmo$save("egg.txt")
#' guizmo$display()
#' guizmo$click("B"); Sys.sleep(3)
#' for(i in 1:7) {guizmo$click("A"); Sys.sleep(.25)}
#' guizmo$click("C"); Sys.sleep(3)
#' Sys.sleep(300)
#' guizmo$display()
#' guizmo$save("babytchi.txt")
#' 
#' @export Tama
#' @exportClass Tama
#' 
#' 

bg = readPNG("img/background.png")
icons = list()
for(ics in c("attention","bathroom","food","game",
             "lights","medicine","status","training")){
    icons[[ics]] = readPNG(paste0("img/",ics,".png"))
}

setRcppClass(Class = "Tama",
             CppClass = "Tama",
             module = "Tamalib",
             methods = list(

    display = function(background = NULL) {
        if(is.null(background)) background = bg
        tmp = .self$GetMatrix()
        ics = .self$GetIcon()

        main = array(0,dim = c(16,32,4))
        for(i in 1:3) main[,,i] = 1-tmp
        main[,,4] = tmp

        plot(c(0,32),c(0,32),type="n",axes=F,xlab="",ylab="",asp=1)
        rasterImage(background,-1, -1, 33, 33)
        rasterImage(main,0,8,32,24,interpolate = F)
        if(ics[1]) rasterImage(icons$food     ,  2,26.25, 6,29.75)
        if(ics[2]) rasterImage(icons$lights   , 10,26.25,14,29.75)
        if(ics[3]) rasterImage(icons$game     , 18,26.25,22,29.75)
        if(ics[4]) rasterImage(icons$medicine , 26,26.5 ,30,29.75)
        if(ics[5]) rasterImage(icons$bathroom ,  2, 2.5 , 6, 5.5 )
        if(ics[6]) rasterImage(icons$status   , 10, 2.5 ,14, 5.25)
        if(ics[7]) rasterImage(icons$training , 18, 2.5 ,22, 5.5 )
        if(ics[8]) rasterImage(icons$attention, 26, 2.5,30,  5   )

    },

    click = function(button = c("A","B","C"),delay = .25){

        stopifnot(all(button %in% c("A","B","C")))
        stopifnot(delay > 0)

        for(b in button){
            .self$SetButton(c(A = 0, B = 1, C = 2)[b],T)
        }
        Sys.sleep(delay)
        for(b in button){
            .self$SetButton(c(A = 0, B = 1, C = 2)[b],F)
        }
    },

    save = function(file){
        state = .self$GetCPU()
        state = as.character(as.hexmode(state))
        cat(c(state,"\n"),file = file, append = F)
    },

    load = function(file){
        state = readLines(file)
        state = unlist(strsplit(state,split=" ", fixed=T))
        state = as.numeric(as.hexmode(state))
        .self$SetCPU(state)
    },

shiny = function(background = NULL, port = 1996){

    options(shiny.port = port)

    ui = pageWithSidebar(
        headerPanel("Tamagotchi Emulator"),
        mainPanel(
	  fluidRow(
	        # Chat room elements
                textInput("chatName", "Enter your name:")	    
	  ),
	  fluidRow(
            splitLayout(
                actionButton("A"," "),
                actionButton("B"," "),
                actionButton("C"," "),
           )
	  ),
	  fluidRow(
               textInput("chatMessage", "Enter a message:"),
                actionButton("sendChat", "Send"),
                tags$hr(),
                tags$h3("Chat Messages:")   	    
	  ),
	  fluidRow(
	        # Add a text area for R code input
                textAreaInput("rcode", "Enter R code to execute", "", height = "100px"),
                actionButton("runCode", "Run Code"),
                tags$hr(),
                tags$h3("R Code Execution Output:") 
	  )
	),
        sidebarPanel(
            plotOutput("screen"),
            # Add an output element for R code execution results
            verbatimTextOutput("rcodeOutput"),
            # Chat messages displayed in the main panel
            htmlOutput("chatText"),
	    width = 3
        )
     )

    server = function(input, output, session){
        autoInvalidate <- reactiveTimer(1000/6, session)

        # Default chat output
        chatText <- reactiveVal("Welcome to the Tamagotchi Chat!")

	# Buttons
        observeEvent(input$A,.self$click("A"))
        observeEvent(input$B,.self$click("B"))
        observeEvent(input$C,.self$click("C"))

        output$screen = renderPlot({
            autoInvalidate()
            .self$display(background = background)
        })

        # Placeholder for R code execution results
        outputCode <- reactiveVal("")

	    # Observe sending chat message
    observeEvent(input$sendChat, {
        newChatMessage <- paste0(chatText(),
            sprintf("<p><strong>%s:</strong> %s</p>", input$chatName, input$chatMessage))
        chatText(newChatMessage)
    })

    # Render chat text output
    output$chatText <- renderUI({
        HTML(chatText())
    })

observeEvent(input$runCode, {
    tryCatch({
        # Evaluate the user code in a local environment
        result <- eval(parse(text = input$rcode), envir = new.env())
        outputCode(paste("Result:", result))
    }, warning = function(w) {
        # Handle warnings separately if desired
        outputCode(paste("Warning:", w$message))
    }, error = function(e) {
        # Handle errors
        outputCode(paste("Error:", e$message))
    }, finally = {
        # Optional to implement; code here executes regardless of errors or warnings
    })
})

        output$rcodeOutput <- renderText({
            outputCode()
        })

    }
    shinyApp(ui, server)
}

))
