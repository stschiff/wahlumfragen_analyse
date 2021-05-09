#!/usr/bin/env bash

DIR=~/Dropbox/Wahlblick/Data/Sonntagsfrage
mkdir -p $DIR/processed
for FILE in $DIR/*.txt; do
  echo "Processing $FILE" > /dev/stderr
  NAME=$(basename $FILE .txt)
  ./preprocessSonntagsFrage.py < $FILE > $DIR/processed/${NAME}_processed.txt
done