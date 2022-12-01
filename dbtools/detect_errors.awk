#!/bin/awk -f
#awk -F, -f detect_errors.awk historical_facility_counts.csv

function abs(x) { return (x<0) ? x*-1 : x }

BEGIN {
	OFS=","
	
	#s[1] = State Name
	#s[2] = State Center's Latitude
	#s[3] = State Center's Longitude
	getline < "state_center.csv"
	while (getline < "state_center.csv") {
		split($0,s,",")
		centermap[toupper(s[1]),1]= s[2]
		centermap[toupper(s[1]),2]= s[3]
	}
	close("state_center.csv")


	#s[1]: FIPS number
	#s[2]: Full County Name - e.g. XYZQ County. The substring excluding the last 7 characters truncates, " County".
	#s[3]: State Name
	getline < "fips_by_state.csv"
	while (getline < "fips_by_state.csv") {
		split($0,s,",")
		countymap[toupper(substr(s[2],0,length(s[2])-7)),toupper($3)] = s[1] #len(" COUNTY") = 7
	}
	close("fips_by_state.csv")
	
	getline < "bounding.csv"
	while (getline < "bounding.csv") {
		#TODO:
	}
	close("bounding.csv")
	
	"" > "err.log" #clear and create the logfile
	
	#TODO: Remove this lines when needed
	#print("Facility.ID,Jurisdiction,State,Name,Date,source,Residents.Confirmed,Staff.Confirmed,Residents.Deaths,Staff.Deaths,Residents.Tadmin,Residents.Tested,Residents.Active,Staff.Active,Population.Feb20,Residents.Population,Residents.Initiated,Staff.Initiated,Residents.Completed,Staff.Completed,Residents.Vadmin,Staff.Vadmin,Web.Group,Address,Zipcode,City,County,Latitude,Longitude,County.FIPS,ICE.Field.Office")
}
{	
	STATE       = 3
	FACIL_NAME  = 4
	COUNTY_NAME = 27
	LATITUDE    = 28
	LONGITUDE   = 29
	COUNTY_FIPS = 30

	if(NR == 1) { next; } #header

	#if($STATE != "California") { next; } #TODO: Remove this lines when needed.
	
	if(!$COUNTY_NAME && (!$LATITUDE || !$LONGITUDE) && !$COUNTY_FIPS) {
		print($FACIL_NAME" has no data!") > "err.log"
		next;
	}
	else if($COUNTY_FIPS && (!$LATITUDE || !$LONGITUDE)) { #Have a FIPS county number, but no coordanites. 
						             #Thus, unable to display a meaningful location within county. Strike and log.
		print($FACIL_NAME" Has FIPS = "$COUNTY_FIPS" but no coordanite data!") > "err.log"
		next;					
	}
	else if(!$COUNTY_FIPS && $LATITUDE && $LONGITUDE) { #No FIPS Number, but coordanites present. Lookup by county name, then coordanites.
		if($COUNTY_NAME) {
			$COUNTY_FIPS = countymap[toupper($COUNTY_NAME),toupper($STATE)] 
		}
		if(!$COUNTY_FIPS) { #Have yet to successfully deduce a FIPS number.
			if($LATITUDE && $LONGITUDE) {
				if(!$COUNTY_NAME) {
					state = toupper($STATE)
					if(abs($LATITUDE - centermap[state,1]) <= 0.1 && abs($LONGITUDE - centermap[state,2]) <= 0.1) {
						print($FACIL_NAME" is probably not a real prison (distance from center ~ "((abs($LATITUDE - centermap[state,1]) + abs($LONGITUDE - centermap[state,2]))/2)")") > "err.log"
						next; #Nothing more do do with this line.
					}
				}
				else {
				
				}
			}
			
		}
	}
	
	if($COUNTY_FIPS) {
		print($0);
	}
	else {
		print($FACIL_NAME" does not have a derivable FIPS number.") > "err.log"
	}
}
END {
	system("cat err.log | sort | uniq > errr.log")
	system("mv errr.log err.log")
}