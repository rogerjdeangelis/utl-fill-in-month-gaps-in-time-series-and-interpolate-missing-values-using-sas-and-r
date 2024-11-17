%let pgm=utl-fill-in-month-gaps-in-time-series-and-interpolate-missing-values-using-sas-and-r;

%stop_submission;

Classic timeseries data preparation

Fill in month gaps in time series and interpolate missing values using sas and r

  CONTENTS

      1 r timeseries packages
      2 related repos


github
https://tinyurl.com/ej8ndex6
https://github.com/rogerjdeangelis/utl-fill-in-month-gaps-in-time-series-and-interpolate-missing-values-using-sas-and-r

/*               _     _
 _ __  _ __ ___ | |__ | | ___ _ __ ___
| `_ \| `__/ _ \| `_ \| |/ _ \ `_ ` _ \
| |_) | | | (_) | |_) | |  __/ | | | | |
| .__/|_|  \___/|_.__/|_|\___|_| |_| |_|
|_|
*/

/**************************************************************************************************************************/
/*                      |                                                  |                                              */
/*         INPUT        |                   PROCESS                        |          OUTPUT                              */
/*         ====         |                   ======                         |          ======                              */
/*                      |                                                  |                                              */
/*  SD1.HAVE obs=12     | %utl_rbeginx;                                    |  year month value  interp                    */
/*                      | parmcards4;                                      |                                              */
/*   year  month value  | library(haven)                                   |  2020   1    NA   528.000                    */
/*                      | library(tidyr)                                   |  2020   2    NA   528.000                    */
/*   2020    7   528    | library(zoo)                                     |  2020   3    NA   528.000                    */
/*   2020    9   551    | library(lubridate)                               |  2020   4    NA   528.000                    */
/*   2020   10   456    | source("c:/oto/fn_tosas9x.R")                    |  2020   5    NA   528.000                    */
/*   2020   12   453    |  # fill missing months;                          |  2020   6    NA   528.000                    */
/*                      |  data<-read_sas("d:/sd1/have.sas7bdat")          |  2020   7   528   528.000  value backwards   */
/*   2021    3   102    |  # fill in mising months;                        |  2020   8    NA   539.500  (528+551)/2=539.5 */
/*   2021    9   889    |  havfil<- data %>%                               |  2020   9   551   551.000                    */
/*   2021   11   640    |    complete(year  = min(year):max(year),         |  2020  10   456   456.000                    */
/*                      |       month = 1.0:12.0,                          |  2020  11    NA   454.500                    */
/*                      |       fill = list(value = NA))                   |  2020  12   453   453.000  value not forward */
/*                      |  print(havfil)                                   |                                              */
/*                      |  # interpolate values;                           |  2021   1    NA   102.000                    */
/*                      |  want <- data.frame()                            |  2021   2    NA   102.000                    */
/*                      |  for (i in min(havfil$year):max(havfil$year)) {  |  2021   3   102   102.000  value backwards   */
/*                      |     hav<-havfil[havfil$year==i,]                 |  2021   4    NA   233.167                    */
/*                      |     ends<-na.locf(na.locf(hav), fromLast = TRUE) |  2021   5    NA   364.333                    */
/*                      |     hav[1,]<-ends[1,]                            |  2021   6    NA   495.500                    */
/*                      |     hav[nrow(hav),]<-ends[nrow(ends),]           |  2021   7    NA   626.667                    */
/*                      |     filmis<-as.data.frame(na.approx(hav$value    |  2021   8    NA   757.833                    */
/*                      |    ,1:nrow(hav)))                                |  2021   9   889   889.000                    */
/*                      |     want<-rbind(want,filmis);                    |  2021  10    NA   764.500  (889 + 640) /2    */
/*                      |  }                                               |  2021  11   640   640.000  value forwards    */
/*                      |  colnames(want)<-"interp"                        |  2021  12    NA   640.000                    */
/*                      |  want<-cbind(havfil,want)                        |                                              */
/*                      |  want                                            |                                              */
/*                      | fn_tosas9x(                                      |                                              */
/*                      |       inp    = want                              |                                              */
/*                      |      ,outlib ="d:/sd1/"                          |                                              */
/*                      |      ,outdsn ="want"                             |                                              */
/*                      |      )                                           |                                              */
/*                      | ;;;;                                             |                                              */
/*                      | %utl_rendx;                                      |                                              */
/*                      |                                                  |                                              */
/**************************************************************************************************************************/

/*   _   _                               _                             _
/ | | |_(_)_ __ ___   ___  ___  ___ _ __(_) ___  ___  _ __   __ _  ___| | ____ _  __ _  ___  ___
| | | __| | `_ ` _ \ / _ \/ __|/ _ \ `__| |/ _ \/ __|| `_ \ / _` |/ __| |/ / _` |/ _` |/ _ \/ __|
| | | |_| | | | | | |  __/\__ \  __/ |  | |  __/\__ \| |_) | (_| | (__|   < (_| | (_| |  __/\__ \
|_|  \__|_|_| |_| |_|\___||___/\___|_|  |_|\___||___/| .__/ \__,_|\___|_|\_\__,_|\__, |\___||___/
 _                   _                               |_|                         |___/
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/


options validvarname=v7;
libname sd1 "d:/sd1";
data sd1.have;
 input year month  value ;
cards4;
2020 07 528
2020 09 551
2020 10 456
2020 12 453
2021 03 102
2021 09 889
2021 11 640
;;;;
run;quit;

/**************************************************************************************************************************/
/*                                                                                                                        */
/*  SD1.HAVE total obs=11                                                                                                 */
/*                                                                                                                        */
/*   year    month   value                                                                                                */
/*                                                                                                                        */
/*   2021       8     1806                                                                                                */
/*   2022       2     1806                                                                                                */
/*   2022       3     1806                                                                                                */
/*   2022       4     1806                                                                                                */
/*   2022       6     1806                                                                                                */
/*   2022       7     1806                                                                                                */
/*   2022       8     1806                                                                                                */
/*   2022       9     1806                                                                                                */
/*   2022      10     2110                                                                                                */
/*   2022      12     2110                                                                                                */
/*   2023       1     2110                                                                                                */
/*                                                                                                                        */
/**************************************************************************************************************************/

/*
 _ __  _ __ ___   ___ ___  ___ ___
| `_ \| `__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|
*/

proc datasets lib=sd1 nolist nodetails;
 delete want;
run;quit;

%utl_rbeginx;
parmcards4;
library(haven)
library(tidyr)
library(zoo)
library(lubridate)
source("c:/oto/fn_tosas9x.R")
 # fill missing months;
 data<-read_sas("d:/sd1/have.sas7bdat")
 # fill in mising months;
 havfil<- data %>%
   complete(year  = min(year):max(year),
      month = 1.0:12.0,
      fill = list(value = NA))
 print(havfil)
 # interpolate values;
 want <- data.frame()
 for (i in min(havfil$year):max(havfil$year)) {
    hav<-havfil[havfil$year==i,]
    ends<-na.locf(na.locf(hav), fromLast = TRUE)
    hav[1,]<-ends[1,]
    hav[nrow(hav),]<-ends[nrow(ends),]
    filmis<-as.data.frame(na.approx(hav$value
   ,1:nrow(hav)))
    want<-rbind(want,filmis);
 }
 colnames(want)<-"interp"
 want<-cbind(havfil,want)
 want
fn_tosas9x(
      inp    = want
     ,outlib ="d:/sd1/"
     ,outdsn ="want"
     )
;;;;
%utl_rendx;

proc print data=sd1.want(drop=rownames);
run;quit;

/**************************************************************************************************************************/
/*                                 |                                                                                      */
/*  >R                             |   SAS                                                                                */
/*                                 |                                                                                      */
/*     year month value   interp   |   year    month    value     interp                                                  */
/*                                 |                                                                                      */
/*  1  2020     1    NA 528.0000   |   2020       1        .     528.000                                                  */
/*  2  2020     2    NA 528.0000   |   2020       2        .     528.000                                                  */
/*  3  2020     3    NA 528.0000   |   2020       3        .     528.000                                                  */
/*  4  2020     4    NA 528.0000   |   2020       4        .     528.000                                                  */
/*  5  2020     5    NA 528.0000   |   2020       5        .     528.000                                                  */
/*  6  2020     6    NA 528.0000   |   2020       6        .     528.000                                                  */
/*  7  2020     7   528 528.0000   |   2020       7      528     528.000                                                  */
/*  8  2020     8    NA 539.5000   |   2020       8        .     539.500                                                  */
/*  9  2020     9   551 551.0000   |   2020       9      551     551.000                                                  */
/*  10 2020    10   456 456.0000   |   2020      10      456     456.000                                                  */
/*  11 2020    11    NA 454.5000   |   2020      11        .     454.500                                                  */
/*  12 2020    12   453 453.0000   |   2020      12      453     453.000                                                  */
/*  13 2021     1    NA 102.0000   |   2021       1        .     102.000                                                  */
/*  14 2021     2    NA 102.0000   |   2021       2        .     102.000                                                  */
/*  15 2021     3   102 102.0000   |   2021       3      102     102.000                                                  */
/*  16 2021     4    NA 233.1667   |   2021       4        .     233.167                                                  */
/*  17 2021     5    NA 364.3333   |   2021       5        .     364.333                                                  */
/*  18 2021     6    NA 495.5000   |   2021       6        .     495.500                                                  */
/*  19 2021     7    NA 626.6667   |   2021       7        .     626.667                                                  */
/*  20 2021     8    NA 757.8333   |   2021       8        .     757.833                                                  */
/*  21 2021     9   889 889.0000   |   2021       9      889     889.000                                                  */
/*  22 2021    10    NA 764.5000   |   2021      10        .     764.500                                                  */
/*  23 2021    11   640 640.0000   |   2021      11      640     640.000                                                  */
/*  24 2021    12    NA 640.0000   |   2021      12        .     640.000                                                  */
/*                                 |                                                                                      */
/**************************************************************************************************************************/


/*___             _       _           _
|___ \   _ __ ___| | __ _| |_ ___  __| |  _ __ ___ _ __   ___  ___
  __) | | `__/ _ \ |/ _` | __/ _ \/ _` | | `__/ _ \ `_ \ / _ \/ __|
 / __/  | | |  __/ | (_| | ||  __/ (_| | | | |  __/ |_) | (_) \__ \
|_____| |_|  \___|_|\__,_|\__\___|\__,_| |_|  \___| .__/ \___/|___/
                                                  |_|
*/

Related Repositories
----------------------------------------------------------------------------------------------------------------------------------
https://github.com/rogerjdeangelis/utl_interpolating_values_in_a_timeseries_when_first-_last_and_middle_values_are_missing

https://github.com/rogerjdeangelis/utl-calculating-and-summing-a-series-when-subsequent-elements-depend-on-previous-elements
https://github.com/rogerjdeangelis/utl-computing-annual-monthly-weekly-and-daily-sums-for-an-irregular-time-series
https://github.com/rogerjdeangelis/utl-cubic-spline-interpolation-for-missing-values-in-a-time-series-by-group
https://github.com/rogerjdeangelis/utl-exploratory-forcasting-sunspot-activity-with-r-auto-arima-time-series
https://github.com/rogerjdeangelis/utl-fill-in-data-between-two-dates-within-by-group-with-non-missing-values-timeseries
https://github.com/rogerjdeangelis/utl-fill-in-gaps-in-time-series-by-groups
https://github.com/rogerjdeangelis/utl-forecast-the-next-four-months-using-a-moving-average-time-series
https://github.com/rogerjdeangelis/utl-identifying-continuos-subseries-of-enrollment-from-claims-data
https://github.com/rogerjdeangelis/utl-impute-missing-values-in-a-arima-timeseries
https://github.com/rogerjdeangelis/utl-number-of-shoppers-in-store-every_5-minutes-time-series
https://github.com/rogerjdeangelis/utl-schdedule-automatic-daily-downloads-of-the-latest-COVID_19-daily-timeseries
https://github.com/rogerjdeangelis/utl-timeseries-calcualtion-of-acf-and-pacf-lagged-autocorrelations
https://github.com/rogerjdeangelis/utl-timeseries-rolling-three-day-averages-by-county
https://github.com/rogerjdeangelis/utl-very-simple-arima-timeseries-model-with-forecast-using-drop-down-to-r
https://github.com/rogerjdeangelis/utl_detecting_structural_breaks_in_a_time_series
https://github.com/rogerjdeangelis/utl_javascript_dygraph_graphics_multipanel_time_series
https://github.com/rogerjdeangelis/utl_moving_average_of_centered_timeseries_or_calculate_a_modified_version_of_moving_averages
https:/ github.com/rogerjdeangelis/utl_Pull-last-non-missing-variable-from-a-series-of-variables
https://github.com/rogerjdeangelis/utl_time_series_analysis_of_sunspots_in_sas_and_r
/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/
