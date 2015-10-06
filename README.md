# Temperaturinator

## About

## Installation

Currently you need to install the database schema manually.

It is in the file **db/schema.cql**.

First create keyspace:

    $ cqlsh
    
    cqlsh> create KEYSPACE temperatures WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

Then

	$ cqlsh -f db/schema.cql
	
Now you are ready to run the software by executing 

	$ rails server