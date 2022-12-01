# COVID-19 In Criminal Justice Facilities

## Authors

The Hackers: Mitchell, Will, Minh-Tri, Alex, and Tom

## Project Structure

The folder structure is as follows:

app/			-- the backend is here (app.js)
templates/		-- the template(s) are here (index.html)
static/			-- javascript, css, geojson files, and  other assets are here
dbtools/		-- the code required to download and import all the data into mysql
db/				-- the database schema
setup/			-- contains a setup script that will prepare your machine for development

## Quick Start

If you are testing, please refer to the submitted user manual and use the provided VDI
file in virtualbox.

## Developing

If you are developing you can bootstrap a new Ubuntu 20.04 VM by running the
commands in the makefile as follows:

    make setup && make db_setup && make db && make populate && make run

## External Code

rSlider.js is the work of https://slawomir-zaziablo.github.io/range-slider/
