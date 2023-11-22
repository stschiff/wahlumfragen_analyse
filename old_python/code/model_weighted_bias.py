import model

class ModelWeightedBias(Model):
    def __init__(self, poll, election=None):
        super(self, init)
        
    def update(self, prior, pollEntry):
        biasVector = self.biasMatrix[pollEntry["institute"]]
        kVec = [n * pollEntry["size"] * self.reductionFactor for n in pollEntry["nVec"]]
        K = sum(kVec)
        denom = sum(k / biasVector[i] for i, k in enumerate(kVec))
        kTildeVec = [K * (k / biasVector[i]) / denom for i, k in eumerate(kVec)]
        return [p + kTildeVec[i] for i, p in enumerate(prior)]
    
    def logLpart(self, pollEntry, prior, posterior):
        biasVector = self.biasMatrix[pollEntry["institute"]]
        kVec = [n * pollEntry["size"] * self.reductionFactor for n in pollEntry["nVec"]]
        K = sum(kVec)
        denom = sum(k / biasVector[i] for i, k in enumerate(kVec))
        kTildeVec = [K * (k / biasVector[i]) / denom for i, k in eumerate(kVec)]
        
        Ft = sum(prior)
        ftVec = prior
        F = sum(posterior)
        fVec = posterior
        result = gammaln(K + 1) - sum(gammaln(k + 1) for k in kTildeVec)
        result += gammaln(Ft) - sum(gammaln(ft) for ft in ftVec)
        result += sum(gammaln(f) for f in fVec) - gammaln(F)
        return result
    
    def learnBiasMatrixWeightedBias(self):
        nP = self.poll.nrParties
        nI = self.poll.nrInstitutes
        
        def rightHandSide():
            pass
        
        newBiasMatrix = [[1.0 / nP for i in range(nP)] for j in range(nI)]
        counts = [0 for j in range(nI)]
        for pollEntry, posteriorVec in zip(self.poll.pollEntries, self.posterior):
            if self.election and self.poll.instituteNames[pollEntry["institute"]] == self.election:
                continue
            norm = sum(posteriorVec)
            institute = pollEntry["institute"]
            counts[institute] += 1
            for i in range(self.poll.nrParties):
                p_mean = posteriorVec[i] / norm
                delta = pollEntry["nVec"][i] - p_mean * 100.0
                newBiasMatrix[institute][i] += delta
              
        for i in range(self.poll.nrInstitutes):
            for j in range(self.poll.nrParties):
                newBiasMatrix[i][j] /= float(counts[i]) if counts[i] > 0 else 1.0
            self.biasMatrix = newBiasMatrix
