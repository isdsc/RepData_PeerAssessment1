################################################################################
# Loading and preprocessing the data
################################################################################

# Set the working directory and get the contents of the .zip file
setwd("~/Coursera/Data Science Specialization/5. Reproducible Research/RepData_PeerAssessment1")
system("7za l activity.zip")

# Load the data.table package
library(data.table)

# Take a peek at the top 5 rows from the input file
print(fread("7za e -so activity.zip activity.csv 2>nul", nrows = 5))

# Take a peek at the top 5 rows from the input file
# Wouldn't use this if this was a very large file
print(fread("7za e -so activity.zip activity.csv 2>nul", skip = 17564))

dt = fread("7za e -so activity.zip activity.csv 2>nul")

# Load lubridate package for easy handling of dates/times
library(lubridate)

# Experiment transforming the interval
dt[, timestamp := sub("^(..)", "\\1:", sprintf("%04d", dt[, interval]))]
dt[, timestamp := sub("(..)$", ":\\1", sprintf("%s %04d", date, interval))]
dt[, timestamp := ymd_hm(sub("(..)$", ":\\1", sprintf("%s %04d", date, interval)))]

str(dt)

# Is lubridate smart enough to deal with non-delimited time?
# NOTE: don't forget this returns a vector! => It will print up to 1000 elements
dt[, sprintf("%s %04d", date, interval)]
# This will make sure we return a data.table (use list() for j)
dt[, .(sprintf("%s %04d", date, interval))]

# This works: lubridate, doesn't need the HH:MM separator, but needs all four digits
bla = dt[, ymd_hm(sprintf("%s %04d", date, interval))]
identical(bla, dt[, timestamp])
# [1] TRUE

# Concatenate date and reformatted time and convert to date/time class
dt[, timestamp := ymd_hm(sprintf("%s %04d", date, interval))]
str(dt)

