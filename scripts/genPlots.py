import subprocess
from tqdm import tqdm
import concurrent.futures

#-------------------------------------------------------------------------------- 
# DEFINES
#-------------------------------------------------------------------------------- 
TYPE = ["ITERATIVE", "PIPELINE"]
ROLLING = ["", "-u"]
DEPENDENCY = ["", "-d"]
BOOKEEPING = ["", "--bookeep"]
LATENCY = [1, 21]
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

def callScript(type, latency, nbi, bookeep, unroll, dependency, id):
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
                                    --interleaved {convertListToString(INTERLEAVED)}\
                                    --id {id}")
    
    # Call the subprocess
    if (id == 0):
        subprocess.run(command, shell=True,
                        capture_output=False,
                        text=False
                        )
    else:
        subprocess.run(command, shell=True,
                        capture_output=False,
                        text=False
                        # stdout=subprocess.DEVNULL,
                        # stderr=subprocess.DEVNULL
                        )

def execute_task(params):
    type, unroll, dependency, bookeep, id = params
    callScript(type, LATENCY, NBI, bookeep, unroll, dependency, id)
    genPlot(type, LATENCY, NBI, bookeep, unroll, dependency)
    return 1

def main():

    total = len(TYPE) * len(BOOKEEPING) * len(ROLLING) * len(DEPENDENCY)

    # for type in TYPE:
    #     for unroll in ROLLING:
    #         for dependency in DEPENDENCY:
    #             for bookeep in BOOKEEPING:
    #                 callScript(type, LATENCY, NBI, bookeep, unroll, dependency, id)
    #                 genPlot(type, LATENCY, NBI, bookeep, unroll, dependency)
    #                 bar.update(1)
    params_list = [
    (type, unroll, dependency, bookeep, id)
    for id, (type, unroll, dependency, bookeep) in enumerate(
        (type, unroll, dependency, bookeep)
        for type in TYPE
        for unroll in ROLLING
        for dependency in DEPENDENCY
        for bookeep in BOOKEEPING
    )
    ]

    with concurrent.futures.ProcessPoolExecutor() as executor:
        # Use tqdm to show progress bar
        results = list(tqdm(executor.map(execute_task, params_list), total=len(params_list)))


if __name__ == "__main__":
    main()