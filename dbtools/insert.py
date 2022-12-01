from mysql.connector import connect
from mysql.connector.errors import DatabaseError
from time import *

def get_connection() :
    #TODO: should probably be from a prop file
    host="127.0.0.1"
    user="root"
    password=""
    database="cmsc447"
    return connect (host = host,user = user,passwd = password,database = database )    

#for progess bar
#https://stackoverflow.com/a/850962
def bufcount(filename):
    f = open(filename)                  
    lines = 0
    buf_size = 1024 * 1024
    read_f = f.read # loop optimization

    buf = read_f(buf_size)
    while buf:
        lines += buf.count('\n')
        buf = read_f(buf_size)

    return lines

if __name__ == '__main__' :
    conn = get_connection()
    
    #load county samples
    lines = bufcount("us_counties.csv")
    read = 0
    fh = open("us_counties.csv","r")
    fh.readline() #nuke header
    
    curse = conn.cursor()
    sql = ''' INSERT INTO CountySamples (fips, county_date, county, state, cases, deaths, latitude, longitude)
              VALUES (%s, %s, %s, %s, %s, %s, %s, %s) '''
    
    then = time()
    batch = 10000
    time_left = 0
    alpha = 0.8
    while True:
        line = fh.readline()
        if not line:
            break
        row = line.strip().split(",")
        params = [
            row[3],row[0],row[1],row[2],row[4],row[5],row[6],row[7]
        ]
        
        try:
            curse.execute(sql, params)
        except DatabaseError:
            pass
        
        read += 1
        if not read % batch:
            time_diff = time() - then        #how long for 1000 operations
            ops_left  = lines - read         #how many operations left
            
            if not time_left:
                time_left = (time_diff * (ops_left / batch ))
            else:
                time_left = ( alpha * (time_left) ) + ( (1 - alpha) * (time_diff * (ops_left / batch )) )
            
            time_left = int(time_left)
            time_diff = round(time_diff,3)
            
            pct = 100*(read / lines)
            print("\rCountySamples: " + f"{pct:2.7f}" + "% - Remaining: {:7d}".format(ops_left) +
                  " dt: " + str(time_diff) + ", est: " + str(time_left) + " seconds" ,end='')
            
            then = time()
            
    conn.commit()
    fh.close()
    print("\rCountySamples: " + f"{100:2.7f}" + "%")
    
    #######Much the same thing for the facility samples...!#######
    
    #load county samples
    lines = bufcount("historical_facility_counts.csv")
    read = 0
    fh = open("historical_facility_counts.csv","r")
    fh.readline() #nuke header
    
    curse = conn.cursor()
    sql = ''' INSERT INTO FacilitySamples (name, city, county, county_fips, state, latitude, 
                                         longitude, facility_date, confirmed_cases, deaths, address, zipcode)
              VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) '''
    while True:
        line = fh.readline()
        if not line:
            break
        row = line.strip().split(",")
        
        try:
            tot_cases  = (0 if not row[6] else int(row[6])) + (0 if not row[7] else int(row[7]))
            tot_deaths = (0 if not row[8] else int(row[8])) + (0 if not row[9] else int(row[9]))
        except ValueError: #something exceptionally poorly-formatted
            continue
            
        params = [
            row[3],row[25],row[26],row[29],row[2],row[27],
            row[28],row[4],tot_cases,tot_deaths,row[23],row[24],
        ]
        
        read += 1
        if not read % 1000:
            pct = 100*(read / lines)
            print("\rFacilitySamples: " + f"{pct:2.7f}" + "%",end='')
        try:
            curse.execute(sql, params)
        except DatabaseError:
            pass

    conn.commit()
    fh.close()
    print("\rFacilitySamples: " + f"{100:2.7f}" + "%")
    
    conn.close()


