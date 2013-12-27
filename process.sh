#!/bin/bash

./loadGymnasts.pl gymnasts10Dec2013.csv 1
./processSiblings.pl siblings-21Dec2013.csv
./loadCompetitors.pl spiritsnow14.csv
./processExcused.pl excused-21Dec2013.csv
./loadSignups.pl signUpGenius-27Dec2013.csv
./validateSignUps.pl
