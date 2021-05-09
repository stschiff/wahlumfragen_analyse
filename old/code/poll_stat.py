#!/opt/local/bin/python2.7

import sys
import argparse
import string
import datetime
import math
from scipy.optimize import minimize, minimize_scalar
import operator
import json
import poll
import model

def mainDecode(args):
    poll_ = poll.Poll(args.pollFiles)
    model_ = model.Model(poll_)
    if args.params:
        model_.load_params(args.params)
    if args.diffusionConstant:
        model_.diffusionConstant = args.diffusionConstant
    if args.reductionFactor:
        model_.reductionFactor = args.reductionFactor
    if args.projectionDate:
        date = datetime.datetime.strptime(args.projectionDate, "%d.%m.%Y")
        model_.runProjection(date)
        model_.printResult(model_.projectionVec)
    else:
        model_.runForward()
        model_.runBackward()
        sys.stderr.write("logL: {}\n".format(model_.logL))
        model_.printResult(model_.posterior)
  

def mainEstimate(args):
    poll_ = poll.Poll(args.pollFiles)
    model_ = model_.Model(poll_)
    if args.reductionFactor:
        model_.reductionFactor = args.reductionFactor
    model_.learnDiffusion()
    lastLogL = model_.logL
    lastDiffusion = model_.diffusionConstant
    lastBiasMatrix = model_.biasMatrix
    for it in range(args.maxIter):
        model_.runForward()
        model_.runBackward()
        model_.learnBiasMatrix()
        model_.learnDiffusion()
        if model_.logL <= lastLogL:
            model_.diffusionConstant = lastDiffusion
            model_.biasMatrix = lastBiasMatrix
            break
        else:
            sys.stderr.write("new params: sigma={}, biasMatrix={}, logL={}\n".format(model_.diffusionConstant, model_.biasMatrix, model_.logL))
            lastLogL = model_.logL
            lastBiasMatrix = model_.biasMatrix
    model_.write_params()

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest="cmd")
decode_parser = subparsers.add_parser("decode")
estimate_parser = subparsers.add_parser("estimate")
estimate_parser.add_argument("pollFiles", nargs='+', help="Poll files in wahlrecht.de format")
estimate_parser.add_argument("-m", "--maxIter", type=int, help="maximum EM iterations [default=10]", default=10)
estimate_parser.add_argument("-r", "--reductionFactor", help="Poll Size reduction", type=float)
decode_parser.add_argument("-d", "--diffusionConstant", help="Diffusion constant used in transition model [default=0.0001]", type=float)
decode_parser.add_argument("-r", "--reductionFactor", help="Poll Size reduction", type=float)
decode_parser.add_argument("pollFiles", nargs='+', help="Poll files in wahlrecht.de format")
decode_parser.add_argument("-p", "--params", help="JSON file with the parameters")
decode_parser.add_argument("--projectionDate", help="Date to project onto")

args = parser.parse_args()

if args.cmd == "decode":
    mainDecode(args)
elif args.cmd == "estimate":
    mainEstimate(args)

