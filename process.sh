#!/bin/bash

DB_NAME=SF2015
FILE_DIR=~/Documents/Personal/Spirit/SF2015

perl ./loadGymnasts.pl $DB_NAME $FILE_DIR/2014_15GymnastListRev091514.csv 1
perl ./processSiblings.pl $DB_NAME $FILE_DIR/siblings-19Sep2014.csv
perl ./loadCompetitors.pl $DB_NAME $FILE_DIR/snowflake18Dec2014.csv
perl ./processExcused.pl $DB_NAME $FILE_DIR/excused-RSG2014.csv
perl ./loadSignups.pl $DB_NAME $FILE_DIR/signUpGenius-26Dec2014.csv
perl ./counts.pl $DB_NAME
perl ./validateSignUps.pl $DB_NAME 
