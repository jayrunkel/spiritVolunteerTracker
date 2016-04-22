#!/bin/bash

DB_NAME=ppgl2016
FILE_DIR=~/Documents/Personal/Spirit/PPGL2016

perl ./loadGymnasts.pl $DB_NAME $FILE_DIR/2015_16GymnastListRev092215.csv
perl ./processSiblings.pl $DB_NAME $FILE_DIR/siblings-19Sep2015.csv
perl ./fixCompetitors.pl "$FILE_DIR/ChampDeb.csv" > $FILE_DIR/$DB_NAME.Fixed.csv
perl ./loadCompetitors.pl $DB_NAME $FILE_DIR/$DB_NAME.Fixed.csv $FILE_DIR/levelSignUps.csv
perl ./processExcused.pl $DB_NAME $FILE_DIR/excused-RSG2015.csv
perl ./loadSignups.pl $DB_NAME $FILE_DIR/signUpGenius-20Apr2016.csv
perl ./counts.pl $DB_NAME
perl ./validateSignUps.pl $DB_NAME 
