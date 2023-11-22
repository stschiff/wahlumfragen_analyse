import json
from scipy.special import gammaln
from itertools import groupby

class Model:
    def __init__(self, poll, diffusionConstant=0.0001, reductionFactor=1.0):
        self.poll = poll
        self.nrEntries = len(self.poll.pollEntries)
        self.diffusionConstant = diffusionConstant
        self.reductionFactor = reductionFactor
        self.parties = poll.parties
        self.institutes = poll.institutes
        self.biasMatrix = {i:[0.0 for p in self.parties] for i in self.institutes}
        
    def load_params(self, filename):
        f = open(filename, "r")
        obj = json.load(f)
        self.diffusionConstant = obj["sigma"]
        self.reductionFactor = obj["reductionFactor"]
        parties = obj["parties"]
        institutes = obj["institutes"]
        matrix = obj["biasMatrix"]
        party_map = {}
        for i, n in enumerate(parties):
            party_map[n] = i
        institute_map = {}
        for i, n in enumerate(institutes):
            institute_map[n] = i
        for institute in self.institutes:
            for j, party in enumerate(self.parties):
                self.biasMatrix[institute][j] = matrix[institute_map[institute]][party_map[party]]

    def write_params(self):
        matrix = [self.biasMatrix[i] for i in self.institutes]
        print json.dumps({"sigma":self.diffusionConstant, "biasMatrix":matrix, "parties":self.parties, "institutes":self.institutes, "reductionFactor":self.reductionFactor}, indent=4)
        
    def update(self, prior, pollEntry):
        biasVector = self.biasMatrix[pollEntry["institute"]]
        return [p + (n - biasVector[i]) / 100.0 * self.reductionFactor * pollEntry["size"] for i, (p, n) in enumerate(zip(prior, pollEntry["nVec"]))]
  
    def diffuse(self, posterior, days):
        A = sum(posterior)
        newA = A * (1.0 + len(self.parties) * self.diffusionConstant**2 * days) / (1.0 + A * self.diffusionConstant**2 * days)
        return [p * newA / A for p in posterior]

    def logLpart(self, pollEntry, prior, posterior):
        biasVector = self.biasMatrix[pollEntry["institute"]]
        
        N = pollEntry["size"] * self.reductionFactor
        nVec = ((n - biasVector[i]) / 100.0 * N for i, n in enumerate(pollEntry["nVec"]))
        Ft = sum(prior)
        ftVec = prior
        F = sum(posterior)
        fVec = posterior
        result = gammaln(N + 1) - sum(gammaln(k + 1) for k in nVec)
        result += gammaln(Ft) - sum(gammaln(ft) for ft in ftVec)
        result += sum(gammaln(f) for f in fVec) - gammaln(F)
        return result
        
    def runForward(self):
        self.forwardVec = []
        self.logL = 0.0
        prior = [1.0] * len(self.parties)
        for i, pollEntry in enumerate(self.poll.pollEntries):
            posterior = self.update(prior, pollEntry)
            self.forwardVec.append(posterior)
            self.logL += self.logLpart(pollEntry, prior, posterior)
            nextDiff = (self.poll.pollEntries[i + 1]["date"] - pollEntry["date"]).days if i < self.nrEntries - 1 else 1
            prior = self.diffuse(posterior, nextDiff)
    
    def runProjection(self, projectionDate):
        self.projectionVec = []
        prior = [1.0] * len(self.parties)
        for i, pollEntry in enumerate(self.poll.pollEntries):
            posterior = self.update(prior, pollEntry)
            projectionDiff = (projectionDate - pollEntry["date"]).days
            if projectionDiff < 0:
              break
            projection = self.diffuse(posterior, projectionDiff)
            self.projectionVec.append(projection)
            nextDiff = (self.poll.pollEntries[i + 1]["date"] - pollEntry["date"]).days if i < self.nrEntries - 1 else 1
            prior = self.diffuse(posterior, nextDiff)
  
    def runBackward(self):
        self.backwardVec = []
        startDate = self.poll.pollEntries[0]["date"]
        endDate = self.poll.pollEntries[-1]["date"]
        prior = [1.0] * len(self.parties)
        for i, pollEntry in enumerate(reversed(self.poll.pollEntries)):
            self.backwardVec.append(prior)
            posterior = self.update(prior, pollEntry)
            nextDiff = (pollEntry["date"] - self.poll.pollEntries[self.nrEntries - i - 2]["date"]).days if i < self.nrEntries - 1 else 1
            prior = self.diffuse(posterior, nextDiff)
        self.backwardVec.reverse()
        self.posterior = [[f + b - 1 for f, b in zip(fVec, bVec)] for fVec, bVec in zip(self.forwardVec, self.backwardVec)]
    
    def learnDiffusion(self):
        def scoreFunc(x):
            self.diffusionConstant = x
            self.runForward()
            return -self.logL
        minR = minimize_scalar(scoreFunc, bounds=(0.0, 1.0), method="Bounded")
        assert minR.success, "minimization not successful"
        self.diffusionConstant = minR.x
        self.logL = -minR.fun
  
    def learnBiasMatrix(self):
        newBiasMatrix = {i:[0.0 for j in self.parties] for i in self.institutes}
        counts = [0 for j in range(self.institutes)]
        for pollEntry, posteriorVec in zip(self.poll.pollEntries, self.posterior):
            norm = sum(posteriorVec)
            institute = pollEntry["institute"]
            counts[institute] += 1
            for i in range(len(self.parties)):
                p_mean = posteriorVec[i] / norm
                delta = pollEntry["nVec"][i] - p_mean * 100.0
                newBiasMatrix[institute][i] += delta
      
        for i in range(len(self.institutes)):
            for j in range(len(self.parties)):
                newBiasMatrix[i][j] /= float(counts[i]) if counts[i] > 0 else 1.0
            self.biasMatrix = newBiasMatrix
    
    def printResult(self, vec):  
        print "Date\t" + "\t".join(self.parties)
        # this fancy line just groups by date and takes the last entry if there are more then one on one day
        for post, pollEntry in map(lambda g:list(g[1])[-1], groupby(zip(vec, self.poll.pollEntries[:len(vec)]), key=lambda x:x[1]["date"])):
            date = pollEntry["date"]
            print date.strftime("%d.%m.%Y") + "\t" + "\t".join(map(str, post))
