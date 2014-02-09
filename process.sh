#!/bin/bash

DB_NAME=dalmation2014
FILE_DIR=~/Documents/Personal/dalmation2014

./loadGymnasts.pl $DB_NAME $FILE_DIR/gymnasts10Dec2013.csv 3
./processSiblings.pl $DB_NAME $FILE_DIR/siblings-21Dec2013.csv
./loadCompetitors.pl $DB_NAME $FILE_DIR/dal14spirit-15Jan2014.csv
./processExcused.pl $DB_NAME $FILE_DIR/excused-Dalmatian2014.csv
./loadSignups.pl $DB_NAME $FILE_DIR/signUpGenius-04Feb2014.csv
./counts.pl $DB_NAME
./validateSignUps.pl $DB_NAME 
