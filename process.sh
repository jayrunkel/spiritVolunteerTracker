#!/bin/bash

DB_NAME=rsg2015
FILE_DIR=~/Documents/Personal/Spirit/RSG2015

perl ./loadGymnasts.pl $DB_NAME $FILE_DIR/2015_16GymnastListRev092215.csv
perl ./processSiblings.pl $DB_NAME $FILE_DIR/siblings-19Sep2015.csv
perl ./loadCompetitors.pl $DB_NAME $FILE_DIR/Deb.csv $FILE_DIR/levelSignUps.csv
perl ./processExcused.pl $DB_NAME $FILE_DIR/excused-RSG2015.csv
perl ./loadSignups.pl $DB_NAME $FILE_DIR/signUpGenius-28Sep2015.csv
perl ./counts.pl $DB_NAME
perl ./validateSignUps.pl $DB_NAME 
