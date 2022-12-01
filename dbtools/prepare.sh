#!/usr/bin/bash

#DATA TO INSERT
curl "https://raw.githubusercontent.com/uclalawcovid19behindbars/data/master/historical-data/historical_facility_counts.csv" > historical_facility_counts.csv
curl "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv" > us_counties.csv

#DATA TO HELP CLEANING
curl "https://gist.githubusercontent.com/rozanecm/29926a7c8132a0a25e3b12a24abdff86/raw/3ae7ae4456b90d4ce0bccab29c95a688fc077ef5/states.csv" > state_center.csv
curl "https://swe.umbc.edu/~w55/fips_by_state.csv" > fips_by_state.csv
curl "https://raw.githubusercontent.com/stucka/us-county-bounding-boxes/master/bounding.csv" > bounding.csv

#DO THE CLEANING
awk -F, -f detect_errors.awk historical_facility_counts.csv > "tmp.csv"
mv "tmp.csv" historical_facility_counts.csv

awk -F, -f estm_cty_centroid.awk us_counties.csv > "tmp.csv"
mv "tmp.csv" us_counties.csv