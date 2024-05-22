# Script to generate a kernel for the dummy accelerator

import argparse
from mako.template import Template
import random

ADD="\tADD(dest, source, source2);\n" 
XOR="\tXOR(dest, source, source2);\n"
SUB="\tSUB(dest, source, source2);\n"

def getDUMMY(type, latency, dependent):
    if (dependent is False):
        source = "source"
    else:
        source = "new_result"

    if (type in ["ITERATIVE", "PIPELINE"]):
        return f"\tDUMMY_{type}(dest_dummy, {source}, {latency});\n"
    else:
        raise ValueError("Invalid type of dummy accelerator")

def sumDummyAndBookeep():
    return f"\tADD(new_result, bookeeping(), dest_dummy)\n"

def getBlockB(n_block_b):
    block_b = f"\tregister int source = 112412, source2 = 12412412;\n"
    for i in range(n_block_b):
        block_b += random.choice([ADD, XOR, SUB])

    block_b = block_b.replace("dest", "acc")

    return block_b



# Write basic commandline parsing options
def parse_args():
    parser = argparse.ArgumentParser(description='Generate a dummy accelerator kernel')

    parser.add_argument('--output', '-o', type=str, default='dummy_accel_kernel.c',
                        help='Output file name')

    parser.add_argument('--n_block_a', '-na', type=int, default=3,
                        help='Number of instructions before the call to the dummy accel')

    parser.add_argument('--type_accel', '-t', choices=["ITERATIVE", "PIPELINE"], default='ITERATIVE',
                        help='Implementation of the dummy accelerator')

    parser.add_argument('--interleaved', '-i', type=int, default=0,
                        help='Interleave calls to the dummy accel with standard blocks of code')

    parser.add_argument('--interleaved_n_block', '-nib', type=int, default=3,
                        help='Interleave calls to the dummy accel with standard blocks of code')

    parser.add_argument('--consecutive', '-c', type=int, default=0,
                        help='Number of consecutive calls to the dummy accel with standard blocks of code')

    parser.add_argument('--latency', '-l', type=int, default=5,
                        help='Latency of the dummy accelerator')

    parser.add_argument('--n_block_b', '-nb', type=int, default=3,
                        help='Number of instructions after the call to the dummy accel')

    parser.add_argument('--template', '-tp', type=str, default=None,
                        help='Template file')

    parser.add_argument('--bookeep', '-b', type=int, default=0,
                        help='Length of the bookeping function')

    parser.add_argument('--dependent', '-d', action='store_true',
                        help='Dependent concatenation of the dummy accelerator and the bookeeping function')
    
    parser.add_argument('--unroll', '-u', action='store_true',
                        help='Unroll for loop in dummy accelerator calls')

    return parser.parse_args()

def check_args(args) :
    if (args.interleaved > 1 and args.consecutive > 1):
        raise ValueError("Cannot have both interleaved and consecutive calls to the dummy accelerator")
    
    if (args.template is None):
        raise ValueError("No template file provided")
    
    if (args.type_accel not in ["ITERATIVE", "PIPELINE"]):
        raise ValueError("Invalid type of dummy accelerator")


def main(args):
    with open(args.template, 'r') as f:
        template = f.read()

    # Generate the dummy accelerator calls

    # Generate the code for the dummy accelerator
    # dummy_accel_code = mako.template.Template(template).render(dummy_accel_calls=dummy_accel_calls)

    # Generate the code for the BLOCK A
    block_a = ""
    for i in range(int(args.n_block_a)):
        block_a += random.choice([ADD, XOR, SUB])

    # Generate the code for the BLOCK DUMMY
    block_dummy = ""

    if (int(args.consecutive) >= 1):
        if (args.unroll is True):
            for i in range(int(args.consecutive)):
                block_dummy += getDUMMY(args.type_accel, args.latency, False) 
        else:
            block_dummy = "\tfor (int i = 0; i < " + str(args.consecutive) + "; i++) {\n"
            block_dummy += getDUMMY(args.type_accel, args.latency, False)
            block_dummy += "\t}\n"

    elif (int(args.bookeep) >= 1):
        if (args.unroll is True):
            for j in range(int(args.interleaved)):
                block_dummy += getDUMMY(args.type_accel, args.latency, args.dependent) 
                block_dummy += sumDummyAndBookeep()
        else:
            block_dummy = "\tfor (int i = 0; i < " + str(args.interleaved) + "; i++) {\n"
            block_dummy += getDUMMY(args.type_accel, args.latency, args.dependent)
            block_dummy += sumDummyAndBookeep()
            block_dummy += "\t}\n"

    elif (int(args.interleaved) >= 1):
        if (args.unroll is True):
            for j in range(int(args.interleaved)):

                block_dummy += getDUMMY(args.type_accel, args.latency, False) 

                for i in range(int(args.interleaved_n_block)):
                    block_dummy += random.choice([ADD, XOR, SUB])
        else:
            block_dummy = "\tfor (int i = 0; i < " + str(args.interleaved) + "; i++) {\n"
            block_dummy += getDUMMY(args.type_accel, args.latency, args.dependent)
            if (args.dependent is True):
                block_dummy += "\tnew_result = dest_dummy;\n"
            for i in range(int(args.interleaved_n_block)):
                block_dummy += random.choice([ADD, XOR, SUB])
            block_dummy += "\t}\n"

    else:
        block_dummy += getDUMMY(args.type_accel, args.latency)


    block_b = getBlockB(args.n_block_b)


    # Generate the full code
    full_code = Template(template).render(  block_a             = block_a, 
                                            block_dummy         = block_dummy, 
                                            block_b             = block_b,
                                            bookeeping_length   = args.bookeep
                                            )

    with open(args.output, 'w') as f:
        f.write(full_code)

if __name__ == "__main__":
    args = parse_args()

    check_args(args)

    main(args)




