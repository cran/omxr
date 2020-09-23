## ----setup--------------------------------------------------------------------
set.seed(10)

## ----load_library-------------------------------------------------------------
library(omxr)

## ----create_omx, echo=c(1,3)--------------------------------------------------
zones <- 1:10
rhdf5::H5close()
omxfile <- tempfile(fileext = ".omx")
create_omx(omxfile, numrows = length(zones), numcols = length(zones))

## ----make_matrix--------------------------------------------------------------
trips <- matrix(rnorm(n = length(zones)^2, 200, 50),  
                nrow = length(zones), ncol = length(zones))
cost <- matrix(rlnorm(n = length(zones)^2, 1, 1),
               nrow = length(zones), ncol = length(zones))

## ----write_omx----------------------------------------------------------------
write_omx(file = omxfile, matrix = trips, "trips", 
          description = "Total Trips")

write_omx(file = omxfile, matrix = cost, "cost", 
          description = "Generalized Cost")

## ----read_matrix--------------------------------------------------------------
read_omx(omxfile, "trips")
read_omx(omxfile, "cost")

## ----long_matrix(), message=FALSE, warning=FALSE------------------------------
library(tidyverse)
read_omx(omxfile, "trips") %>%
  gather_matrix("trips")

## ----read_subset--------------------------------------------------------------
read_omx(omxfile, "trips", row_index = 2:4, col_index = 2:5)

## ----attributes---------------------------------------------------------------
get_omx_attr(omxfile)
list_omx(omxfile)

## ----write_lookup-------------------------------------------------------------
lookup <- zones %in% c(1, 2:5, 9)
lookup
write_lookup(omxfile, lookup_v = lookup, 
             name = "trial", description = "test lookup", replace = TRUE)

## ----read_lookup--------------------------------------------------------------
read_selected_omx(omxfile, "trips", 
                  row_selection = "trial", col_selection = "trial")

