import random
NbOfVNFTypes = 4
NbOfNodes = 12
NbOfWorkNodes = 6
NbOfSFCs = 10

SetupCostLow = 1
SetupCostHigh = 10
OpCostLow = 1
OpCostHigh = 10

LatencySensitive = False
BwSensitive = True
LatencyLow = 1
LatencyHigh = 10

CPURequirementLow = 5
CPURequirementHigh = 8
BwRequirementLow = 3
BwRequirementHigh = 5

MinLengthOfSFC = 2
MaxLengthOfSFC = 4



MaxNumber = 100000

TypeOfVNFs = ["VNF1", "VNF2", "VNF3", "VNF4"]

def generate_VNFSetupCost(TypeOfVNFs, low, high):
    VNFSetupCost = "VNFSetupCost = #["
    for t in TypeOfVNFs:
        VNFSetupCost = VNFSetupCost +  "\"" + t + "\": " + str(random.randint(low, high)) + ", "
    VNFSetupCost = VNFSetupCost + "]#;"
    return VNFSetupCost


def generate_VNFOpCost(TypeOfVNFs, NbOfWorkNodes, NbOfNodes, low, high):

    VNFOpCost = "VNFOpCost =#[\n"

    for t in TypeOfVNFs:
        vnf = "\"" + t + "\": " + "#["
        for i in range(1, NbOfWorkNodes + 1):
            vnf = vnf + str(i) + ": " + str(random.randint(low, high)) + ", "
        for i in range(NbOfWorkNodes + 1, NbOfNodes + 1):
            vnf = vnf + str(i) + ": " + str(0) + ", "
        VNFOpCost = VNFOpCost + vnf + "]#,\n"
    VNFOpCost = VNFOpCost + "]#;\n"
    return VNFOpCost


def generate_SFCRequest(NbOfSFCs,
                        NbOfWorkNodes,
                        NbOfNodes,
                        LatencySensitive,
                        BwSensitive,
                        TypeOfVNFs,
                        LatencyLow,
                        LatencyHigh,
                        BwLow,
                        BwHigh):
    SFCRequest = "SFCRequests = {\n"
    sfc_c = []
    for i in range(1, NbOfSFCs + 1):
        c = []
        sfc = "<\"sfc_" + str(i) + "\", "
        src = random.randint(NbOfWorkNodes + 1, NbOfNodes)
        dst = random.randint(NbOfWorkNodes + 1, NbOfNodes)
        while(dst == src):
            dst = random.randint(NbOfWorkNodes + 1, NbOfNodes)
        latency = MaxNumber
        bw = 0
        if(LatencySensitive):
            latency = random.randint(LatencyLow, LatencyHigh)
        if(BwSensitive):
            bw = random.randint(BwLow, BwHigh)
        lengthOfSFC = random.randint(2, 4)
        VNFList = "{"
        vnfs = random.sample(TypeOfVNFs, lengthOfSFC)

        for vnf in vnfs:
            VNFList = VNFList + "\"" + vnf + "\", "
            c.append(random.randint(2, 4))
        VNFList = VNFList + "}"
        sfc_c.append(c)

        sfc = sfc + str(src) + ", " + str(dst) + ", " + str(latency) + ", " + str(bw) + ", " + VNFList
        sfc = sfc + ">\n"

        SFCRequest = SFCRequest + sfc
    SFCRequest = SFCRequest + "};"
    return SFCRequest, sfc_c

print

# SFCRequests = {
# 	<"sfc_1", 1, 4, 20, 20, {"VNF3", "VNF2"}>,
# 	<"sfc_2", 1, 4, 25, 20, {"VNF3", "VNF1", "VNF2"}>
# };

VNFSetupCost = generate_VNFSetupCost(TypeOfVNFs, SetupCostLow, SetupCostHigh)

VNFOpCost = generate_VNFOpCost(TypeOfVNFs, NbOfWorkNodes, NbOfNodes, OpCostLow, OpCostHigh)

SFCRequest, sfc_c = generate_SFCRequest(NbOfSFCs,
                        NbOfWorkNodes,
                        NbOfNodes,
                        LatencySensitive,
                        BwSensitive,
                        TypeOfVNFs,
                        LatencyLow,
                        LatencyHigh,
                        BwRequirementLow,
                        BwRequirementHigh)

print 'NbOfSFCs = ' + str(NbOfSFCs) + ';'
print 'MaxNbOfVNFs = 4;'
print VNFSetupCost
print VNFOpCost
print SFCRequest
print sfc_c


