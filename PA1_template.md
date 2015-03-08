# Reproducible Research: Peer Assessment 1


## Loading and preprocessing the data

Before analyzing the data, we need to load the data into R. The assignment
instructions inform us that the input data contains three columns: `steps`,
`date`, and `interval`. Furthermore the instructions indicate that the dataset
is stored in a comma-separated-value (CSV) file and that there are a total of
17,568 observations in it. The input data is in the file `activity.zip`. From
the extention, we will assume that it is in compressed format.

Just to make sure that our assumption is correct and to get a sense of the
input data, we will take a quick peek at a few records from the input file.
For this task we could use external programs like `head` or `tail`. However,
while these are usually available on *nix systems, they are not available on
standard Windows systems (unless added on later by Cygwin or msys etc.).

To remain platform-agnostic, instead of using `read.csv()` from the base R
system we will use the `fread()` function from the `data.table` package. Also,
the data loading code assumes that open source 7-Zip archive management
software is available in the in the search path of the OS.


```r
# Set the working directory and get the contents of the .zip file
setwd("~/Coursera/Data Science Specialization/5. Reproducible Research/RepData_PeerAssessment1")
system("7za l activity.zip")

# Load the data.table package
library(data.table)

# Read the data into a data.table with default fread() options
dt = fread("7za e -so activity.zip activity.csv 2>nul")

# Take a look at the data
str(dt)
```

```
## Classes 'data.table' and 'data.frame':	17568 obs. of  3 variables:
##  $ steps   : int  NA NA NA NA NA NA NA NA NA NA ...
##  $ date    : chr  "2012-10-01" "2012-10-01" "2012-10-01" "2012-10-01" ...
##  $ interval: int  0 5 10 15 20 25 30 35 40 45 ...
##  - attr(*, ".internal.selfref")=<externalptr>
```

```r
dt
```

```
##        steps       date interval
##     1:    NA 2012-10-01        0
##     2:    NA 2012-10-01        5
##     3:    NA 2012-10-01       10
##     4:    NA 2012-10-01       15
##     5:    NA 2012-10-01       20
##    ---                          
## 17564:    NA 2012-11-30     2335
## 17565:    NA 2012-11-30     2340
## 17566:    NA 2012-11-30     2345
## 17567:    NA 2012-11-30     2350
## 17568:    NA 2012-11-30     2355
```

The instructions indicate that the variable `interval` is the identifier for
5-minute intervals. The first intervals start with the series [0, 5, 10, ...],
and if it were a continous series during the day, we would expect the
following:



```r
# Number of intervals in a day
interval_count = 24 * (60/5)


# Sequence of intervals for one day
data.table(seq(from = 0, by = 5, length.out = interval_count))
```

```
##        V1
##   1:    0
##   2:    5
##   3:   10
##   4:   15
##   5:   20
##  ---     
## 284: 1415
## 285: 1420
## 286: 1425
## 287: 1430
## 288: 1435
```

The tail end of the source dataset doesn't match this vector. In fact, it looks
more like the time of the day in 24-hour format, but without the ":" separator.
To confirm this, we can take a quick look at the end of the hour and the end of
the day:


```r
# Check out the end of the first hour
dt[(60/5 - 1):(60/5 + 2)]
```

```
##    steps       date interval
## 1:    NA 2012-10-01       50
## 2:    NA 2012-10-01       55
## 3:    NA 2012-10-01      100
## 4:    NA 2012-10-01      105
```

```r
# Check out the 24-hour boundary between the first and second day
dt[(24*(60/5)-1):(24*(60/5)+2)]
```

```
##    steps       date interval
## 1:    NA 2012-10-01     2350
## 2:    NA 2012-10-01     2355
## 3:     0 2012-10-02        0
## 4:     0 2012-10-02        5
```

It looks like the `interval` column is actually the time of the day, but it is
formatted as a number: e.g. `55` is followed by `100`; `2355` is followed by
`0`, etc. In case we need a properly formatted `interval` and a proper date and
time variable in later steps, we will transform them and keep them in a new
Date/Time column.



## What is mean total number of steps taken per day?



## What is the average daily activity pattern?



## Imputing missing values



## Are there differences in activity patterns between weekdays and weekends?
