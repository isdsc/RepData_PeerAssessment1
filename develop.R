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

# mean steps taken
steps_by_date[, mean(total_steps)]
# [1] 9354.23

# median steps taken
steps_by_date[, median(total_steps)]
# [1] 10395

# revisit na.rm: by removing these, we keep the dates without data, and the sum
# of steps on thosedays become zero. When we take the average again, those zeros
# bring down the average. This would be very clear if our "histogram" was
# properly constructed. Now, let's move to the correct histogram, and revisit
# the difference between na.rm or not for the daily totals.

# In retrospect, this question is asking about the distribution of the mean
# steps taken during a typical day. The comment about the bar plot vs
# histogram in the question is also an evidence of this. Now, take a look at
# the distribution (no need to reinvent the wheel):
summary(steps_by_date)


# The histogram to show the disribution of these days will have the days as the
# x axis and the y axis will be count (as is in a true histogram) of days at
# that level of activity.
ggplot(steps_by_date, aes(x = total_steps)) + geom_histogram()
ggplot(steps_by_date, aes(x = total_steps)) + stat_bin()
ggplot(steps_by_date, aes(x = total_steps)) + geom_density()
ggplot(steps_by_date, aes(x = total_steps)) + geom_histogram()                   + geom_density()
ggplot(steps_by_date, aes(x = total_steps)) + geom_histogram(aes(y=..density..)) + geom_density()
ggplot(steps_by_date, aes(x = total_steps)) + geom_histogram()                   + geom_density(aes(y=..scaled..))
ggplot(steps_by_date, aes(x = total_steps)) + geom_histogram(aes(y=..ncount..))  + geom_density(aes(y=..scaled..))
ggplot(steps_by_date, aes(x = total_steps)) + geom_histogram()                   + geom_density(aes(y=..scaled..*4))

# Add the mean line
ggplot(steps_by_date, aes(x = total_steps)) + geom_histogram() + geom_vline(aes(xintercept=mean(total_steps, na.rm=TRUE)))

require(scales) # for removing scientific notation

plot_it = function(dt_to_plot) { 
  ggplot(dt_to_plot, aes(x = total_steps)) +
    geom_histogram(colour="black", fill="white") +
    ggtitle("Distribution of Total Steps per Day") +
    xlab("Total Steps in a Day") +
    ylab("Number of Days") +
    scale_x_continuous(labels = comma) +
    geom_density(aes(y=..scaled..*4.35), alpha=0.2, fill="#FF6666") +
    geom_vline(aes(xintercept=mean(total_steps, na.rm=TRUE)), color="red", size=1) +
    geom_vline(aes(xintercept=median(total_steps, na.rm=TRUE)), color="blue",linetype="dashed", size=1)
}

# This makes it very clear that na.rm at the daily total level is wrong!
plot_it(dt[, .( total_steps = sum(steps, na.rm = TRUE) ), date])

# Go back to using steps_by_date_na
steps_by_date = dt[, list( total_steps = sum(steps) ), date]

plot_it(steps_by_date)

# Stack them up
p1 <- plot_it(dt[, .( total_steps = sum(steps, na.rm = TRUE) ), date])
p2 <- plot_it(dt[, .( total_steps = sum(steps) ), date])

require(grid)

grid.newpage()
pushViewport(viewport(layout = grid.layout(nrow = 2, ncol = 1)))
print(p1, vp = viewport(layout.pos.row = 1, layout.pos.col = 1))
print(p2, vp = viewport(layout.pos.row = 2, layout.pos.col = 1))

summary(steps_by_date)

# Get the mean and median for the text, now we have to use na.rm
stats = steps_by_date[,
  .(
    mean   = mean(total_steps, na.rm = TRUE),
    median = median(total_steps, na.rm = TRUE)
  )
]
stats
#        mean median
# 1: 10766.19  10765

# Can we access the stats from within summary()?
stats = summary(steps_by_date)
stats
 #      date             total_steps   
 # Min.   :2012-10-01   Min.   :   41  
 # 1st Qu.:2012-10-16   1st Qu.: 8841  
 # Median :2012-10-31   Median :10765  
 # Mean   :2012-10-31   Mean   :10766  
 # 3rd Qu.:2012-11-15   3rd Qu.:13294  
 # Max.   :2012-11-30   Max.   :21194  
 #                      NA's   :8

class(stats)
# [1] "table"

str(stats)
#  'table' chr [1:7, 1:2] "Min.   :2012-10-01  " "1st Qu.:2012-10-16  " "Median :2012-10-31  " "Mean   :2012-10-31  " ...
#  - attr(*, "dimnames")=List of 2
#   ..$ : chr [1:7] "" "" "" "" ...
#   ..$ : chr [1:2] "     date" " total_steps"

names(attributes(stats))
# [1] "dim"      "dimnames" "class"

attributes(stats)
# $dim
# [1] 7 2

# $dimnames
# $dimnames[[1]]
# [1] "" "" "" "" "" ""

# $dimnames[[2]]
# [1] "     date"    " total_steps"

# $class
# [1] "table"

unclass(stats)
#       date               total_steps     
#  "Min.   :2012-10-01  " "Min.   :   41  "
#  "1st Qu.:2012-10-16  " "1st Qu.: 8841  "
#  "Median :2012-10-31  " "Median :10765  "
#  "Mean   :2012-10-31  " "Mean   :10766  "
#  "3rd Qu.:2012-11-15  " "3rd Qu.:13294  "
#  "Max.   :2012-11-30  " "Max.   :21194  "
#  NA                     "NA's   :8  "

names(unclass(stats))
# NULL


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
  xlab("Intervals") +
  ylab("Average Steps Taken")

# axis.text.x=element_text(angle=90, hjust=1), 

l + theme(
  axis.text.x=element_text(angle=90),
  panel.grid.minor = element_blank(),
  panel.grid.major.x = element_blank()
)

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


################################################################################
# Imputing missing values
################################################################################
# Note that there are a number of days/intervals where there are missing
# values (coded as NA). The presence of missing days may introduce bias into
# some calculations or summaries of the data.
# 1. Calculate and report the total number of missing values in the dataset
#    (i.e. the total number of rows with NAs)
# 2. Devise a strategy for filling in all of the missing values in the
#    dataset. The strategy does not need to be sophisticated. For example, you
#    could use the mean/median for that day, or the mean for that 5-minute
#    interval, etc.
# 3. Create a new dataset that is equal to the original dataset but with the
#    missing data filled in.
# 4. Make a histogram of the total number of steps taken each day and
#    Calculate and report the mean and median total number of steps taken per
#    day. Do these values differ from the estimates from the first part of the
#    assignment? What is the impact of imputing missing data on the estimates
#    of the total daily number of steps?

# Rows with missing values
nrow(na.omit(dt, invert = TRUE))
# [1] 2304

# One approach to imputing is to get the average of the interval for specific
# days of the week. E.g. a person's daily activity on a weekend day is more
# likely to be similar to to another weekend day rather than a weekday. We can
# extend the same logic and assume that the expected pattern on a Monday will
# be similar to the average of activities accross Mondays.

# See how many days are covered if we use a weekday-specific averages
# (Note that from part two, we already know there are 61 unique days)
uniqueN(dt[, date])

# This gives the interval counts by week day
dt[, .N, wday(date)]
#    wday    N
# 1:    2 2592
# 2:    3 2592
# 3:    4 2592
# 4:    5 2592
# 5:    6 2592
# 6:    7 2304
# 7:    1 2304

# Get the count of observed week days
unique(dt[, .(date)])[, .N, wday(date)]
#    wday N
# 1:    2 9
# 2:    3 9
# 3:    4 9
# 4:    5 9
# 5:    6 9
# 6:    7 8
# 7:    1 8

# Average steps by interval/by week day
estimates = dt[,
  .(nobs = sum(!is.na(steps)), average_steps = mean(steps, na.rm = TRUE)),
  .(weekday = wday(date), interval)
]
setkey(estimates, weekday, interval)

# Here, do a faceted ggplot to see how similar the patterns are by week day
# TODO
# TODO
# TODO

# dt outer join estimates
estimates[dt[, .(weekday = wday(date), interval)]]

# Intervals with missing data
dt[is.na(steps), ]

# This creates a new column
dt[is.na(steps), bla := 1]

# Drop the added column
dt[, bla := NULL]

dt[is.na(steps), bla := 1]
dt[!is.na(steps), imputed := steps]

# Drop the added columns
dt[, c("bla", "imputed") := NULL]

# This does it in two passes 1: estimates for NAs 2: actuals
# Also takes care of the int v. num issue
dt[is.na(steps), imputed := estimates[.SD[, .(weekday = wday(date), interval)], average_steps]]
dt[!is.na(steps), imputed := steps]


estimates[dt[, .(weekday = wday(date), interval, date, timestamp, steps)], .(imputed = if (is.na(steps)) average_steps else steps)]
#         imputed
#     1: 1.428571
#     2: 0.000000
#     3: 0.000000
#     4: 0.000000
#     5: 0.000000
#    ---         
# 17564: 0.000000
# 17565: 0.000000
# 17566: 0.000000
# 17567: 0.000000
# 17568: 1.142857

imputed = estimates[dt[is.na(steps), .(weekday = wday(date), interval), nomatch = 0], .(steps = average_steps)]

# Get the steps by date
steps_by_date = dt[, .( total_steps = sum(imputed) ), date]

# mean steps taken
steps_by_date[, mean(total_steps)]
# [1] 10821.21

# median steps taken
steps_by_date[, median(total_steps)]
# [1] 11015


# What would happen if we used overall average to impute the missing values?
estimates_overall = dt[!is.na(steps), .(nobs = .N, average_steps = mean(steps)), interval]
setkey(estimates_overall, interval)

# How is the distribution of these estimates?
ggplot(estimates_overall, aes(x = interval, y = average_steps)) +
  geom_bar(stat = "identity") +
  scale_x_discrete(breaks=labels, labels=as.character(labels)) + theme(axis.text.x=element_text(angle=90))

# How about by week day?
estimates_overall[, weekday := 0]
# This ifelse() doesn't work
comb = rbind(estimates_overall, estimates)[, day := ifelse(weekday == 0, "All", wday(weekday, label = TRUE, abbr = TRUE))]

# How about by week day?
estimates_overall[, day := "All"]
# This ifelse() doesn't work
comb = rbind(estimates_overall, estimates[, day := wday(weekday, label = TRUE, abbr = TRUE)])

ggplot(comb, aes(x = interval, y = average_steps)) +
  facet_grid(day ~ .) +
  geom_bar(stat = "identity") +
  scale_x_discrete(breaks=labels, labels=as.character(labels)) + theme(axis.text.x=element_text(angle=90))


# Combine alternatives in the same datasets
dt[is.na(steps),
  `:=`(
    imputed         = TRUE,
    imputed_overall = estimates_overall[.SD[, interval], average_steps],
    imputed_weekday = estimates[.SD[, .(weekday = wday(date), interval)], average_steps]
   )
]
dt[!is.na(steps), 
  `:=`(
    imputed         = FALSE,
    imputed_overall = steps,
    imputed_weekday = steps
   )
]

ggplot(dt[interval == "10:25"], aes(x = date, y = steps)) + geom_bar(stat = "identity")

ggplot(dt, aes(x = date, y = imputed_overall, fill = imputed)) + geom_bar(stat = "identity")

ggplot(dt, aes(x = date, y = imputed_weekday, fill = imputed)) + geom_bar(stat = "identity")

# Note that these latest plots don't use a pre-aggregated data table
# In fact, if the individual intervals had different characteristics, those
# would be captured by these plots. To illustrate:
dt[c(20:90, 130, 150, 170, 211:212, 250:255), imputed := FALSE ]
ggplot(dt, aes(x = date, y = imputed_weekday, fill = imputed)) + geom_bar(stat = "identity")
dt[is.na(steps), imputed := TRUE ]


# Stacking up the plots
plot_it = function(dt_to_plot, plot_title) {
  ggplot(dt_to_plot, aes(x = total_steps)) +
    geom_histogram     ( colour = "black", fill = "white") +
    ggtitle            ( plot_title ) +
    xlab               ( "Total Steps in a Day") +
    ylab               ( "Number of Days") +
    scale_x_continuous ( labels = comma) +
    geom_density       ( aes(y = ..scaled..*4.35), alpha = 0.2, fill = "#FF6666") +
    geom_vline         ( aes(xintercept = mean(total_steps, na.rm = TRUE)),   color = "red", size = 1) +
    geom_vline         ( aes(xintercept = median(total_steps, na.rm = TRUE)), color = "blue", linetype = "dashed", size = 1)
}

step_by_date_impute = na.omit(stacked[,
  .(total_steps = sum(steps)),
  .(date, Method)
])
hist1 = plot_it(step_by_date_impute[Method == "1. Original"]       , "Original")
hist2 = plot_it(step_by_date_impute[Method == "2. Impute: Overall"], "Impute: Overall")
hist3 = plot_it(step_by_date_impute[Method == "3. Impute: Weekday"], "Impute: Weekday")


grid.newpage()
# These two are probably the same:
pushViewport(viewport(width = unit(1, "snpc"), height = unit(2, "snpc"), layout = grid.layout(nrow = 3, ncol = 1)))
pushViewport(viewport(width = 1, height = 2, layout = grid.layout(nrow = 3, ncol = 1)))

print(hist1, vp = viewport(layout.pos.row = 1, layout.pos.col = 1))
print(hist2, vp = viewport(layout.pos.row = 2, layout.pos.col = 1))
print(hist3, vp = viewport(layout.pos.row = 3, layout.pos.col = 1))


# For easier arrangement of plots in a grid
require(gridExtra)
grid.arrange(hist1, hist2, hist3)

