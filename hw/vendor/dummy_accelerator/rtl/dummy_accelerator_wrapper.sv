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
// File: dummy_accelerator_wrapper.sv
// Author: Flavia Guella
// Date: 17/05/2024

module dummy_accelerator_wrapper #(
    parameter int unsigned      WIDTH = 32,
    parameter int unsigned      IMM_WIDTH = dummy_accelerator_pkg::IMM_WIDTH,
    parameter type             CtlType = dummy_accelerator_pkg::CtlType,
    parameter type             TagType = dummy_accelerator_pkg::TagType,
    parameter logic [dummy_accelerator_pkg::OPCODE_SIZE-1:0] DUMMY_INSTR_OPCODE = 7'b1110111,
    parameter logic [dummy_accelerator_pkg::FUNC3-1:0] DUMMY_INSTR_FUNC3 = 3'b000
) (
    input logic              clk_i,
    input logic              rst_ni,   
    // CORE-V eXtension Interface (optional memory interfaces not required)
    if_xif.coproc_issue      xif_issue_if,       // issue interface
    if_xif.coproc_commit     xif_commit_if,      // commit interface
    if_xif.coproc_result     xif_result_if      // result interface
);



// XIF-issue <--> coproc
logic valid_instr;
logic cpu_copr_valid, copr_cpu_ready;
logic [WIDTH-1:0] rs1_value;
logic [IMM_WIDTH-1:0] imm_value;
TagType issue_copr_tag;

// XIF-result <--> coproc
logic copr_cpu_valid, cpu_copr_ready;
TagType copr_result_tag;
logic [WIDTH-1:0] copr_result;

// XIF-commit <--> coproc
logic copr_flush;


// X-IF issue signals mapping
// Decode instruction and accept. issue_resp signals
assign valid_instr = (xif_issue_if.issue_req.instr[dummy_accelerator_pkg::OPCODE_SIZE-1:0] == DUMMY_INSTR_OPCODE && xif_issue_if.issue_req.instr[15:13] == DUMMY_INSTR_FUNC3) ? 1'b1 : 1'b0; //check it works 
assign xif_issue_if.issue_resp.accept = valid_instr; // TODO: check if required && copr_cpu_ready;
assign xif_issue_if.issue_ready = copr_cpu_ready;
assign xif_issue_if.issue_resp.writeback = 1'b1;
// Issue req signals. valid input is issue_valid and input operands valid
assign cpu_copr_valid = xif_issue_if.issue_valid && xif_issue_if.issue_req.rs_valid[0];
assign rs1_value = xif_issue_if.issue_req.rs[0];
assign imm_value = xif_issue_if.issue_req.instr[32-1:32-IMM_WIDTH]; //TODO: check if need subset or extension
assign issue_copr_tag.id = xif_issue_if.issue_req.id;

assign issue_copr_tag.rd_idx = xif_issue_if.issue_req.instr[12:8];
// leave unassigned tag_i.rd_idx

// X-IF result signals mapping
assign xif_result_if.result_valid = copr_cpu_valid;
assign cpu_copr_ready = xif_result_if.result_ready;
assign xif_result_if.result.id = copr_result_tag.id;
assign xif_result_if.result.rd = copr_result_tag.rd_idx;
assign xif_result_if.result.we = copr_cpu_valid;
assign xif_result_if.result.data = copr_result;

// X-IF commit signals mapping
assign copr_flush = xif_commit_if.commit.commit_kill && xif_commit_if.commit_valid; // if valid and kill, then kill instr in flight
// ignore xif_commit_if.commit.id carries 
// not necessary for this simple arch to check xif_commit_if.commit.id = tag of instr in flight, as only one instr is in flight

// Top-level accelerator module
dummy_accelerator_top #(
    .WIDTH(WIDTH),
    .IMM_WIDTH(IMM_WIDTH),
    .CtlType(CtlType),
    .TagType(TagType)
) u_dummy_accelerator_top (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni),
    .flush_i        (copr_flush),
    .valid_i        (cpu_copr_valid),
    .ready_o        (copr_cpu_ready),
    .ready_i        (cpu_copr_ready),
    .valid_o        (copr_cpu_valid),
    .rs1_value_i    (rs1_value),
    .imm_i          (imm_value),
    .tag_i          (issue_copr_tag),
    .result_o       (copr_result),
    .tag_o          (copr_result_tag)
);

endmodule
