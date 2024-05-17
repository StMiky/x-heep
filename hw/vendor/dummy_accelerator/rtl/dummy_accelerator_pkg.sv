/// Copyright 2024 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: dummy_accelerator_pkg.sv
// Author: Flavia Guella
// Date: 17/05/2024


package dummy_accelerator_pkg;

// architecture specific parameters
// TODO: in len5 map to the external package values
localparam int unsigned IMM_WIDTH = 12;
localparam int unsigned OPCODE_SIZE = 7;
localparam int unsigned FUNC3 = 3;
localparam int unsigned ADDR_WIDTH = 5;
localparam int unsigned XLEN = 32;

// X-IF parameters
localparam int unsigned X_NUM_RS = 2;
localparam int unsigned X_ID_WIDTH = 4;
localparam int unsigned X_MEM_WIDTH = XLEN;
localparam int unsigned X_RFR_WIDTH = XLEN;
localparam int unsigned X_RFW_WIDTH = XLEN;
localparam int unsigned X_MISA = 0;



localparam logic [OPCODE_SIZE-1:0] DUMMY_INSTR_OPCODE = 7'b1110111;
localparam logic [FUNC3-1:0] DUMMY_INSTR_FUNC3 = 3'b000;
// type definition
typedef logic [IMM_WIDTH-1:0] CtlType;

typedef struct packed {
    logic [X_ID_WIDTH-1:0]      id;
    logic [ADDR_WIDTH-1:0]      rd_idx;
} TagType;



endpackage
