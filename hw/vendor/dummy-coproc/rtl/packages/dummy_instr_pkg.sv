// Copyright 2024 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: dummy_instr_pkg.sv
// Author: Michele Caon
// Date: 22/05/2024
// Description: Instruction definitions for the dummy coprocessor

package dummy_instr_pkg;
  // Instruction length
  localparam int unsigned ILEN = 32'd32;

  // RISC-V I-type instruction
  typedef struct packed {
    logic [31:20] imm11;
    logic [19:15] rs1;
    logic [14:12] funct3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
  } instr_i_t;

  // Instruction union
  typedef union packed {
    instr_i_t       i;
    logic [ILEN-1:0]  raw;
  } instr_t;

  // Instruction encoding
  localparam logic [31:0] XDUMMY_ITER = 32'b?????????????????000?????1110111;
  localparam logic [31:0] XDUMMY_PIPE = 32'b?????????????????000?????1011011;
endpackage
