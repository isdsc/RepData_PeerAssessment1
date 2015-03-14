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

# Get the steps by date
steps_by_date = dt[, .( total_steps = sum(steps) ), date]

# Calculate average steps by interval, overall
estimates_overall = dt[,
  .(nobs = sum(!is.na(steps)), average_steps = mean(steps, na.rm = TRUE)),
  interval
]
setkey(estimates_overall, interval)

# Calculate average steps by interval, by week day
estimates_dow = dt[,
  .(nobs = sum(!is.na(steps)), average_steps = mean(steps, na.rm = TRUE)),
  .(dow  = wday(date, label = TRUE, abbr = TRUE), interval)
]
setkey(estimates_dow, dow, interval)

# To compare the alternative estimation methods, create two imputed variables
dt[is.na(steps),
  `:=`(
    imputed_flag = TRUE,
    imputed_dow = estimates_dow[
      .SD[, .(dow = wday(date, label = TRUE, abbr = TRUE), interval)],
      average_steps
    ],
    imputed_overall = estimates_overall[
      .SD[, interval],
      average_steps
    ]
  )
]
dt[!is.na(steps),
  `:=`(
    imputed_flag    = FALSE,
    imputed_dow = steps,
    imputed_overall = steps
  )
]

# Stack imputed values
stacked = rbind(
  dt[, .(date, interval, Method = "1. Original", Imputed = "No", steps)],
  dt[is.na(steps),
    .(
      date,
      interval,
      Method  = "2. Impute: Overall",
      Imputed = "Yes",
      steps   = estimates_overall[.SD[, interval], average_steps]
    )
  ],
  dt[!is.na(steps), .(date, interval, Method = "2. Impute: Overall", Imputed = "No", steps)],
  dt[is.na(steps),
    .(
      date,
      interval,
      Method  = "3. Impute: DOW",
      Imputed = "Yes",
      steps   = estimates_dow[
        .SD[, .(dow = wday(date, label = TRUE, abbr = TRUE), interval)],
        average_steps
      ]
    )
  ],
  dt[!is.na(steps), .(date, interval, Method = "3. Impute: DOW", Imputed = "No", steps)]
)

# Aggreate for the histogram comparisons
step_by_date_impute = na.omit(stacked[,
  .(total_steps = sum(steps)),
  .(date, Method)
])

