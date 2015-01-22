#!/bin/bash

DB_NAME=dal2015
FILE_DIR=~/Documents/Personal/Spirit/dalmation2015

perl ./loadGymnasts.pl $DB_NAME $FILE_DIR/2014_15GymnastListRev121614.csv 
perl ./processSiblings.pl $DB_NAME $FILE_DIR/siblings-19Sep2014.csv
perl ./loadCompetitors.pl $DB_NAME $FILE_DIR/dalrunkel2.csv $FILE_DIR/levelSignUps.csv
perl ./processExcused.pl $DB_NAME $FILE_DIR/excused-RSG2014.csv
perl ./loadSignups.pl $DB_NAME $FILE_DIR/signUpGenius-21Jan2015.csv
perl ./counts.pl $DB_NAME
perl ./validateSignUps.pl $DB_NAME 
