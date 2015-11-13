
source("myRsession.R")
source("myRfunctions.R")

## Interpret the explicit NA, the empty string and the word 'unknown' as missing values
## Most (all?) 0s seem to indicate missing values as well
na.strings = c(NA,"","unknown","Unknown")
## There are 40 value columns; it is feasible to specify the class of each column explicitly
colClasses = c("integer","numeric",
							 "Date","character",
							 "numeric","character",
							 "numeric","numeric",
							 "character","integer",
							 "character","character",
							 "character","character",
							 "character","character",
							 "character","numeric",
							 "logical","character",
							 "character","character",
							 "logical","integer",
							 "character","character",
							 "character","character",
							 "character","character",
							 "character","character",
							 "character","character",
							 "character","character",
							 "character","character",
							 "character","character")

train.labels = tbl_dt(fread("data/Training set labels.csv",
                            na.strings = na.strings,
                            colClasses = c("integer","character")))
train.values = tbl_dt(fread("data/Training set values.csv",
                            na.strings = na.strings,
                            colClasses = colClasses))
test.values = tbl_dt(fread("data/Test set values.csv",
                           na.strings = na.strings,
                           colClasses = colClasses))

## For feature engineering, I will transform the train and test sets together
## I combine them into `data`. I add the column `subset`, so that I can split them later on.
train.values$subset = "train"
test.values$subset = "test"
train = inner_join(train.labels, train.values, by = "id")

data = tbl_df(rbind.fill(train,test.values)) %>%
  select( - recorded_by ) %>%
  ## A value of 0 does not make sense for any of the following predictors
	mutate(funder = ifelse(funder == 0, NA, funder)) %>%
  mutate(installer = ifelse(installer == 0, NA, installer)) %>%
  mutate(gps_height = ifelse(gps_height == 0, NA, gps_height)) %>%
  mutate(population = ifelse(population == 0, NA, population)) %>%
  mutate(amount_tsh = ifelse(amount_tsh == 0, NA, amount_tsh)) %>%
	mutate(construction_year = ifelse(construction_year == 0, NA, construction_year)) %>%
	## A value of 0 might not make sense for district_code either
	## latitude ranges in [-11.65,-2e-08] and *plotting* suggests that
	## the almost zeros indicate missing values
	mutate(latitude = ifelse(latitude > -1e-06, NA, latitude)) %>%
	## longitude ranges in [0.0,40.35] and *plotting* suggests that
	## the zeros indicate missing values
	mutate(longitude = ifelse(longitude < 1e-06, NA, longitude))

## For every categorical response, convert the levels to lower case,
## in case there is some random capitalization
chr.cols = data %>% summarise_each(funs(is.character(.))) %>% unlist() %>% which() %>% names()
data = data %>% mutate_each( funs(tolower), one_of(chr.cols))
