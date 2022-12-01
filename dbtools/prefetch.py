#!/usr/bin/env python3

# generates requests for each date throughout the pandemic
# in order to prime the redis cache
from datetime import datetime, timedelta
import urllib3
import time

http = urllib3.PoolManager()

# prime the top 10 days

date = datetime.now() 
for i in range(10):
    counties_url = "http://127.0.0.1:3000/api/county-samples?startDate=2019-01-01" + \
          "&endDate=" + date.strftime("%Y-%m-%d")

    facilities_url = "http://127.0.0.1:3000/api/facility-samples?startDate=2019-01-01" + \
          "&endDate=" + date.strftime("%Y-%m-%d")

    # we don't care about the result, we're priming a cache

    http.request("GET", counties_url)
    time.sleep(1)
    http.request("GET", facilities_url)
    time.sleep(1)

    date -= timedelta(days=1)

