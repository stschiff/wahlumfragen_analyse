import string
import datetime
import operator

class Poll:
    def __init__(self, filenames):
        self.parties = self.readPartyNames(filenames[0])
        self.pollEntries = []
        for file in filenames:
            self.readPoll(file)
        self.pollEntries.sort(key=operator.itemgetter("date"))
        all_institutes = [p["institute"] for p in self.pollEntries]
        self.institutes = list(set(all_institutes))
        
    def readPartyNames(self, filename):
        file = open(filename, "r")
        line = file.next()
        fields = string.split(string.strip(line))
        return fields[3:]
    
    def readPoll(self, filename):
        file = open(filename, "r")
        line = file.next()
        fields = string.split(string.strip(line))
        assert fields[0] == "Date"
        assert fields[1] == "Size"
        assert fields[2] == "Institute"
        for line in file:
            fields = string.split(string.strip(line))
            date = datetime.datetime.strptime(fields[0], "%d.%m.%Y")
            size = int(fields[1])
            instituteName = fields[2]
            result = [float(a) for a in fields[3:]]
            norm = sum(result)
            assert abs(norm - 100) < 1e-8, "error in {}: polls must add up to 100%:{}".format(filename, line)
            assert len(result) == len(self.parties), "missing data:{}, {}, {}".format(result, self.parties, line)
            self.pollEntries.append({"date":date, "size":size, "nVec":result, "institute":instituteName})
    
