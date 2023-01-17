library(tidyverse)
library(data.table)

# load data set
setwd(dirname(rstudioapi::getActiveDocumentContext()[["path"]]))
path_i = "./PretrialReleaseDataExtractWeb" #input data path
raw_data <- read.csv(paste0(path_i, "/PretrialReleaseDataExtractWeb.csv"), header = TRUE)

# preview data
str(raw_data)

# filter onto variables of interest
clean_data <- raw_data %>%
  # remove the unique case ID because there are multiple dockets from the same arrest
  select(-ï..Internal_Case_ID) %>%
  # remove duplicates
  distinct() %>%
  # convert NULL ages to 0 in order to subsequently mutate it
  mutate(Age_at_Arrest = ifelse(Age_at_Arrest == "NULL", 0, Age_at_Arrest),
         Age_at_Crime = ifelse(Age_at_Crime == "NULL", 0, Age_at_Crime)) %>%
  # create binary variable for whether bail was granted
  mutate(any_bail = ifelse(Bail_Set_and_Posted_at_Arraign == "Y" | Bail_Set_and_Not_Posted_at_Arraign == "Y",
                           1, 0),
         First_Arraign_Date = as.Date(First_Arraign_Date, "%m/%d/%y"),
         general_age = pmax(Age_at_Arrest, Age_at_Crime),
         First_Bail_Set_Cash = ifelse(is.na(First_Bail_Set_Cash) == TRUE, 0, First_Bail_Set_Cash),
         First_Bail_Set_Credit = ifelse(is.na(First_Bail_Set_Credit) == TRUE, 0, First_Bail_Set_Credit),
         First_Insurance_Company_Bail_Bond = ifelse(is.na(First_Insurance_Company_Bail_Bond) == TRUE, 0, First_Insurance_Company_Bail_Bond),
         First_Secured_Surety_Bond = ifelse(is.na(First_Secured_Surety_Bond) == TRUE, 0, First_Secured_Surety_Bond),
         First_Secured_App_Bond = ifelse(is.na(First_Secured_Surety_Bond) == TRUE, 0, First_Secured_Surety_Bond),
         First_Unsecured_Surety_Bond = ifelse(is.na(First_Unsecured_Surety_Bond) == TRUE, 0, First_Unsecured_Surety_Bond),
         First_Unsecured_App_Bond = ifelse(is.na(First_Unsecured_App_Bond) == TRUE, 0, First_Unsecured_App_Bond)) %>%
  mutate(after_july_2020 = ifelse(First_Arraign_Date >= as.Date("07/01/2020", "%m/%d/%y"), 1, 0),
         bail_amt = case_when(First_Bail_Set_Cash > 0 ~ First_Bail_Set_Cash,
                              First_Bail_Set_Credit > 0 ~ First_Bail_Set_Credit,
                              First_Insurance_Company_Bail_Bond > 0 ~ First_Insurance_Company_Bail_Bond,
                              First_Secured_Surety_Bond > 0 ~ First_Secured_Surety_Bond,
                              First_Secured_App_Bond > 0 ~ First_Secured_App_Bond,
                              First_Unsecured_Surety_Bond > 0 ~ First_Unsecured_Surety_Bond,
                              First_Unsecured_App_Bond > 0 ~ First_Unsecured_App_Bond)) %>%
  # filter out NAs
  filter(is.na(Race) == FALSE,
         Race != "Unknown",
         Ethnicity != "Unknown",
         Gender != "Unknown",
         general_age > 0,
         # Docket_Status != "Pending",
         # is.na(Docket_Status) == FALSE,
         is.na(First_Arraign_Date) == FALSE,
         (Representation_Type != "NULL" & Representation_Type != "Unknown"),
         any_bail == 1,
         bail_amt != 1) %>%
  # classify representation types as private or public
  mutate(Representation_PubPriv = case_when(Representation_Type == "18B (Assigned Counsel)" ~ "Private",
                                            Representation_Type == "Conflict Defender" ~ "Private",
                                            Representation_Type == "Legal Aid" ~ "Public",
                                            Representation_Type == "Public Defender" ~ "Public",
                                            Representation_Type == "Retained Attorney" ~ "Private",
                                            Representation_Type == "Self Represented" ~ "Private"),
         # recode categorical variables to create ordinal variable
         Top_Charge_Arraign_Ordinal = case_when(Top_Charge_Weight_at_Arraign == "AF" ~ 1,
                                                Top_Charge_Weight_at_Arraign == "BF" ~ 2,
                                                Top_Charge_Weight_at_Arraign == "CF" ~ 3,
                                                Top_Charge_Weight_at_Arraign == "DF" ~ 4,
                                                Top_Charge_Weight_at_Arraign == "EF" ~ 5,
                                                Top_Charge_Weight_at_Arraign == "AM" ~ 6,
                                                Top_Charge_Weight_at_Arraign == "BM" ~ 7,
                                                Top_Charge_Weight_at_Arraign == "UM" ~ 8),
         Warrant_Ordered_btw_Arraign_and_Dispo = ifelse(Warrant_Ordered_btw_Arraign_and_Dispo == "Y", 1, 0)) %>%
  select(arr_cycle_id, Warrant_Ordered_btw_Arraign_and_Dispo, County_Name, Gender, Race, Ethnicity, general_age, any_bail, after_july_2020,
         Representation_PubPriv, Court_Type, Court_Name, Court_ORI, District, Region, Judge_Name, Top_Charge_Weight_at_Arraign,
         Top_Severity_at_Arraign, First_Arraign_Date, Disposition_Date, bail_amt, Top_Charge_Arraign_Ordinal,
         prior_vfo_cnt, prior_nonvfo_cnt, prior_misd_cnt) %>%
  # replace null values with 0 for prior convictions
  mutate(prior_vfo_cnt = ifelse(prior_vfo_cnt == "NULL", 0, prior_vfo_cnt),
         prior_nonvfo_cnt = ifelse(prior_nonvfo_cnt == "NULL", 0, prior_nonvfo_cnt),
         prior_misd_cnt = ifelse(prior_misd_cnt == "NULL", 0, prior_misd_cnt),
         bail_amt = as.integer(bail_amt)) %>%
  # take unique rows based on all column info
  unique()

rm(raw_data)

# remove more repeats in the data that are due to multiple crimes but the same arraignment cycle ID
repeats <- clean_data %>%
  group_by(arr_cycle_id) %>%
  count() %>%
  filter(n > 1) %>%
  rename("entries" = "n") %>%
  filter(arr_cycle_id != "NULL")

# split data into three parts since I have to clean them separately

# PART 1. good data
good_data <- clean_data %>%
  filter(arr_cycle_id != "NULL") %>% 
  anti_join(repeats, by = "arr_cycle_id")

# PART 2. null data that we will add in last
null_data <- clean_data %>%
  filter(arr_cycle_id == "NULL")

# PART 3. clean duplicates
# this gives us anything that has Superior Court over Local court and based on the Top Charge
deduped_1 <- clean_data %>% inner_join(repeats,
                         by = "arr_cycle_id") %>%
  filter(Disposition_Date != "NULL") %>%
  group_by(arr_cycle_id, entries, Court_Type) %>%
  count() %>%
  filter(n == 1) %>%
  ungroup() %>%
  select(arr_cycle_id) %>%
  inner_join(clean_data, by = "arr_cycle_id") %>%
  # gives us all the duplicated arr_cycle_ids where one of the disposition dates is simply null
  filter(Disposition_Date != "NULL") %>%
  arrange(Top_Charge_Arraign_Ordinal, desc(Court_Type)) %>%
  group_by(Top_Charge_Arraign_Ordinal, arr_cycle_id) %>%
  slice_head(n = 1) %>%
  ungroup() %>%
  unique()

deduped_2 <- clean_data %>% inner_join(repeats, by = "arr_cycle_id") %>%
  filter(Disposition_Date != "NULL") %>%
  anti_join(deduped_1) %>%
  arrange(Top_Charge_Arraign_Ordinal, desc(Court_Type)) %>%
  group_by(Top_Charge_Arraign_Ordinal, arr_cycle_id) %>%
  slice_head(n = 1) %>%
  ungroup() %>%
  unique() %>%
  select(-entries)

final_data <- good_data %>%
  rbind(null_data) %>%
  rbind(deduped_1) %>%
  rbind(deduped_2) %>%
  # remove arr_cycle_id since we want to catch any NULL arr_cycle_ids that are duplicates of existing entries
  unique()

# create an alternative data set with missing data so that we can evaluate covariates that were excluded
clean_data %>% group_by(arr_cycle_id) %>% count() %>% filter(n > 1)

# create output
write.csv(final_data, "./Thesis Data Analysis/final_data.csv")
