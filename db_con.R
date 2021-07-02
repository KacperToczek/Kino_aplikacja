# install.packages('RPostgres')
library(RPostgres)
library(config)
library(odbc)


con <- dbConnect(RPostgres::Postgres(), dbname = 'postgres', host = 'localhost', port = 5432, user = 'postgres')

