#!/bin/bash

DB_NAME=ksg2014
FILE_DIR=~/Documents/Personal/KSG2014

./loadGymnasts.pl $DB_NAME $FILE_DIR/Gymnasts2013-2014rev03112014.csv 2
./processSiblings.pl $DB_NAME $FILE_DIR/siblings-21Dec2013.csv
./loadCompetitors.pl $DB_NAME $FILE_DIR/gymnastsKSG08May2014.csv
./processExcused.pl $DB_NAME $FILE_DIR/excused-KSG2014.csv
./loadSignups.pl $DB_NAME $FILE_DIR/signUpGenius-15May2014.csv
./counts.pl $DB_NAME
./validateSignUps.pl $DB_NAME 
