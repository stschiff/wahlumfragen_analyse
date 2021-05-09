#!/usr/bin/env python

import sys
import string


finalParties = ["CDU", "SPD", "LINKE", "GRUENE", "FDP", "AFD", "PIRATEN"]
finalPartyMap = {p:i for i, p in enumerate(finalParties)}
maxMissing = 5



line = sys.stdin.next()
fields = string.split(string.strip(line))

parties = fields[3:]
partyMap = {p:i for i, p in enumerate(parties)}
sonstIndex = partyMap["SONSTIGE"]


print "Date\tSize\tInstitute\t{}\tSONSTIGE".format("\t".join(finalParties))

for line in sys.stdin:
  fields = string.split(string.strip(line))
  date = fields[0]
  size = fields[1]
  institute = fields[2]
  finalValues = [None for p in finalParties]
  for i in range(len(fields) - 3):
    party = parties[i]
    sonst = float(fields[3 + i]) if party == "SONSTIGE" else None
    if party not in finalPartyMap:
      continue
    finalIndex = finalPartyMap[party]
    try:
      finalValues[finalIndex] = float(fields[3 + i])
    except ValueError:
      pass
  assert sonst, "need value for \"SONSTIGE\""
  missingCount = 0
  for i, value in enumerate(finalValues):
    if not value:
      finalValues[i] = sonst / maxMissing
      missingCount += 1
  assert missingCount <= maxMissing, "too many missing values"
  
  print "{}\t{}\t{}\t{}\t{}".format(date, size, institute, "\t".join([str(v) for v in finalValues]), 100 - sum(finalValues))

  