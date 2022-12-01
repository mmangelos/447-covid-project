#!/bin/awk -f
#awk -F, -f estm_cty_centroid.awk us_counties.csv

#Attempt to find the center between to latitude and longitudes
#Not strictly accurate, but a good-enough approximation.
function avg(p1,p2) {
	split(p1,p1p," ") #p1p -> [p1[latitude],p1[longitude]]
	split(p2,p2p," ") #p2p -> "                          "
	return ( (p1p[1] + p2p[1]) / 2)" "( (p1p[2] + p2p[2]) / 2)
}

BEGIN {
	LAT  = 1
	LON  = 2
	FIPS = 4
	SW   = 8
	NW   = 9
	NE   = 10
	SE   = 11

	getline < "bounding.csv" #this pattern nukes CSV headers
	while (getline < "bounding.csv") {
		split($0,s,",")
		split(avg(avg(s[SW],s[NW]),avg(s[NE],s[SE])),tmp," ") #Split the average coordanites into an array, with longitide and latitude
		fipsmatch[substr(s[FIPS],2,length(s[FIPS])-2)] = tmp[LAT]","tmp[LON] #Note: s[4] = "\"XXXXX\"", important to strip quot literals.
	}
	close("bounding.csv")
	
	print("###") >> "err.log"
}
{
	COUNTY_NAME = 2
	STATE = 3
	COUNTY_FIPS = 4

	if(NR == 1) { next; } #header
	#if($STATE != "California") { next; } #TODO: Remove this lines when needed.

	ctr = fipsmatch[$COUNTY_FIPS]
	if(!ctr) {
		print("County "$COUNTY_NAME" ("$STATE") could not not have its center found!") >> "err.log"
	}
	else {
		print($0","fipsmatch[$COUNTY_FIPS])
	}
}
END {
	system("cat err.log | sort | uniq > errr.log")
	system("mv errr.log err.log")
}