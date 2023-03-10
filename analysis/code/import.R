#' ---
#' title: "Combine expert estimate tables"
#' author: "Abbey Camaclang"
#' date: "02 Feb 2023"
#' output: github_document
#' ---

#' This script reads individual expert estimates from multiple .csv files,
#' compiles them into a single table, and reorganizes the table into a tidy
#' version. It requires that the individual expert tables contain the same
#' number of rows and columns, are saved as .csv file in a subfolder within the
#' working directory, and no other .csv files are in the same subfolder.

#+ warning = FALSE, message = FALSE
# Load packages
library(here)
library(tidyverse)
library(naniar)

# Specify paths to subfolders within current working directory
input <- here("analysis", "data", "raw", "benefits") # where .csv files of benefit estimates are saved
derived <- here("analysis", "data") # where compiled data tables should be saved
results <- here("analysis", "results") # where results of analysis should be saved


#' Read in the individual tables of expert estimates and combine.  
#' NOTE to maintain confidentiality, only sample tables are provided
nstrat <- 17 # number of strategies (including combinations, but excluding baseline)
ngroups <- 7 # number of ecological groups
numexp <- 10 # number of experts

numcols <- (nstrat+1+2) # number of cols to read in (one per strategy + 1 for Baseline + 2 for row header names)
numrows <- (ngroups+1)*3 # number of rows to read in (3 rows [Best, Low, High] per Ecol group and the example )

skiplines <- 20 # number of header rows to skip (a bit finicky - needs some trial & error)

# Combine .csv files into single data frame
files <- list.files(path = paste(input, "/", sep=""),
                    pattern = "*.csv", 
                    full.names = T)
listcsv <- lapply(files, 
                  function(x) read.csv(x, 
                                       skip = skiplines, 
                                       header = F, 
                                       nrows = numrows, 
                                       as.is = T))
rawdata <- do.call("rbind", listcsv)

# Check that all rows have been read
checkrows <- nrow(rawdata)
if (checkrows != numrows*numexp) {
  warning("Unexpected number of rows in the combined table")
}

rawdata <- rawdata[,1:numcols] # exclude 'Notes' column

# Add column names
names(rawdata) <- c("Ecological.Group", 
                 "Estimate", 
                 "Baseline", 
                 paste(rep("S", times = nstrat), 
                       1:nstrat, 
                       sep = "")) 

# Add new column for Expert ID
tempvec <- c()

for (i in 1:numexp) {
  tempvec <- c(tempvec, rep(i, times = (ngroups+1)*3))
  }

rawdata <- rawdata %>% 
  add_column(Expert = tempvec, .before = "Ecological.Group")

#' Format table
data <- rawdata %>% 
  mutate(Ecological.Group = ifelse(Ecological.Group == "", NA, Ecological.Group)) %>% # changes blank rows to NA
  fill(Ecological.Group) %>% # fills NA rows with Ecological Group name
  filter(!grepl("example", Ecological.Group)) # remove 'example' rows 
  
# Standardize column/row names (if needed - also useful for plotting)
data$Ecological.Group[which(str_detect(data$Ecological.Group, "GRASSLAND") == 1)] <- "Grassland species"
data$Ecological.Group[which(str_detect(data$Ecological.Group, "BURROW/DEN") == 1)] <- "Burrow and den species"
data$Ecological.Group[which(str_detect(data$Ecological.Group, "SAND DUNE") == 1)] <- "Sand dune species"
data$Ecological.Group[which(str_detect(data$Ecological.Group, "WETLAND") == 1)] <- "Wetland and shorebird species"
data$Ecological.Group[which(str_detect(data$Ecological.Group, "AMPHIBIANS") == 1)] <- "Amphibians"
data$Ecological.Group[which(str_detect(data$Ecological.Group, "FISH SPECIES") == 1)] <- "Fish species"
data$Ecological.Group[which(str_detect(data$Ecological.Group, "HEALTHY") == 1)] <- "Healthy prairie landscape"

data$Estimate[which(str_detect(data$Estimate, "High") == 1)] <- "High"
data$Estimate[which(str_detect(data$Estimate, "Low") == 1)] <- "Low"

# Replace X's and blanks with NA
na_strings <- c("X", "X ", "x", "x ")
clean <- data %>%
  replace_with_na_all(condition = ~.x %in% na_strings) %>%
  replace_with_na_all(condition = ~.x == "")
 
# Replace B's with value for baseline estimates from same row 
for (i in 1:(numexp*ngroups*3)) {
  temp <- which(data[i,] == "B" | data[i,] == "b")
  clean[i,temp] <- data[i,4]
}

write.csv(clean, file = paste(derived, "/Estimates_clean.csv", sep = ""), row.names = FALSE)

#' Convert to tidy version
long <-
  gather(clean,
         key = Strategy,
         value = Value,
         Baseline:S17
  )

write_csv(long, file = paste(derived, "/Estimates_tidy.csv", sep = ""))
# head(long)

#' Convert to wide format

grp.levels <- unique(long$Ecological.Group)

long <- na.omit(long)
long$Value <- as.numeric(long$Value)

tempvec <- paste(long$Strategy, long$Estimate, sep = ".")
long <- add_column(long, Strat.Est = tempvec, .before = "Value")
est.levels <- unique(long$Strat.Est)

long.sub <- long[,c(1,2,5,6)]
wide <- spread(long.sub, 
               key = Strat.Est, 
               value = Value)
wide$Ecological.Group <- factor(wide$Ecological.Group, levels = grp.levels) 

wide <- wide[, c("Expert", "Ecological.Group", est.levels)] # Reorder columns by Strategy
wide <- with(wide, wide[order(Expert, Ecological.Group),]) # Reorder rows by Ecological Group

write_csv(wide, file = paste(derived, "/Estimates_wide.csv", sep = ""))
# head(wide)

#' Summarize the number of expert estimates
temp <- subset(long, Estimate == "Best")

strat.levels <- unique(temp$Strategy)
temp$Strategy <- factor(temp$Strategy,levels = strat.levels)

stgy.count <- table(temp$Ecological.Group, temp$Strategy)

write.csv(stgy.count, file = paste(results, "/estimatecounts.csv", sep = ""))