fluidPage(
  theme = shinytheme("united"),
  titlePanel("Aplikacja do obsługi bazy danych kina"),
  tabsetPanel(
    tabPanel("Klient",
             tabsetPanel(
               tabPanel("Repertuar",
                        sidebarLayout(
                          sidebarPanel(
                            dateRangeInput("data_kl", label = h3("Repertuar z okresu:"), language = 'pl'),
                            timeInput(inputId = "godzina_kl", label = "Seanse od godziny:",  value = Sys.time()),
                            actionButton(inputId = "wyszukaj", label = "Wyszukaj")
                          ),
                          mainPanel(
                            tags$h3("Repertuar:"),
                            DT::dataTableOutput(outputId = "repertuar_tbl_kl")
                          )
                        )),
               tabPanel("Informacje o filmach",
                        sidebarLayout(
                          sidebarPanel(
                            uiOutput("filmklSelector")
                          ),
                          mainPanel(
                            tags$h3("Dostępne informacje o filmach:"),
                            DT::dataTableOutput(outputId = "film_tbl_kl")
                          )
                        )),
               tabPanel("Zarezerwuj miejsce",
                        sidebarLayout(
                          sidebarPanel(
                            textInput(inputId = "imie_kl", label = "Wpisz imię"),
                            textInput(inputId = "nazwisko_kl", label = "Wpisz nazwisko"),
                            textInput(inputId = "email_kl", label = "Wpisz e-mail"),
                            uiOutput("reprezklSelector"),
                            selectInput(inputId = "ulga_kl", label = "Wybierz bilet", choices = list("normalny"= FALSE,"ulgowy"=TRUE)),
                            actionButton(inputId = "dalej", label = "Dalej"),
                            uiOutput("miejscaklSelector"),
                            uiOutput("rezerwujButton")
                            ),
                          mainPanel(
                            tags$h3("Historia twoich rezerwacji:"),
                            DT::dataTableOutput(outputId = "wszystkierez")
                          )
                        ))
             )),
    tabPanel("Pracownik",
             tabsetPanel(
               tabPanel("Sale kinowe",
                        sidebarLayout(
                          sidebarPanel(
                            useShinyalert(),
                            shinyjs::useShinyjs(),
                            tags$h3("Dodawanie sali:"),
                            textInput(inputId = "sala_nazwa", label = "Wpisz nazwę sali"),
                            numericInput(inputId = "rzedy_ilosc", label = "Podaj liczbę rzędów", value = 0, min = 1),
                            numericInput(inputId = "kolumny_ilosc", label = "Podaj liczbę kolumn", value = 0, min = 1),
                            actionButton(inputId = "sala_dodaj", label = "Dodaj salę"),
                            
                            tags$h3("Usuwanie sali:"),
                            uiOutput("saleSelector"),
                            actionButton(inputId = "sala_usun", label = "Usuń salę")
                          ),
                          mainPanel(
                            tags$h3("Sale w kinie:"),
                            DT::dataTableOutput(outputId = "sale_tbl"),
                            tags$h3("Miejsca w salach kinowych:"),
                            DT::dataTableOutput(outputId = "miejsca_w_salach_tbl")
                          )
                        )),
               tabPanel("Informacje ogólne",
                        sidebarLayout(
                          sidebarPanel(
                            tags$h3("Dodawanie i usuwanie gatunków:"),
                            textInput(inputId = "gatunek_nazwa", label = "Wpisz nazwę gatunku filmowego"),
                            actionButton(inputId = "gatunek_dodaj", label = "Dodaj"),
                            uiOutput("gatunkiSelector"),
                            actionButton(inputId = "gatunek_usun", label = "Usuń"),
                            
                            tags$h3("Dodawanie i usuwanie kategorii wiekowych:"),
                            textInput(inputId = "kategoria_nazwa", label = "Wpisz kategorie wiekową"),
                            actionButton(inputId = "kategoria_dodaj", label = "Dodaj"),
                            uiOutput("kategorieSelector"),
                            actionButton(inputId = "kategoria_usun", label = "Usuń"),
                            
                            tags$h3("Dodawanie i usuwanie rodzajów seansów:"),
                            textInput(inputId = "rodzaj_nazwa", label = "Wpisz rodzaj seansu"),
                            actionButton(inputId = "rodzaj_dodaj", label = "Dodaj"),
                            uiOutput("rodzajeSelector"),
                            actionButton(inputId = "rodzaj_usun", label = "Usuń"),
                            
                            tags$h3("Dodawanie i usuwanie biletów:"),
                            uiOutput("rodzajebilSelector"),
                            selectInput(inputId = "ulga", label = "Wybierz rodzaj biletu", choices = list("normalny" = FALSE,"ulgowy" = TRUE)),
                            numericInput(inputId = "cena", label = "Ustal cenę biletu", min = 0.01 ,value = 0.01),
                            actionButton(inputId = "bilet_dodaj", label = "Dodaj"),
                            uiOutput("biletySelector"),
                            actionButton(inputId = "bilet_usun", label = "Usuń"),
                            
                            tags$h3("Dodawanie i usuwanie wersji językowych:"),
                            textInput(inputId = "jezyk_nazwa", label = "Podaj język"),
                            checkboxInput(inputId = "napisy", label = "napisy", value = FALSE),
                            checkboxInput(inputId = "lektor", label = "lektor", value = FALSE),
                            checkboxInput(inputId = "dubbing", label = "dubbing", value = FALSE),
                            actionButton(inputId = "jezyk_dodaj", label = "Dodaj"),
                            uiOutput("jezykiSelector"),
                            actionButton(inputId = "jezyk_usun", label = "Usuń")
                          ),
                          mainPanel(
                            tags$h3("Gatunki filmowe:"),
                            DT::dataTableOutput(outputId = "gatunki_tbl"),
                            tags$h3("Kategorie wiekowe:"),
                            DT::dataTableOutput(outputId = "kategorie_tbl"),
                            tags$h3("Rodzaje seansów:"),
                            DT::dataTableOutput(outputId = "rodzaje_tbl"),
                            tags$h3("Bilety:"),
                            DT::dataTableOutput(outputId = "bilety_tbl"),
                            tags$h3("Wersje językowe:"),
                            DT::dataTableOutput(outputId = "jezyki_tbl")
                          )
                        )),
               tabPanel("Filmy",
                        sidebarLayout(
                          sidebarPanel(
                            tags$h3("Dodawanie filmu:"),
                            textInput(inputId = "tytul", label = "Podaj tytuł filmu"),
                            uiOutput("gatunekfilmSelector"),
                            textInput(inputId = "rezyser", label = "Reżyser"),
                            textInput(inputId = "produkcja", label = "Kraj produkcji"),
                            dateInput(inputId = "data", label = "Data premiery", value ="2021-01-01"),
                            numericInput(inputId = "czas_trwania", label = "Czas trwania filmu", value = 1),
                            uiOutput("kategoriafilmSelector"),
                            actionButton(inputId = "film_dodaj", label = "Dodaj"),
                            
                            tags$h3("Usuwanie filmu:"),
                            uiOutput("filmSelector"),
                            actionButton(inputId = "film_usun", label = "Usuń")
                          ),
                          mainPanel(
                            tags$h3("Filmy:"),
                            DT::dataTableOutput(outputId = "filmy_tbl")
                          )
                        )),
               tabPanel("Modyfikacja repertuaru",
                        sidebarLayout(
                          sidebarPanel(
                            tags$h3("Dodawanie seansu:"),
                            uiOutput("filmrepSelector"),
                            dateInput(inputId = "datarep", label = "Wybierz termin seansu", value = Sys.Date(), language = 'pl'),
                            timeInput(inputId = "godzinarep", label = "Wybierz godzinę rozpoczęcia seansu",value = Sys.time()),
                            uiOutput("jezykrepSelector"),
                            uiOutput("rodzajrepSelector"),
                            uiOutput("salarepSelector"),
                            actionButton(inputId = "repertuar_dodaj", label = "Dodaj"),
                            
                            tags$h3("Usuwanie seansu:"),
                            uiOutput("repertuarSelector"),
                            actionButton(inputId = "repertuar_usun", label = "Usuń")
                            
                          ),
                          mainPanel(
                            tags$h3("Repertuar:"),
                            DT::dataTableOutput(outputId = "repertuar_tbl"))
                        )),
               tabPanel("Klienci",
                        sidebarLayout(
                          sidebarPanel(
                            tags$h3("Usuwanie klienta:"),
                            uiOutput("klientSelector"),
                            actionButton(inputId = "klient_usun", label = "Usuń")
                          ),
                          mainPanel(
                            tags$h3("Wszyscy klienci kina:"),
                            DT::dataTableOutput(outputId = "klienci_tbl"))
                        )),
               tabPanel("Rezerwacje",
                        sidebarLayout(
                          sidebarPanel(
                            tags$h3("Usuwanie rezerwacji:"),
                            uiOutput("rezerwacjeSelector"),
                            actionButton(inputId = "rezerwacja_usun", label = "Usuń")
                          ),
                          mainPanel(
                            DT::dataTableOutput(outputId = "rezerwacje_tbl"))
                        ))
             ))
  )
)