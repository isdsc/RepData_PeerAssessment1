# Set the working directory
setwd("~/Coursera/Data Science Specialization/5. Reproducible Research/RepData_PeerAssessment1")

# Load packages
library(data.table)
library(lubridate)
library(ggplot2)
require(scales) # for removing scientific notation
require(grid)
require(gridExtra)


# Load and get the dataset ready
dt = fread("7za e -so activity.zip activity.csv 2>nul")
dt[, interval := sub("^(..)", "\\1:", sprintf("%04d", interval))]
dt[, timestamp := ymd_hm(paste(date, interval))]
dt[, date := ymd(date)]
