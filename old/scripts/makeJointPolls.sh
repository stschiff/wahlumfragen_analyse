#!/usr/bin/env bash

DIR=~/Dropbox/Wahlblick/Data
( printf "Date\tSize\tInstitute\tCDU\tSPD\tLINKE\tGRUENE\tFDP\tAFD\tPIRATEN\tSONSTIGE\n"
for F in $DIR/Sonntagsfrage/processed/*_processed.txt; do
  tail -n+2 $F
done ) | sort -t '.' -nk 3 -nk 2 -nk 1 > ~/Dropbox/Wahlblick/Data/Sonntagsfrage/processed/joinedPoll.txt

