################################################################################
# Loading and preprocessing the data
################################################################################
# Show any code that is needed to
#   1. Load the data (i.e. read.csv())
#   2. Process/transform the data (if necessary) into a format suitable for
#      your analysis

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
# For this part of the assignment, you can ignore the missing values in the
# dataset.
#   1. Calculate the total number of steps taken per day
#   2. If you do not understand the difference between a histogram and a
#      barplot, research the difference between them. Make a histogram of the
#      total number of steps taken each day
#   3. Calculate and report the mean and median of the total number of steps
#      taken per day


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


# can we skip the aggregation step? Something like:
ggplot(dt, aes(x = date, y = steps)) + geom_bar( stat = "sum")

# This gives the following error:
# Error: replacement element 8 has 62 rows, need 65
# In addition: Warning message:
# Removed 8 rows containing missing values (position_stack).


################################################################################
# What is the average daily activity pattern?
################################################################################
# 1. Make a time series plot (i.e. type = "l") of the 5-minute interval
#    (x-axis) and the average number of steps taken, averaged across all days
#    (y-axis).
# 2. Which 5-minute interval, on average across all the days in the dataset,
#    contains the maximum number of steps?

steps_by_interval = dt[, .( average_steps = sum(steps, na.rm = TRUE) ), interval]

l = ggplot(steps_by_interval, aes(x = interval, y = average_steps, group = 1)) +
  geom_line() +
  ggtitle("Average Daily Activity Pattern") +
  xlab("5-min Intervals") +
  ylab("Average Steps Taken")

# axis.text.x=element_text(angle=90, hjust=1), 

l + theme(
  axis.text.x=element_text(angle=90),
  panel.grid.minor = element_blank(),
  panel.grid.major.x = element_blank()
)

require(scales) # for removing scientific notation
l + scale_y_continuous(labels = comma)

# manually generate breaks/labels
# http://stackoverflow.com/questions/14428887/overflowing-x-axis-ggplot2
# Extracting every nth element of a vector
# http://stackoverflow.com/questions/5237557/extracting-every-nth-element-of-a-vector
labels = steps_by_interval[1:(length(interval)/12)*12, interval]
labels = steps_by_interval[seq(1, length(interval), 12), interval]

# and set breaks and labels
l + scale_x_discrete(breaks=labels, labels=as.character(labels)) + theme(axis.text.x=element_text(angle=90))

# Max steps
steps_by_interval[, max(average_steps)]
# [1] 10927

# Position of max steps
steps_by_interval[, which.max(average_steps)]
# [1] 104

# Interval with max average steps
steps_by_interval[ average_steps == steps_by_interval[, max(average_steps)]]
#    interval average_steps
# 1:    08:35         10927

# Canonical
steps_by_interval[which.max(average_steps)]
#    interval average_steps
# 1:    08:35         10927

# Add a vertical line to the graph
l + geom_vline(aes(xintercept = steps_by_interval[, which.max(average_steps)]))

# Add a line up to the max steps
# http://stackoverflow.com/questions/9085104/is-there-a-way-to-limit-vline-lengths-in-ggplot2
# marks = data.table(list(average_steps = steps_by_interval[, which.max(average_steps)], interval = )
# geom_segment(data=marks, aes(xend=-Inf, yend=probability))

max_step_index = steps_by_interval[, which.max(average_steps)]
max_steps = steps_by_interval[which.max(average_steps), average_steps]
max_steps_interval = steps_by_interval[which.max(average_steps), interval]

l + geom_segment(aes(x = max_step_index, y = 0, xend = max_step_index, yend = max_steps), colour = "blue", linetype = "longdash") +
   geom_segment(aes(x = 1, y = max_steps, xend = max_step_index, yend = max_steps))


l + geom_text(x = max_step_index, y = max_steps, label = max_steps)

l + geom_text(x = max_step_index, y = max_steps, label = max_steps, hjust=0, vjust=0)

l + geom_text(x = max_step_index, y = 0, label = max_steps_interval, hjust=0, vjust=2, angle = 90)
