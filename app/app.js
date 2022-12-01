const fs = require('fs');
const http = require('http');
const static = require('node-static');
const url = require('url');
const mysql = require('mysql');
const redis = require('redis');

const hostname = '0.0.0.0';
const port = 3000;

const US = require('./us_states_and_counties.js');

// connects to the sql database asynchronously and runs
// the specified query; results are passed to callback
function query(sql, callback, params) {
    var con = mysql.createConnection({
        host: "127.0.0.1",
        user: "root",
        database: "cmsc447",
        password: "",
    });

    con.connect(function(err) {
        if (err) throw err;
        con.query(sql, callback);
    });
}

// checks the cache for an appropriate result before calling a view
// function -- the data the queries will always return the same result set so
// this is a trivial optimization -- use this to decorate a view function
function checkCache(viewFn) {
    return function (req, res) {
        const redisClient = redis.createClient({ host: 'localhost' })
        redisClient.on("connect", function() {
            redisClient.get(req.url, function(err, data) {
                // if the response is not already cached
                if (data == null) {
                    // then we'll hand over control to the view function
                    viewFn(req, res);

                // if it is cached
                } else {
                    // then just return the cached response
                    res.statusCode = 200;
                    res.setHeader('Content-Type', 'application/json');
                    res.end(data);
                }
            });
        });
    }
}

// cache the result of a view function -- call this with the request URL
// of a view function decorated with checkCache to save ourselves from querying
// the database when we know nothing has chanced
function cacheResult(url, result) {
    const redisClient = redis.createClient({ host: 'localhost' })
    redisClient.on("connect", function() {
        redisClient.set(url, result);
    });
}

// handle a request to the /api/county-samples endpoint
function handleCountySamples(req, res) {
    // fetch the latest facility samples (maximize date)
    var sql = `
WITH f1 AS
    (SELECT county, state, longitude, latitude, cases, deaths, county_date, RANK()
        OVER
        (PARTITION BY county ORDER BY county_date DESC) as \`rank\`
    FROM CountySamples WHERE county_date BETWEEN ? AND ?)
SELECT county, state, longitude, latitude, cases, deaths, county_date FROM f1 WHERE \`rank\` = 1 ORDER BY county;
`;

    var params = url.parse(req.url, true).query;
    var startDate = params["startDate"].replaceAll("/", "-");
    var endDate = params["endDate"].replaceAll("/", "-");

    // safely parameterize query
    sql = mysql.format(sql, [startDate, endDate]);

    query(sql, function(err, result) {
        if (err) throw err;
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json');
        // organize the data such that we can look up counties by state and then
        // county name
        var data = {};

        // copy a reference to this static object we'll use as an optimization to
        // avoid making an expensive query (we still query the database for
        // individual county data) -- the stringify and parse are a cheap trick
        // to get a deep copy (this avoids stale/lingering data)
        var data = JSON.parse(JSON.stringify(US.COUNTIES_BY_STATE));

        // organize the results by state and county using the above optimization
        for(var i = 0; i < result.length; i++) {
            var row = result[i];

            var state = row["state"];
            var county = row["county"];
            var obj = data[state][county];

            obj["fips"] = STATE_TO_FIPS[state];
            obj["county"] = county;
            obj["state"] = state;
            obj["longitude"] = row["longitude"];
            obj["latitude"] = row["latitude"];
            obj["cases"] = row["cases"];
            obj["deaths"] = row["deaths"];
            obj["county_date"] = row["county_date"];
        }

        // serialize result as JSON
        var result = JSON.stringify(data);

        // cache in redis
        cacheResult(req.url, result);

        // send response to browser
        res.end(result);
    });
}
// always check cache for handleCountySamples result
handleCountySamples = checkCache(handleCountySamples);


// handle a request to the /api/facility-samples endpoint
function handleFacilitySamples(req, res) {
    // fetch the latest facility samples (maximize date)
    var sql = `
WITH f1 AS
    (SELECT name, longitude, latitude, confirmed_cases, facility_date, RANK()
        OVER
        (PARTITION BY name ORDER BY facility_date DESC) as \`rank\`
    FROM FacilitySamples WHERE facility_date BETWEEN ? AND ?)
SELECT name, longitude, latitude, confirmed_cases, facility_date FROM f1 WHERE \`rank\` = 1 ORDER BY name;
`;

    var params = url.parse(req.url, true).query;
    var startDate = params["startDate"].replaceAll("/", "-");
    var endDate = params["endDate"].replaceAll("/", "-");

    // safely parameterize query
    sql = mysql.format(sql, [startDate, endDate]);


    query(sql, function(err, result) {
        if (err) throw err;

        // serialize result
        var result = JSON.stringify({ "facilities" : result });

        // cache in redis
        cacheResult(req.url, result);

        // send to browser
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json');
        res.end(result);
    });
}
// always check cache for handleFacilitySamples result
handleFacilitySamples = checkCache(handleFacilitySamples);

// serve static files
var staticServer = new static.Server("../static")
function serveStaticFile(req, res) {
    req.addListener("end", function() {
        staticServer.serve(req, res);
    }).resume();
}

// route URL to appropriate handler
const server = http.createServer((req, res) => {
    // delegate request to static file server
    if (req.url.includes("/css") || req.url.includes("/js") 
        || req.url.includes("/geo") || req.url.includes("/img")) {
        return serveStaticFile(req, res);
    }

    // delegate to API endpoints
    if (req.url.includes("/api/facility-samples")) {
        return handleFacilitySamples(req, res);
    }

    if (req.url.includes("/api/county-samples")) {
        return handleCountySamples(req, res);
    }

    // delegate requests to url handlers
    template = "../templates/index.html"
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/html');
    res.end(fs.readFileSync(template).toString());
});

server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname}:${port}/`);
});
