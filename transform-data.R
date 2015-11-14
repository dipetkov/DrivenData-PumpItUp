
## Clean up existing predictors. Engineer some new features.

source("read-data.R")
source("myRfunctions.R")

data = data %>%
  mutate(extraction_type = revalue(extraction_type,
                                   c("cemo" = "other motorpump",
                                     "climax" = "other motorpump",
                                     "other - mkulima/shinyanga" = "other handpump",
                                     "other - play pump" = "other handpump",
                                     "walimi" = "other handpump",
                                     "other - swn 81" = "swn",
                                     "swn 80" = "swn",
                                     "india mark ii" = "india mark",
                                     "india mark iii" = "india mark"))) %>%
  mutate(source = revalue(source,c("other" = NA))) %>%
  mutate(funder = myreduce.levels(funder)) %>%
  mutate(installer = myreduce.levels(installer))
## Compute averages in districts within regions
data = data %>% 
  group_by(region,district_code) %>%
  mutate(district.long = mean(longitude, na.rm = TRUE)) %>%
  mutate(district.lat = mean(latitude, na.rm = TRUE)) %>%
  ungroup()
## Compute averages in regions (just in case the above is also NA)
data = data %>%
  group_by(region) %>%
  mutate(region.long = mean(longitude, na.rm = TRUE)) %>%
  mutate(region.lat = mean(latitude, na.rm = TRUE)) %>%
  ungroup()
## "Impute" missing longitude/latitude values
data = data %>%
  mutate(longitude = ifelse(!is.na(longitude), longitude,
                            ifelse(!is.na(district.long), district.long, region.long))) %>%
  mutate(latitude = ifelse(!is.na(latitude), latitude,
                           ifelse(!is.na(district.lat), district.lat, region.lat))) %>%
  mutate(lga = ifelse( grepl(" rural", lga), "rural",
                       ifelse( grepl(" urban", lga), "urban","other"))) %>%
  mutate(date_recorded = ymd(date_recorded)) %>%
  mutate(day_of_year = yday(date_recorded)) %>%
  mutate(month_recorded = lubridate::month(date_recorded)) %>%
  mutate(operation_years = lubridate::year(date_recorded) - construction_year) %>%
  mutate(operation_years = ifelse(operation_years < 0, NA, operation_years)) %>%
  mutate(season = ifelse( month_recorded <= 2, "dry short",
                          ifelse( month_recorded <= 5, "wet long",
                                  ifelse(month_recorded <= 9, "dry long", "wet short")))) %>%
  select( - scheme_name, - payment, - extraction_type_group,
          - quality_group, - quantity_group, - waterpoint_type_group,
          - source_type, - wpt_name, - subvillage, - ward,
          - region_code, - district_code, - region.long, - region.lat,
          - district.long, - district.lat, - amount_tsh, - num_private,
          - date_recorded , - month_recorded, - construction_year, - id) %>%
  filter(scheme_management != "none" | is.na(scheme_management))

## Let each predictor be either numeric or nominal (factor rather than character or logical)
chr.cols = data %>% summarise_each(funs(is.character(.))) %>% unlist() %>% which() %>% names()
lgl.cols = data %>% summarise_each(funs(is.logical(.))) %>% unlist() %>% which() %>% names()
data = data %>% mutate_each( funs(as.factor), one_of(chr.cols,lgl.cols))
train = data %>% filter(subset == "train") %>% select( - subset)
test = data %>% filter(subset == "test") %>% select( - subset, - status_group)
