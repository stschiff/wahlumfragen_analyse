#!/usr/bin/env bash

DIR=~/Dropbox/Wahlblick
SAMPLING=1000
REDUCTION=0.7


# echo "estimating parameters"
# ./poll_stat.py estimate $DIR/Data/Sonntagsfrage/processed/joinedPoll.txt -r $REDUCTION > $DIR/results/params.txt
# 
# echo "decoding hidden states"
# ./poll_stat.py decode -p $DIR/results/params.txt $DIR/Data/Sonntagsfrage/processed/joinedPoll.txt > $DIR/results/posterior.txt
# 
# echo "projecting posterior on 22.09.2013"
# ./poll_stat.py decode -p $DIR/results/params.txt --projectionDate 22.09.2013 $DIR/Data/Sonntagsfrage/processed/joinedPoll.txt > $DIR/results/projection.txt

echo "decoding hidden states Europawahl"
poll_stat/poll_stat.py decode -p $DIR/results/params.txt $DIR/Data/Sonntagsfrage_Europawahl/joined_poll.txt > $DIR/results/posterior_Europawahl.txt

echo "projecting posterior Europawahl on 25.05.2014"
poll_stat/poll_stat.py decode -p $DIR/results/params.txt --projectionDate 25.05.2014 $DIR/Data/Sonntagsfrage_Europawahl/joined_poll.txt > $DIR/results/projection_Europawahl.txt

# echo "sampling coalition probabilities"
# ./sampleCoalitions.py $DIR/results/projection.txt $SAMPLING > $DIR/results/coalitionProjections.txt
# 

echo "preparing plot tables"
# ./plotProjection.py ../results/projection.txt | sed '$d' > ../Website/data/projection.txt
# ./plotProjection.py ../results/posterior.txt > ../Website/data/posterior.txt
./plotProjection.py ../results/projection_Europawahl.txt > ../Website/data/projection_Europawahl.txt
./plotProjection.py ../results/posterior_Europawahl.txt > ../Website/data/posterior_Europawahl.txt
cp ../Data/Sonntagsfrage_Europawahl/joined_poll.txt ../Website/data/joinedPoll_Europawahl.txt
# cp ../Data/Sonntagsfrage/processed/joinedPoll.txt ../Website/data/joinedPoll.txt
# ./plotThresholdProb.py ../results/projection.txt | sed '$d' > ../Website/data/thresholdProb.txt
# cat ../results/coalitionProjections.txt | sed '$d' > ../Website/data/coalitionProjections.txt
# cp ../results/params.txt ../Website/data/params.txt
