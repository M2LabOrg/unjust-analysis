# This function loads the stop and search data from the GOV.UK url
#
# Parameters:
#   desired_sheet: Name of the sheet to be read (default is "open_data").
#   print_info: Boolean indicating whether to print sheet names and data 
#               summary (default is FALSE).
# References: how to read data from url:
# [1] https://scales.arabpsychology.com/stats/how-to-read-a-csv-from-a-url-in-r-3-methods/
# [2] https://stackoverflow.com/questions/69452146/how-can-i-download-ods-data-from-web-to-r
# Returns: Stop and search data

library(tidyverse)
library(httr)
library(readODS)


load_stop_search_data <- function(desired_sheet = "open_data", 
                                  print_info = FALSE, download = FALSE) {

  f <- "data/stop-search-open-data-tables-mar21-mar23-second-edition.ods"
  
  # Download the data if download = TRUE
  if (download) {
    # Stop and search data URL
    dataurl <- "https://assets.publishing.service.gov.uk/media/65ef2cf75b6524100bf21b07/stop-search-open-data-tables-mar21-mar23-second-edition.ods"
    
    # Reading by using the suggestion in reference [2] above
    download.file(dataurl, dest = f)
  }
  
  stop_search_data <- readODS::read_ods(f, sheet=desired_sheet)
  
  # Print a summary of the data if print_info is TRUE
  if (print_info) {
    cat("Summary of stop and search data:\n")
    summary(stop_search_data)
  }
  
  # Return the data frame
  return(stop_search_data)
}


# This function loads the census 2021 data
#
# Parameters:
#    print_info: If TRUE, prints the head of the loaded dataframe.
# References:
# [1] Data source: https://www.ons.gov.uk/peoplepopulationandcommunity/
#                      culturalidentity/ethnicity/bulletins/
#                      ethnicgroupenglandandwales/census2021
# [2] Excel file: https://www.ons.gov.uk/datasets/TS021/editions/2021/
#                     versions/1
# [3] CSV file per region: https://www.ethnicity-facts-figures.service.gov.uk/
#                     uk-population-by-ethnicity/national-and-regional-populations/
#                     regional-ethnic-diversity/latest/
#
# Returns: Census data

load_census_data <- function(print_info = FALSE, download = FALSE) {

  f <- "data/population-by-ethnicity-and-region-2021.csv"
  
  # Download the data if download = TRUE
  
  if (download){
    dataurl <- "https://www.ethnicity-facts-figures.service.gov.uk/uk-population-by-ethnicity/national-and-regional-populations/regional-ethnic-diversity/latest/downloads/population-by-ethnicity-and-region-2021.csv"
    download.file(dataurl, dest=f)
  }
  
  
  # Read the CSV data
  data <- read_csv(f)
  
  # Filter data for census ONS 2021+1 and keep needed columns
  data_filter <- data %>% 
    filter(Ethnicity_type == "ONS 2021 5+1", Geography != "All - England And Wales") %>% 
    select(Geography_code, Geography, Ethnicity, `Ethnic Population`) %>% 
    rename(regions_code = Geography_code,
           region = Geography,
           ethnic_group_code = Ethnicity,
           population = `Ethnic Population`)
  
  # Rename a few levels to make them comparable with the stop and search data
  data_filter <- data_filter %>% 
    mutate(region = str_replace(region, "Yorkshire and The Humber", "Yorkshire and the Humber")) %>% 
    mutate(region = str_replace(region, "East of England", "Eastern")) %>% 
    mutate(ethnic_group_code = str_replace(ethnic_group_code, "Asian", "Asian or Asian British"),
           ethnic_group_code = str_replace(ethnic_group_code, "Black", "Black or Black British"),
           ethnic_group_code = str_replace(ethnic_group_code, "Other", "Other Ethnic Group"))
  
  # Convert to factor
  data_filter$ethnic_group_code <- as.factor(data_filter$ethnic_group_code)
  data_filter$region <- as.factor(data_filter$region)
  
  # Print head if specified
  if (print_info) {
    print(head(data_filter))
  }
  
  return(data_filter)
}
