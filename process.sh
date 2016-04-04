#!/bin/bash

DB_NAME=ksg2016
FILE_DIR=~/Documents/Personal/Spirit/KSG2016

perl ./loadGymnasts.pl $DB_NAME $FILE_DIR/2015_16GymnastListRev092215.csv
perl ./processSiblings.pl $DB_NAME $FILE_DIR/siblings-19Sep2015.csv
perl ./fixCompetitors.pl "$FILE_DIR/debksg16.csv" > $FILE_DIR/spiritdal16Fixed.csv
perl ./loadCompetitors.pl $DB_NAME $FILE_DIR/spiritdal16Fixed.csv $FILE_DIR/levelSignUps.csv
perl ./processExcused.pl $DB_NAME $FILE_DIR/excused-RSG2015.csv
perl ./loadSignups.pl $DB_NAME $FILE_DIR/signUpGenius-03Apr2016.csv
perl ./counts.pl $DB_NAME
perl ./validateSignUps.pl $DB_NAME 
