source("db_con.R")
library(shiny)
library(shinyTime)
library(shinyalert)
library(shinyjs)
library(DT)

function(input, output){
  #1000 milliseconds * 60 seconds * 60 minutes * 4 hours
  shinyjs::runjs("function reload_page() { window.location.reload(); setTimeout(reload_page, 180000);}
                  setTimeout(reload_page, 180000);") 
    
  # panel repertuar dla klienta
  
  output$repertuar_tbl_kl <- DT::renderDataTable({
    sql <- paste0('SELECT id_seansu AS "kod seansu", film AS "Tytuł filmu", termin AS "Data", godzina_rozpoczecia AS "Godzina rozpoczęcia",
                  rodzaj AS "Rodzaj seansu", czas_trwania_minuty AS "Czas trwania (minuty)", jezyki.etykieta AS "Język"
                  FROM repertuar INNER JOIN filmy ON repertuar.film = filmy.tytul 
                  INNER JOIN jezyki ON repertuar.jezyk = jezyki.id_jezyka;')
    dbGetQuery(con, sql)
  })
  
  observeEvent(input$wyszukaj, {
    output$repertuar_tbl_kl <- DT::renderDataTable({
      sql <- paste0('SELECT id_seansu AS "kod seansu", film AS "Tytuł filmu", termin AS "Data", godzina_rozpoczecia AS "Godzina rozpoczęcia",
                  rodzaj AS "Rodzaj seansu", czas_trwania_minuty AS "Czas trwania (minuty)", jezyk AS "Język"
                  FROM repertuar INNER JOIN filmy ON repertuar.film = filmy.tytul
                  WHERE repertuar.termin BETWEEN ',"'",input$data_kl[1],"' AND '", input$data_kl[2], "'",
                  "AND repertuar.godzina_rozpoczecia >= '", input$godzina_kl, "';")
    dbGetQuery(con, sql)
    })
  })
  
  # panel informacje o filmach
  
  wektor_gatunkow_kl <- dbGetQuery(con, "SELECT gatunek FROM gatunki;")
  output$filmklSelector <- renderUI({
    selectInput(inputId = "gatunek_kl", label = "Wybierz gatunek", choices = wektor_gatunkow_kl, selected = 1)
  })
  
  output$film_tbl_kl <- DT::renderDataTable({
    sql <- paste0('SELECT tytul AS "Tytuł", gatunek AS "Gatunek", rezyser AS "Reżyser", produkcja AS "Kraj produkcji",
                  premiera AS "Data premiery", czas_trwania_minuty AS "Czas trwania", kategoria_wiekowa AS "Od ilu lat" 
                  FROM filmy WHERE filmy.gatunek =', "'", input$gatunek_kl, "';")
    dbGetQuery(con,sql)
  })
  
  # panel rezerwacja
  
  wektor_rep_rez_kl <- dbGetQuery(con, "SELECT id_seansu FROM repertuar;")
  output$reprezklSelector <- renderUI({
    selectInput(inputId = "rep_rez_kl", label = "Wybierz kod seansu", choices = wektor_rep_rez_kl, selected = 1)
  })
  
  observeEvent(input$dalej,{
    if(nchar(input$imie_kl) > 30){
      shinyalert("Błąd!!!", "Imię jest za długie, możliwe max 30 znaków.", type = "error")
    }
    else if(nchar(input$nazwisko_kl) > 30){
      shinyalert("Błąd!!!", "Nazwisko jest za długie, możliwe max 30 znaków.", type = "error")
    }
    else if(nchar(input$email_kl) > 30){
      shinyalert("Błąd!!!", "E-mail jest za długi, możliwe max 30 znaków.", type = "error")
    }
    else if(grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(input$email_kl), ignore.case=TRUE) == FALSE){
      shinyalert("Błąd!!!", "E-mail jest błędny.", type = "error")
    }
    else{
      wektor_miejsc_rez_kl <- dbGetQuery(con, paste0("SELECT id_miejsca FROM miejsca_w_salach WHERE sala = 
                                                   ( SELECT sala FROM repertuar WHERE id_seansu =", input$rep_rez_kl,")
                                                   EXCEPT 
                                                   SELECT miejsce FROM rezerwacje WHERE seans =", input$rep_rez_kl,"ORDER BY id_miejsca DESC;"))
      
      output$miejscaklSelector <- renderUI({
        selectInput(inputId = "miejsce_kl", label = "Wybierz miejsce w sali", choices = wektor_miejsc_rez_kl, selected = 1)
      })
      output$rezerwujButton <- renderUI({
        actionButton(inputId = "rezerwuj_kl", label = "Rezerwuj")
      })
    }
  })
  
  observeEvent(input$rezerwuj_kl,{
    wektor_klienci <- dbGetQuery(con, "SELECT email FROM klienci")
    if(is.element(input$email_kl, wektor_klienci$email) == FALSE)
    {
      sql <- paste0("INSERT INTO klienci VALUES('", input$imie_kl, "','", input$nazwisko_kl, "','", input$email_kl, "');")
      dbSendQuery(con,sql)
    }
    
    idbiletu <- dbGetQuery(con, paste0("SELECT id_biletu FROM bilety WHERE rodzaj = 
                                       (SELECT rodzaj FROM repertuar WHERE id_seansu =",input$rep_rez_kl,") AND
                                       czy_ulgowy =", input$ulga_kl,";"))
    
    sql <- paste0("INSERT INTO rezerwacje(klient, seans, miejsce, bilet) VALUES('", input$email_kl, "','",
                  input$rep_rez_kl, "','", input$miejsce_kl, "',",idbiletu,");" )
    
    tryCatch(
      expr = {
        dbSendQuery(con, sql)
      },
      error = function(e){
        shinyalert("Błąd!!", "Naciśnij ponownie przycisk 'Dalej'.", type="error")
      }
    )

    output$wszystkierez <- DT::renderDataTable({
      dbGetQuery(con,paste0("SELECT id_rezerwacji, klient, film, termin, godzina_rozpoczecia, miejsce, cena FROM rezerwacje INNER JOIN bilety ON rezerwacje.bilet = bilety.id_biletu
                            INNER JOIN repertuar ON rezerwacje.seans = repertuar.id_seansu
                            WHERE klient ='", input$email_kl,"';"))
    })
    
    wektor_klientow <- dbGetQuery(con, "SELECT email FROM klienci;")
    output$klientSelector <- renderUI({
      selectInput(inputId = "klient_do_us", label = "Wybierz klienta do usunięcia", choices = wektor_klientow, selected = 1)
    })
    output$klienci_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM klienci;")
    })
    
    wektor_rezerwacji <-dbGetQuery(con, "SELECT id_rezerwacji FROM rezerwacje;")
    output$rezerwacjeSelector <- renderUI({
      selectInput(inputId = "rezerw_do_us", label = "Wybierz rezerwację do usunięcia", choices = wektor_rezerwacji, selected = 1)
    })
    output$rezerwacje_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM rezerwacje;")
    })
  })
  
  
  
  

  # PRACOWNIK
  
  # panel sale
  
  ## dodaj sale
  
  output$sale_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM sale;")
  })
  
  output$miejsca_w_salach_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM miejsca_w_salach;")
  })
  
  wektor_sal <- dbGetQuery(con, "SELECT sala FROM sale;")
  output$saleSelector <- renderUI({
    selectInput(inputId = "sala_do_us", label = "Wybierz salę", choices = wektor_sal, selected = 1)
  })
  
  observeEvent(input$sala_dodaj, {
    wektor_sal <- dbGetQuery(con, "SELECT sala FROM sale;")
    if(is.element(input$sala_nazwa, wektor_sal$sala)){
      shinyalert("Błąd!!!","Sala o takiej nazwie już istnieje.", type = "error")
    }
    else if(nchar(input$sala_nazwa) > 10){
      shinyalert("Błąd!!!", "Nazwa jest za długa, możliwe max 10 znaków.", type = "error")
    }
    else if(input$rzedy_ilosc <= 0 || input$rzedy_ilosc >20){
      shinyalert("Błąd!!!","Liczba rzędów powinna być większa od 0 i mniejsza niż 20.", type = "error")
    }
    else if(input$kolumny_ilosc <= 0 || input$rzedy_ilosc > 20 ){
      shinyalert("Błąd!!!","Liczba kolumn powinna być większa od 0 i mniejsza niż 20.", type = "error")
    }
    else
    {
      sql <- paste0("INSERT INTO sale VALUES('", input$sala_nazwa, "',", input$rzedy_ilosc, ", ", input$kolumny_ilosc, ");")
      dbSendQuery(con, sql)
      output$sale_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM sale;")
      })
      output$miejsca_w_salach_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM miejsca_w_salach;")
      })
      wektor_sal <- dbGetQuery(con, "SELECT sala FROM sale;")
      output$saleSelector <- renderUI({
        selectInput(inputId = "sala_do_us", label = "Wybierz salę", choices = wektor_sal, selected = 1)
      })
      wektor_salrep <- dbGetQuery(con, "SELECT sala FROM sale;")
      output$salarepSelector <- renderUI({
        selectInput(inputId = "sala_do_rep", label = "Wybierz salę", choices = wektor_salrep, selected = 1)
      })
    }
  })
  
  ## usun sale
  
  observeEvent(input$sala_usun, {
    sql <- paste0("DELETE FROM sale WHERE sala ='", input$sala_do_us, "';")
    dbSendQuery(con, sql)
    output$sale_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM sale;")
    })
    output$miejsca_w_salach_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM miejsca_w_salach;")
    })
    wektor_sal <- dbGetQuery(con, "SELECT sala FROM sale;")
    output$saleSelector <- renderUI({
      selectInput(inputId = "sala_do_us", label = "Wybierz salę", choices = wektor_sal, selected = 1)
    })
    wektor_salrep <- dbGetQuery(con, "SELECT sala FROM sale;")
    output$salarepSelector <- renderUI({
      selectInput(inputId = "sala_do_rep", label = "Wybierz salę", choices = wektor_salrep, selected = 1)
    })
  })
  
  
  # panel modyfikacje gatunki/rodzaje/bilety/kategorie wiekowe
  
  ## dodaj gatunki
  
  output$gatunki_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM gatunki;")
  })
  
  wektor_gatunkow <- dbGetQuery(con, "SELECT * FROM gatunki;")
  output$gatunkiSelector <- renderUI({
    selectInput(inputId = "gatunek_do_us", label = "Wybierz gatunek do usunięcia", choices = wektor_gatunkow, selected = 1)
  })
  
  observeEvent(input$gatunek_dodaj, {
    if(nchar(input$gatunek_nazwa) > 30){
      shinyalert("Błąd!!!", "Nazwa jest za długa, możliwe max 30 znaków.", type = "error")
    }
    else{
      sql <- paste0("INSERT INTO gatunki VALUES ('", input$gatunek_nazwa, "');")
      dbSendQuery(con, sql)
      
      output$gatunki_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM gatunki;")
      })
      wektor_gatunkow <- dbGetQuery(con, "SELECT * FROM gatunki;")
      output$gatunkiSelector <- renderUI({
        selectInput(inputId = "gatunek_do_us", label = "Wybierz gatunek do usunięcia", choices = wektor_gatunkow, selected = 1)
      })
      
      wektor_gatunkow_kl <- dbGetQuery(con, "SELECT gatunek FROM gatunki;")
      output$filmklSelector <- renderUI({
        selectInput(inputId = "gatunek_kl", label = "Wybierz gatunek", choices = wektor_gatunkow_kl, selected = 1)
      })
      
      wektor_gatunkow_film <- dbGetQuery(con, "SELECT * FROM gatunki;")
      output$gatunekfilmSelector <- renderUI({
        selectInput(inputId = "gatunekfilm", label = "Wybierz gatunek", choices = wektor_gatunkow_film)
      })
  
    }
  })
  
  ## usun gatunek
  
  observeEvent(input$gatunek_usun, {
    sql <- paste0("DELETE FROM gatunki WHERE gatunek = '", input$gatunek_do_us, "';")
    dbSendQuery(con, sql)
    output$gatunki_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM gatunki;")
    })
    
    wektor_gatunkow <- dbGetQuery(con, "SELECT * FROM gatunki;")
    output$gatunkiSelector <- renderUI({
      selectInput(inputId = "gatunek_do_us", label = "Wybierz gatunek do usunięcia", choices = wektor_gatunkow, selected = 1)
    })
    
    wektor_gatunkow_kl <- dbGetQuery(con, "SELECT gatunek FROM gatunki;")
    output$filmklSelector <- renderUI({
      selectInput(inputId = "gatunek_kl", label = "Wybierz gatunek", choices = wektor_gatunkow_kl, selected = 1)
    })
    
    wektor_gatunkow_film <- dbGetQuery(con, "SELECT * FROM gatunki;")
    output$gatunekfilmSelector <- renderUI({
      selectInput(inputId = "gatunekfilm", label = "Wybierz gatunek", choices = wektor_gatunkow_film)
    })
    
  })
  
  ## dodaj kategorie
  
  output$kategorie_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
  })
  
  wektor_kategori <- dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
  output$kategorieSelector <- renderUI({
    selectInput(inputId = "kategoria_do_us", label = "Wybierz kategorię do usunięcia", choices = wektor_kategori, selected = 1)
  })
  
  observeEvent(input$kategoria_dodaj, {
    if(nchar(input$kategoria_nazwa) > 10){
      shinyalert("Błąd!!!", "Nazwa jest za długa, możliwe max 10 znaków.", type = "error")
    }
    else{
      sql <- paste0("INSERT INTO kategorie_wiekowe VALUES ('", input$kategoria_nazwa, "');")
      dbSendQuery(con, sql)
      output$kategorie_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
      })
      wektor_kategori <- dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
      output$kategorieSelector <- renderUI({
        selectInput(inputId = "kategoria_do_us", label = "Wybierz kategorię do usunięcia", choices = wektor_kategori, selected = 1)
      })
      
      wektor_kategoria_film <- dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
      output$kategoriafilmSelector<- renderUI({
        selectInput(inputId = "katfilm", label = "Wybierz kategorię wiekową", choices = wektor_kategoria_film)
      })
    }
  })
  
  ## usun kategorie
  
  observeEvent(input$kategoria_usun, {
    sql <- paste0("DELETE FROM kategorie_wiekowe WHERE wiek = '", input$kategoria_do_us, "';")
    dbSendQuery(con, sql)
    output$kategorie_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
    })
    wektor_kategori <- dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
    output$kategorieSelector <- renderUI({
      selectInput(inputId = "kategoria_do_us", label = "Wybierz kategorię do usunięcia", choices = wektor_kategori, selected = 1)
    })
    
    wektor_kategoria_film <- dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
    output$kategoriafilmSelector<- renderUI({
      selectInput(inputId = "katfilm", label = "Wybierz kategorię wiekową", choices = wektor_kategoria_film)
    })
  })
  
  ## dodaj rodzaje
  
  output$rodzaje_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM rodzaje;")
  })
  
  wektor_rodzajow <- dbGetQuery(con, "SELECT * FROM rodzaje;")
  output$rodzajeSelector <- renderUI({
    selectInput(inputId = "rodzaj_do_us", label = "Wybierz rodzaj do usunięcia", choices = wektor_rodzajow, selected = 1)
  })
  
  observeEvent(input$rodzaj_dodaj, {
    if(nchar(input$rodzaj_nazwa) > 30){
      shinyalert("Błąd!!!", "Nazwa jest za długa, możliwe max 30 znaków.", type = "error")
    }
    else{
      sql <- paste0("INSERT INTO rodzaje VALUES ('", input$rodzaj_nazwa, "');")
      dbSendQuery(con, sql)
      output$rodzaje_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM rodzaje;")
      })
      wektor_rodzajow <- dbGetQuery(con, "SELECT * FROM rodzaje;")
      output$rodzajeSelector <- renderUI({
        selectInput(inputId = "rodzaj_do_us", label = "Wybierz rodzaj do usunięcia", choices = wektor_rodzajow, selected = 1)
      })
      
      wektor_rodzajowrep <- dbGetQuery(con, "SELECT * FROM rodzaje;")
      output$rodzajrepSelector <- renderUI({
        selectInput(inputId = "rodzaj_do_rep", label = "Wybierz rodzaj", choices = wektor_rodzajowrep, selected = 1)
      })
    }
  })
  
  ## usun rodzaj
  
  observeEvent(input$rodzaj_usun, {
    sql <- paste0("DELETE FROM rodzaje WHERE rodzaj = '", input$rodzaj_do_us, "';")
    dbSendQuery(con, sql)
    output$rodzaje_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM rodzaje;")
    })
    wektor_rodzajow <- dbGetQuery(con, "SELECT * FROM rodzaje;")
    output$rodzajeSelector <- renderUI({
      selectInput(inputId = "rodzaj_do_us", label = "Wybierz rodzaj do usunięcia", choices = wektor_rodzajow, selected = 1)
    })
   
    wektor_rodzajowrep <- dbGetQuery(con, "SELECT * FROM rodzaje;")
    output$rodzajrepSelector <- renderUI({
      selectInput(inputId = "rodzaj_do_rep", label = "Wybierz rodzaj", choices = wektor_rodzajowrep, selected = 1)
    })
  })
  
  ## dodaj bilety
  
  output$bilety_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM bilety;")
  })
  
  wektor_biletow <- dbGetQuery(con, "SELECT id_biletu FROM bilety;")
  output$biletySelector <- renderUI({
    selectInput(inputId = "bilet_do_us", label = "Wybierz bilet do usunięcia", choices = wektor_biletow, selected = 1)
  })
  
  output$rodzajebilSelector <- renderUI({
    selectInput(inputId = "rodzaj_bil", label = "Wybierz rodzaj seansu", choices = wektor_rodzajow, selected = 1)
  })
  
  observeEvent(input$bilet_dodaj,{
    if(input$cena <= 0){
      shinyalert("Błąd!!!", "Cena biletu powinna być większa od 0.", type = "error")
    }
    else{
      sql <- paste0("INSERT INTO bilety(rodzaj, czy_ulgowy, cena) VALUES ('", input$rodzaj_bil, "',", input$ulga, ",", input$cena , ");")
      tryCatch(
        expr = {
          dbSendQuery(con, sql)
        },
        error = function(e){
          shinyalert("Błąd!!", "Taki bilet już istnieje.", type="error")
        }
      )
      output$bilety_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM bilety;")
      })
      wektor_biletow <- dbGetQuery(con, "SELECT id_biletu FROM bilety;")
      output$biletySelector <- renderUI({
        selectInput(inputId = "bilet_do_us", label = "Wybierz bilet do usunięcia", choices = wektor_biletow, selected = 1)
      })}
  })
  
  ## usun bilet
  
  observeEvent(input$bilet_usun,{
    sql <- paste0("DELETE FROM bilety WHERE id_biletu = '", input$bilet_do_us, "';")
    dbSendQuery(con, sql)
    output$bilety_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM bilety;")
    })
    wektor_biletow <- dbGetQuery(con, "SELECT id_biletu FROM bilety;")
    output$biletySelector <- renderUI({
      selectInput(inputId = "bilet_do_us", label = "Wybierz bilet do usunięcia", choices = wektor_biletow, selected = 1)
    })
  })
    
  ## dodaj jezyk
  
  output$jezyki_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM jezyki;")
  })
  
  wektor_jezykow <- dbGetQuery(con, "SELECT id_jezyka FROM jezyki;")
  output$jezykiSelector <- renderUI({
    selectInput(inputId = "jezyk_do_us", label = "Wybierz język do usunięcia", choices = wektor_jezykow, selected = 1)
  })
  
  wektor_jezykow_all <- dbGetQuery(con, "SELECT jezyk, czy_napisy, czy_lektor, czy_dubbing FROM jezyki;")
  
  observeEvent(input$jezyk_dodaj,{
    if(nchar(input$jezyk_nazwa) > 10){
      shinyalert("Błąd!!!", "Nazwa jest za długa, możliwe max 10 znaków.", type = "error")
    }
    else{
      sql <- paste0("INSERT INTO jezyki(jezyk, czy_napisy, czy_lektor, czy_dubbing) VALUES('",
                    input$jezyk_nazwa, "',", input$napisy, ",", input$lektor, ",", input$dubbing, ");" )
      tryCatch(
        expr = {
          dbSendQuery(con, sql)
        },
        error = function(e){
          shinyalert("Błąd!!", "Taka wersja językowa jest już dostępna.", type="error")
        }
      )      
      output$jezyki_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM jezyki;")
      })
      wektor_jezykow <- dbGetQuery(con, "SELECT id_jezyka FROM jezyki;")
      output$jezykiSelector <- renderUI({
        selectInput(inputId = "jezyk_do_us", label = "Wybierz język do usunięcia", choices = wektor_jezykow, selected = 1)
      })
      
      wektor_jezykowrep <- dbGetQuery(con, "SELECT id_jezyka FROM jezyki;")
      output$jezykrepSelector <- renderUI({
        selectInput(inputId = "jezyk_do_rep", label = "Wybierz język", choices = wektor_jezykowrep, selected = 1)
      })
      
    }
  })
  
  ## usun jezyk
  
  observeEvent(input$jezyk_usun,{
    sql <- paste0("DELETE FROM jezyki WHERE id_jezyka = '", input$jezyk_do_us, "';")
    dbSendQuery(con, sql)
    output$jezyki_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM jezyki;")
    })
    wektor_jezykow <- dbGetQuery(con, "SELECT id_jezyka FROM jezyki;")
    output$jezykiSelector <- renderUI({
      selectInput(inputId = "jezyk_do_us", label = "Wybierz język do usunięcia", choices = wektor_jezykow, selected = 1)
    })
    wektor_jezykowrep <- dbGetQuery(con, "SELECT id_jezyka FROM jezyki;")
    output$jezykrepSelector <- renderUI({
      selectInput(inputId = "jezyk_do_rep", label = "Wybierz język", choices = wektor_jezykowrep, selected = 1)
    })
    
  })
  
  # panel filmy
  
  output$filmy_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM filmy;")
  })
  
  wektor_filmow <- dbGetQuery(con, "SELECT tytul FROM filmy;")
  output$filmSelector <- renderUI({
    selectInput(inputId = "film_do_us", label = "Wybierz film do usunięcia", choices = wektor_filmow )
  })

  wektor_gatunkow_film <- dbGetQuery(con, "SELECT * FROM gatunki;")
  output$gatunekfilmSelector <- renderUI({
    selectInput(inputId = "gatunekfilm", label = "Wybierz gatunek", choices = wektor_gatunkow_film)
  })
  
  wektor_kategoria_film <- dbGetQuery(con, "SELECT * FROM kategorie_wiekowe;")
  output$kategoriafilmSelector<- renderUI({
    selectInput(inputId = "katfilm", label = "Wybierz kategorię wiekową", choices = wektor_kategoria_film)
  })
  
  observeEvent(input$film_dodaj, {
    if(nchar(input$tytul) > 40){
      shinyalert("Błąd!!!", "Tytuł jest za długi, możliwe max 40 znaków.", type = "error")
    }
    else if(nchar(input$rezyser) > 30){
      shinyalert("Błąd!!!", "Nazwa reżysera jest za długa, możliwe max 30 znaków.", type = "error")
    }
    else if(nchar(input$produkcja) > 30){
      shinyalert("Błąd!!!", "Nazwa kraju produkcji jest za długa, możliwe max 30 znaków.", type = "error")
    }
    else if(input$czas_trwania <= 0){
      shinyalert("Błąd!!!", "Czas trwania filmu powinien być większy od 0", type = "error")
    }
    else{
      sql <- paste0("INSERT INTO filmy VALUES('", input$tytul, "','", input$gatunekfilm , "','", input$rezyser, "','",
                    input$produkcja, "','", input$data, "',", input$czas_trwania, ",'", input$katfilm, "');")
      dbSendQuery(con, sql)
      output$filmy_tbl <- DT::renderDataTable({
        dbGetQuery(con, "SELECT * FROM filmy;")
      })
      wektor_filmow <- dbGetQuery(con, "SELECT tytul FROM filmy;")
      output$filmSelector <- renderUI({
        selectInput(inputId = "film_do_us", label = "Wybierz film do usunięcia", choices = wektor_filmow )
      })
      
      wektor_filmowrep <- dbGetQuery(con, "SELECT tytul FROM filmy;")
      output$filmrepSelector <- renderUI({
        selectInput(inputId = "film_do_rep", label = "Wybierz film", choices = wektor_filmowrep )
      })
      }
  })
  
  observeEvent(input$film_usun, {
    sql <- paste0("DELETE FROM filmy WHERE tytul = '", input$film_do_us, "';")
    dbSendQuery(con, sql)
    output$filmy_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM filmy;")
    })
    wektor_filmow <- dbGetQuery(con, "SELECT tytul FROM filmy;")
    output$filmSelector <- renderUI({
      selectInput(inputId = "film_do_us", label = "Wybierz film do usunięcia", choices = wektor_filmow )
    })
    
    wektor_filmowrep <- dbGetQuery(con, "SELECT tytul FROM filmy;")
    output$filmrepSelector <- renderUI({
      selectInput(inputId = "film_do_rep", label = "Wybierz film", choices = wektor_filmowrep )
    })
  })
  
  
  # panel repertuar
  
  output$repertuar_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM repertuar;")
  })
  
  wektor_repertuar <- dbGetQuery(con, "SELECT id_seansu FROM repertuar;")
  output$repertuarSelector <- renderUI({
    selectInput(inputId = "rep_do_us", label = "Wybierz seans do usunięcia", choices = wektor_repertuar)
  })
  
  wektor_filmowrep <- dbGetQuery(con, "SELECT tytul FROM filmy;")
  output$filmrepSelector <- renderUI({
    selectInput(inputId = "film_do_rep", label = "Wybierz film", choices = wektor_filmowrep )
  })
  
  wektor_jezykowrep <- dbGetQuery(con, "SELECT etykieta FROM jezyki;")
  output$jezykrepSelector <- renderUI({
    selectInput(inputId = "jezyk_do_rep", label = "Wybierz język", choices = wektor_jezykowrep, selected = 1)
  })
  
  wektor_rodzajowrep <- dbGetQuery(con, "SELECT * FROM rodzaje;")
  output$rodzajrepSelector <- renderUI({
    selectInput(inputId = "rodzaj_do_rep", label = "Wybierz rodzaj", choices = wektor_rodzajowrep, selected = 1)
  })
  
  wektor_salrep <- dbGetQuery(con, "SELECT sala FROM sale;")
  output$salarepSelector <- renderUI({
    selectInput(inputId = "sala_do_rep", label = "Wybierz salę", choices = wektor_salrep, selected = 1)
  })
  
  observeEvent(input$repertuar_dodaj, {
    jezyk_do_repertuaru <- dbGetQuery(con, paste0("SELECT id_jezyka FROM jezyki WHERE etykieta='",input$jezyk_do_rep,"';"))
    sql <- paste0("INSERT INTO repertuar(film, termin, godzina_rozpoczecia, jezyk, rodzaj, sala) VALUES('",
                  input$film_do_rep, "','", input$datarep, "','", input$godzinarep, "',", as.integer(jezyk_do_repertuaru), ",'",
                  input$rodzaj_do_rep, "','", input$sala_do_rep, "');")
    
    tryCatch(
      expr = {
        dbSendQuery(con, sql)
      },
      error = function(e){
        shinyalert("Błąd!!", "Sala jest w tym czasie zajęta.", type="error")
      }
    )
    
    output$repertuar_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM repertuar;")
    })
    
    wektor_repertuar <- dbGetQuery(con, "SELECT id_seansu FROM repertuar;")
    
    output$repertuarSelector <- renderUI({
      selectInput(inputId = "rep_do_us", label = "Wybierz seans do usunięcia", choices = wektor_repertuar)
    })
    
    output$repertuar_tbl_kl <- DT::renderDataTable({
      sql <- paste0('SELECT id_seansu AS "kod seansu", film AS "Tytuł filmu", termin AS "Data", godzina_rozpoczecia AS "Godzina rozpoczęcia",
                  rodzaj AS "Rodzaj seansu", czas_trwania_minuty AS "Czas trwania (minuty)", jezyk AS "Język"
                  FROM repertuar INNER JOIN filmy ON repertuar.film = filmy.tytul;')
      dbGetQuery(con, sql)
    })
    
    wektor_rep_rez_kl <- dbGetQuery(con, "SELECT id_seansu FROM repertuar;")
    output$reprezklSelector <- renderUI({
      selectInput(inputId = "rep_rez_kl", label = "Wybierz kod seansu", choices = wektor_rep_rez_kl, selected = 1)
    })
  })
  
  observeEvent(input$repertuar_usun, {
    sql <- paste0("DELETE FROM repertuar WHERE id_seansu = ", input$rep_do_us, ";")
    dbSendQuery(con, sql)
    
    output$repertuar_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM repertuar;")
    })
    
    wektor_repertuar <- dbGetQuery(con, "SELECT id_seansu FROM repertuar;")
    
    output$repertuarSelector <- renderUI({
      selectInput(inputId = "rep_do_us", label = "Wybierz seans do usunięcia", choices = wektor_repertuar)
    })
    
    output$repertuar_tbl_kl <- DT::renderDataTable({
      sql <- paste0('SELECT id_seansu AS "kod seansu", film AS "Tytuł filmu", termin AS "Data", godzina_rozpoczecia AS "Godzina rozpoczęcia",
                  rodzaj AS "Rodzaj seansu", czas_trwania_minuty AS "Czas trwania (minuty)", jezyk AS "Język"
                  FROM repertuar INNER JOIN filmy ON repertuar.film = filmy.tytul;')
      dbGetQuery(con, sql)
    })
    
    wektor_rep_rez_kl <- dbGetQuery(con, "SELECT id_seansu FROM repertuar;")
    output$reprezklSelector <- renderUI({
      selectInput(inputId = "rep_rez_kl", label = "Wybierz kod seansu", choices = wektor_rep_rez_kl, selected = 1)
    })
  })
  
  # panel klienci
  
  output$klienci_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM klienci;")
  })
  
  wektor_klientow <- dbGetQuery(con, "SELECT email FROM klienci;")
  output$klientSelector <- renderUI({
    selectInput(inputId = "klient_do_us", label = "Wybierz klienta do usunięcia", choices = wektor_klientow, selected = 1)
  })
  
  observeEvent(input$klient_usun,{
    sql <- paste0("DELETE FROM klienci WHERE email = '", input$klient_do_us, "';")
    dbSendQuery(con, sql)
    
    output$klienci_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM klienci;")
    })
    
    wektor_klientow <- dbGetQuery(con, "SELECT email FROM klienci;")
    output$klientSelector <- renderUI({
      selectInput(inputId = "klient_do_us", label = "Wybierz klienta do usunięcia", choices = wektor_klientow, selected = 1)
    })
    
    output$rezerwacje_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM rezerwacje;")
    })
    
    wektor_rezerwacji <-dbGetQuery(con, "SELECT id_rezerwacji FROM rezerwacje;")
    output$rezerwacjeSelector <- renderUI({
      selectInput(inputId = "rezerw_do_us", label = "Wybierz rezerwację do usunięcia", choices = wektor_rezerwacji, selected = 1)
    })
  })
  
  # panel rezerwacje
  
  output$rezerwacje_tbl <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM rezerwacje;")
  })
  
  wektor_rezerwacji <-dbGetQuery(con, "SELECT id_rezerwacji FROM rezerwacje;")
  output$rezerwacjeSelector <- renderUI({
    selectInput(inputId = "rezerw_do_us", label = "Wybierz rezerwację do usunięcia", choices = wektor_rezerwacji, selected = 1)
  })
  
  observeEvent(input$rezerwacja_usun,{
    sql <- paste0("DELETE FROM rezerwacje WHERE id_rezerwacji =", input$rezerw_do_us, ";")
    dbSendQuery(con, sql)
    
    output$rezerwacje_tbl <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM rezerwacje;")
    })
    
    wektor_rezerwacji <-dbGetQuery(con, "SELECT id_rezerwacji FROM rezerwacje;")
    output$rezerwacjeSelector <- renderUI({
      selectInput(inputId = "rezerw_do_us", label = "Wybierz rezerwację do usunięcia", choices = wektor_rezerwacji, selected = 1)
    })
  })
  
}