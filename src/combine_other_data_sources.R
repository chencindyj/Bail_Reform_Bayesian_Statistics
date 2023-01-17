library(brms)
library(rstanarm)
library(dplyr)
library(stringr)

# load data set
setwd(dirname(rstudioapi::getActiveDocumentContext()[["path"]]))
path_i = "." #input data path
final_data <- read.csv(paste0(path_i, "/final_data.csv"))

# convert ordinal variable into ordered factor
final_data$Top_Charge_Arraign_Ordinal <- ordered(factor(final_data$Top_Charge_Arraign_Ordinal,
                                                levels = c(1, 2, 3, 4, 5, 6, 7, 8)))


# add in ACS income data
income_data <- read.csv(paste0(path_i, "/clean_acs_data.csv"), na.strings = "-")
income_data <- income_data %>%
  mutate(clean_county = str_extract(County, "^(\\w+)")) %>%
  mutate(clean_county = ifelse(clean_county == "New", "New York",
                               ifelse(clean_county == "St", "St. Lawrence", clean_county)),
         race_black = as.integer(race_black))

# add in income data by gender
gender_data <- read.csv(paste0(path_i, "/gender_split.csv"), na.strings = "-")
gender_data <- gender_data %>%
  mutate(female_index = Female / Male) %>%
  select(County, female_index)

# create a merged data frame
merged_data <- final_data %>% left_join(income_data,
                         by = c("County_Name" = "clean_county")) %>%
  select(-County, -Metric) %>%
  left_join(gender_data, by = c("County_Name" = "County")) %>%
  filter(Race == "White" | Race == "Black") %>%
  
  # transform data so we can estimate income for each defendant based on ACS data
  mutate(estimated_income = case_when(
    Race == "White" ~ race_white,
    Race == "Black" ~ race_black) * case_when(Ethnicity == "Hispanic" ~ hispanic_index,
                                              Ethnicity == "Non Hispanic" ~ non_hispanic_white_index) *
      case_when(general_age <= 24 ~ age_group_15_24,
                general_age >= 25 & general_age <= 44 ~ age_group_25_44,
                general_age >= 45 & general_age <= 64 ~ age_group_45_64,
                general_age >= 65 ~ age_group_65_plus) * 0.59 *
      case_when(Gender == "Female" ~ female_index,
                Gender == "Male" ~ 1), 
    censored = ifelse(Disposition_Date == "NULL", 0, 1),
    estimated_income = log(estimated_income),
    after_july_2020 = as.factor(after_july_2020),
    bail_amt = log(bail_amt),
    Judge_Name = as.factor(Judge_Name),
    general_age = general_age/10) # divide age so we scale better

# createa subset of judges so that we can investigate the judges with the top 10 case counts 
judge_list <- merged_data %>%
  group_by(Judge_Name) %>%
  count() %>%
  rename(case_count = n) %>%
  filter(case_count > 50) %>%
  select(Judge_Name)

# make a subset for those judges
merged_data_test <- merged_data %>% inner_join(judge_list, by = "Judge_Name")

rm(income_data, final_data, gender_data, income_data, judge_list, merged_data)