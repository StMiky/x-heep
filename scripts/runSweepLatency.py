import subprocess
import sys
import re
import pandas as pd
from tqdm import tqdm
import argparse


PROJECT_NAME = "dummy_accelerator_test"
cycle_pattern = r'C (\d+)'
inst_pattern = r'I (\d+)'

def toTuple(string : str):
    return tuple(map(int, string.replace("[", "").replace("]", "").split(',')))

def parseArguments():
    parser = argparse.ArgumentParser(description='Run a sweep over the latency of the dummy accelerator')
    parser.add_argument('--type', type=str, default="PIPELINE", help='Type of the dummy accelerator')
    parser.add_argument('--interleaved', type=str, default="500,501", help='Interleaved calls to the dummy accelerator')
    parser.add_argument('--nbi', type=str, default="0,10", help='Number of instructions per block')
    parser.add_argument('--latency', type=str, default="10,20", help='Latency of the dummy accelerator')
    parser.add_argument('--dependency','-d', action="store_true", help='Insert dependency between accel calls')
    parser.add_argument('--unroll', '-u', action="store_true", help='Unroll the main loop with calls to the accel')
    parser.add_argument('--bookeep', action="store_true", help='Unroll the main loop with calls to the accel')
    parser.add_argument('--output', type=str, required=True, help='.csv output')

    args = parser.parse_args()

    args.interleaved = toTuple(args.interleaved)
    args.nbi = toTuple(args.nbi)
    args.latency = toTuple(args.latency)
    args.bookeep = 1 if args.bookeep else 0


    return args
    




def gianCarlo(  type : str = ["PIPELINE", "ITERATIVE"], latency : int = 10, # Was genKernel
                n_block_a : int = 10,
                n_block_b : int = 0,
                interleaved : int = 1,
                bookeep : int = 0,
                interleaved_n_block : int = 10,
                consecutive : int = 0,
                unroll : str = "",
                dependent : str = "",
                template : str = "scripts/dummy_accel.c.tpl",
                output : str = "sw/applications/dummy_accelerator_test/main.c"):
    
    # Call the script
    command = (f"python3 scripts/genDummyAccelKernel.py\
                                    --type {type}\
                                    --latency {latency}\
                                    --n_block_a {n_block_a}\
                                    --n_block_b {n_block_b}\
                                    --interleaved {interleaved}\
                                    --bookeep {bookeep}\
                                    {unroll}\
                                    {dependent}\
                                    --interleaved_n_block {interleaved_n_block}\
                                    --consecutive {consecutive}\
                                    --template {template}\
                                    --output {output}")


    subprocess.run(command, shell=True, capture_output=False, text=True)

# Parse this using a regexp and get the number
def parseNumber(pattern, output : str):
    # Using re.search to find the pattern in the string
    match = re.search(pattern, output)

    # Extracting and printing the matched number if found
    if match:
        extracted_number = match.group(1)
    
    return extracted_number 

def parseIPC(output : str):
    inst = parseNumber(inst_pattern, output)
    cycle = parseNumber(cycle_pattern, output)

    return float(inst) / float(cycle)


def kernelRunner():
    """Function to simulate work and output to stdout."""

    # Source toolchain
    command = "source /software/scripts/init_x_heep"
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    # Basic error handling
    if (result.returncode != 0):
        sys.stdout.write(result.stderr)
        return

    # Then run the simulation
    command = f"make run-app-verilator PROJECT={PROJECT_NAME}"
    result = subprocess.run(command, capture_output=True, text=True, shell=True)

    # Basic error handling
    if (result.returncode != 0):
        sys.stdout.write(result.stderr)
        return
    
    output = result.stdout

    # Store the output in the queue
    return parseIPC(output)

def createDataFrame():
    # With cols: Type, Interleaved Number, NBI, Latency, IPC
    df = pd.DataFrame(columns=['Type', 'Interleaved Number', 'NBI', 'Latency', 'IPC'])

    return df

def pushToDataFrame(df, type, interleaved, nbi, latency, ipc):
    new_row = {'Type': type, 'Interleaved Number': interleaved, 'NBI': nbi, 'Latency': latency, 'IPC': ipc}
    df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)

    return df

def main():
    args = parseArguments()
    # create bar computing the total
    total = (args.interleaved[1] - args.interleaved[0]) * (args.nbi[1] - args.nbi[0]) * (args.latency[1] - args.latency[0])
    pbar = tqdm(total=total)

    df = createDataFrame()

    for interleaved in range(args.interleaved[0], args.interleaved[1]):
        for nbi in range(args.nbi[0], args.nbi[1]):
            for latency in range(args.latency[0], args.latency[1]):
                gianCarlo(
                    type = args.type,
                    interleaved = interleaved,
                    interleaved_n_block = nbi,
                    latency = latency,
                    unroll="-u" if (args.unroll ) else "",
                    dependent="-d" if (args.dependency) else "",
                    bookeep=args.bookeep,
                    n_block_b=nbi
                )

                ipc = kernelRunner()

                df = pushToDataFrame(df, args.type, interleaved, nbi, latency, ipc)
                pbar.update(1)
    

    # Save the dataframe to a CSV file
    df.to_csv(args.output)
    


if __name__ == "__main__":

    main()