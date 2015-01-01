#!/opt/local/bin/python2.7

from scipy.special import betaincinv
import string
import sys

filename = sys.argv[1]
f = open(filename, "r")

band_threshold = 0.05

line = f.next()
fields = string.split(string.strip(line))
parties = fields[1:]

sys.stdout.write("Date")
for p in parties:
  sys.stdout.write("\t{0}_mean\t{0}_lower\t{0}_higher".format(p))
sys.stdout.write("\n")

for line in f:
  fields = string.split(string.strip(line))
  date = fields[0]
  values = map(float, fields[1:])
  norm = sum(values)
  sys.stdout.write(date)
  for v, p in zip(values, parties):
    mean = v / norm
    lower = betaincinv(v, norm - v, band_threshold)
    upper = betaincinv(v, norm - v, 1.0 - band_threshold)
    sys.stdout.write("\t{}\t{}\t{}".format(mean, lower, upper))
  sys.stdout.write("\n")
