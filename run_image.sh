#!/usr/bin/env bash
docker run --rm --name measurinator -e PASSENGER_APP_ENV=development -e DB_HOSTS=$(ifconfig en0|grep "inet "|sed "s/^.*inet \([0-9.]*\)*.*$/\1/") -p 9999:80 measurinator-website
