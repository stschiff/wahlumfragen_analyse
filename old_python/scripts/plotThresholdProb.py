#!/opt/local/bin/python2.7

from scipy.special import betainc
import string
import sys

filename = sys.argv[1]
f = open(filename, "r")

line = f.next()
fields = string.split(string.strip(line))
parties = fields[1:]

sys.stdout.write("Date\t{}\n".format("\t".join(parties)))

for line in f:
  fields = string.split(string.strip(line))
  date = fields[0]
  values = map(float, fields[1:])
  norm = sum(values)
  probs = [1.0 - betainc(v, norm - v, 0.05) for v in values]
  sys.stdout.write("{}\t{}\n".format(date, "\t".join(map(str, probs))))
