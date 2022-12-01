.PHONY: setup db populate run

setup:
	chmod +x setup/setup.sh && ./setup/setup.sh	

# must be run once before the first time you run `db'
db_setup:
	dbtools/setup.sh
	
db:
	mysql -u root cmsc447 < db/db_schema.sql

populate: db
	chmod +x dbtools/*.sh
	cd dbtools && rm -f *.csv && ./prepare.sh && python3 ./insert.py && cd -

run:
	./run.sh

