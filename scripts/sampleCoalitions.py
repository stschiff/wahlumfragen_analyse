#!/opt/local/bin/python2.7

from numpy.random import dirichlet
import string
import sys

filename = sys.argv[1]
nrSamples = int(sys.argv[2])

coalDefs = {
  "ROTGRUEN" : ["SPD", "GRUENE"],
  "SCHWARZGELB" : ["CDU", "FDP"],
  "SCHWARZGRUEN" : ["CDU", "GRUENE"],
  "ROTROTGRUEN" : ["SPD", "GRUENE", "LINKE"],
  "GROKO" : ["CDU", "SPD"]
}

coalNames = coalDefs.keys()
coalParties = [coalDefs[n] for n in coalNames]

f = open(filename, "r")

line = f.next()
fields = string.split(string.strip(line))
partyNames = fields[1:]
partyIndices = {p:i for i, p in enumerate(partyNames)}
coalIndices = [[partyIndices[p] for p in parties] for parties in coalParties]

def renormalizeResult(fractions):
  proportions = [f if f > 0.05 else 0.0 for f in fractions]
  norm = sum(proportions)
  return [p / norm for p in proportions]

def getCoalProbs(params):
  majorities = [0 for c in coalNames]
  samples = dirichlet(params, nrSamples)
  for sample in samples:
    proportions = renormalizeResult(sample)
    for i, _ in enumerate(coalNames):
      coalProportion = sum(proportions[j] for j in coalIndices[i])
      majorities[i] += coalProportion > 0.5
  return [m / float(nrSamples) for m in majorities]

sys.stdout.write("Date\t{}\n".format("\t".join(coalNames)))

for line in f:
  fields = string.split(string.strip(line))
  date = fields[0]
  sys.stderr.write("processing {}\n".format(date))
  values = map(float, fields[1:])
  coalProbs = getCoalProbs(values)
  sys.stdout.write("{}\t{}\n".format(date, "\t".join(map(str, coalProbs))))
