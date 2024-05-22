import subprocess
from tqdm import tqdm

#-------------------------------------------------------------------------------- 
# DEFINES
#-------------------------------------------------------------------------------- 
TYPE = ["ITERATIVE", "PIPELINE"]
ROLLING = ["","-u"]
DEPENDENCY = ["","-d"]
BOOKEEPING = ["", "--bookeep"]
LATENCY = [1, 5]
NBI = LATENCY
INTERLEAVED = [100, 101]

#-------------------------------------------------------------------------------- 
# CODE 
#-------------------------------------------------------------------------------- 


def convertListToString(list):
    return f"[{list[0]},{list[1]}]"

def getFilename(type, latency, nbi, bookeep, unroll, dependency):
    return f"exp_{type}_{convertListToString(latency)}_{convertListToString(nbi)}_{bookeep}_{unroll}_{dependency}.csv"

def getPlotName(type, latency, nbi, bookeep, unroll, dependency):
    return f"exp_{type}_{convertListToString(latency)}_{convertListToString(nbi)}_{bookeep}_{unroll}_{dependency}.png"

def genPlot(type, latency, nbi, bookeep, unroll, dependency):
    filename = getFilename(type, latency, nbi, bookeep, unroll, dependency)
    plotname = getPlotName(type, latency, nbi, bookeep, unroll, dependency)

    # Call the script
    command = (f"python3 scripts/gen3DBarPlotImpl.py\
                                    --type {type}\
                                    --csv {filename}\
                                    --output {plotname}")
    
    # Call the command
    subprocess.run(command, shell=True, capture_output=False, text=False)

def callScript(type, latency, nbi, bookeep, unroll, dependency):
    filename = getFilename(type, latency, nbi, bookeep, unroll, dependency)

    # Call the script
    command = (f"python3 scripts/runSweepLatency.py\
                                    --type {type}\
                                    --latency {convertListToString(latency)}\
                                    --nbi {convertListToString(nbi)}\
                                    {bookeep}\
                                    {unroll}\
                                    {dependency}\
                                    --output {filename}\
                                    --interleaved {convertListToString(INTERLEAVED)}")
    
    # Call the subprocess
    subprocess.run(command, shell=True,
                    capture_output=False,
                    text=False)#,
                    #stdout=subprocess.DEVNULL,
                    #stderr=subprocess.DEVNULL)

def main():

    total = len(TYPE) * len(BOOKEEPING) * len(ROLLING) * len(DEPENDENCY)
    bar = tqdm(total=total)

    for type in TYPE:
        for unroll in ROLLING:
            for dependency in DEPENDENCY:
                for bookeep in BOOKEEPING:
                    callScript(type, LATENCY, NBI, bookeep, unroll, dependency)
                    genPlot(type, LATENCY, NBI, bookeep, unroll, dependency)
                    bar.update(1)

if __name__ == "__main__":
    main()