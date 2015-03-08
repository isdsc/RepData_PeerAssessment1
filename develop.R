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
dt[, interval := sub("^(..)", "\\1:", sprintf("%04d", interval))]
dt[, timestamp := ymd_hm(paste(date, interval))]
dt[, date := ymd(date)]
str(dt)


################################################################################
# What is mean total number of steps taken per day?
################################################################################

# Get the steps by date
steps_by_date = dt[, sum(steps), date] # This will create a column with name V1
steps_by_date_na = dt[, list( total_steps = sum(steps) ), date]
head(steps_by_date)
#          date total_steps
# 1: 2012-10-01          NA
# 2: 2012-10-02         126
# 3: 2012-10-03       11352
# 4: 2012-10-04       12116
# 5: 2012-10-05       13294
# 6: 2012-10-06       15420

steps_by_date = dt[, .( total_steps = sum(steps, na.rm = TRUE) ), date]
head(steps_by_date)
#          date total_steps
# 1: 2012-10-01           0
# 2: 2012-10-02         126
# 3: 2012-10-03       11352
# 4: 2012-10-04       12116
# 5: 2012-10-05       13294
# 6: 2012-10-06       15420

# Load ggplot2 package
library(ggplot2)

# Plot with ggplot
# See http://docs.ggplot2.org/current/geom_histogram.html
#   geom_histogram is an alias for geom_bar plus stat_bin

ggplot(dt, aes(x = date)) + stat_bin() # Does this work because default plot is geom_bar()?
ggplot(dt, aes(x = date)) + geom_histogram(colour="black", fill="white")

# See http://docs.ggplot2.org/current/geom_bar.html for stat="identity"
ggplot(steps_by_date, aes(x = date, y = total_steps)) + geom_bar(stat = "identity")


# can we skip the aggregation step?
ggplot(dt, aes(x = date, y = steps)) + geom_bar( stat = "sum")

# This gives the following error:
# Error: replacement element 8 has 62 rows, need 65
# In addition: Warning message:
# Removed 8 rows containing missing values (position_stack).

