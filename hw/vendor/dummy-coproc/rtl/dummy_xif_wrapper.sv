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
// File: dummy_xif_wrapper.sv
// Author: Michele Caon
// Date: 22/05/2024
// Description: Dummy coprocessor wrapper for the CORE-V eXtension interface

module dummy_xif_wrapper #(
  parameter int unsigned DATA_WIDTH = 32'd32,
  parameter int unsigned MAX_LATENCY = 32'd32,  // power of 2
  parameter int unsigned MAX_PIPE_DEPTH = 32'd32,
  parameter int unsigned XIF_ID_WIDTH = 32'd1
) (
  input logic       clk_i,
  input logic       rst_ni,

  // CORE-V eXtension Interface
  if_xif.coproc_compressed xif_compressed,  // compressed instr. interface
  if_xif.coproc_issue      xif_issue,       // issue interface
  if_xif.coproc_commit     xif_commit,      // commit interface
  if_xif.coproc_mem        xif_mem,         // memory interface (unused)
  if_xif.coproc_mem_result xif_mem_result,  // memory result interface (unused)
  if_xif.coproc_result     xif_result       // result interface
);
  import dummy_pkg::*;
  import dummy_instr_pkg::*;

  // INTERNAL SIGNALS
  // ----------------
  // Auxiliary information to be propagated
  typedef struct packed {
    logic [XIF_ID_WIDTH-1:0] xif_id; // XIF instruction ID
    logic [4:0]              rd_idx; // destination register index
  } tag_t;
  tag_t xif_coproc_tag, coproc_xif_tag;

  // XIF <--> coprocessor
  logic                  xif_coproc_valid;
  logic                  xif_coproc_ready;
  logic                  xif_coproc_flush;
  instr_t                xif_coproc_instr;
  coproc_ctl_t           xif_coproc_ctl;
  logic [DATA_WIDTH-1:0] xif_coproc_rs1;
  logic [DATA_WIDTH-1:0] xif_coproc_rs2;
  logic                  coproc_xif_valid;
  logic                  coproc_xif_ready;
  logic                  coproc_xif_accept;
  logic [DATA_WIDTH-1:0] coproc_xif_result;
  logic                  coproc_dec_ready;
  logic                  coproc_op_ready;

  // -------------------
  // INSTRUCTION DECODER
  // -------------------
  // Operands ready
  assign coproc_op_ready = xif_issue.issue_req.rs_valid[0] & xif_issue.issue_req.rs_valid[1];

  // Decode opcode
  assign xif_coproc_instr.raw = xif_issue.issue_req.instr;
  always_comb begin : instr_dec
    // Default values
    xif_coproc_valid  = 1'b0;
    xif_coproc_ctl    = MODE_ITER;
    coproc_xif_accept = 1'b0;
    coproc_xif_ready  = 1'b1; // ready by default, but accept only valid instructions

    unique casez (xif_coproc_instr.raw)
      XDUMMY_ITER, XDUMMY_PIPE: begin
        xif_coproc_ctl    = (xif_coproc_instr.raw === XDUMMY_ITER) ? MODE_ITER : MODE_PIPE;
        coproc_xif_accept = 1'b1;
        xif_coproc_valid  = xif_issue.issue_valid & coproc_op_ready;
        coproc_xif_ready  = coproc_dec_ready & coproc_op_ready;
      end
      default: ; // use default values
    endcase
  end

  // -----------------
  // DUMMY COPROCESSOR
  // -----------------
  // XIF input bridge
  assign xif_coproc_ready = xif_result.result_ready;
  // TODO: this kills all the instructions in the coprocessor in case of kill
  // request. In other words, the XIF ID is ignored. This is not compliant and
  // should be addressed. Currently, the coprocessor pipeline does not support
  // per-instruction flushing.
  assign xif_coproc_flush = xif_commit.commit_valid & xif_commit.commit.commit_kill;
  assign xif_coproc_tag.xif_id = xif_issue.issue_req.id;
  assign xif_coproc_tag.rd_idx = xif_coproc_instr.i.rd;
  assign xif_coproc_rs1 = xif_issue.issue_req.rs[0];
  assign xif_coproc_rs2 = xif_issue.issue_req.rs[1];

  // Coprocessor interface
  dummy_top #(
    .DATA_WIDTH    (DATA_WIDTH),
    .MAX_LATENCY   (MAX_LATENCY),
    .MAX_PIPE_DEPTH(MAX_PIPE_DEPTH),
    .tag_t         (tag_t)
  ) u_dummy_top (
    .clk_i   (clk_i   ),
    .rst_ni  (rst_ni  ),
    .flush_i (xif_coproc_flush),
    .valid_i (xif_coproc_valid),
    .ready_o (coproc_dec_ready),
    .ctl_i   (xif_coproc_ctl),
    .tag_i   (xif_coproc_tag),
    .rs1_i   (xif_coproc_rs1),
    .rs2_i   (xif_coproc_rs2),
    .valid_o (coproc_xif_valid),
    .ready_i (xif_coproc_ready),
    .tag_o   (coproc_xif_tag),
    .rd_o    (coproc_xif_result)
  );

  // ------------------
  // OUTPUT ASSIGNEMENT
  // ------------------

  // XIF interface
  // -------------
  // Compressed interface (no compressed instructions implemented)
  assign xif_compressed.compressed_ready        = 1'b1;
  assign xif_compressed.compressed_resp.instr   = '0;
  assign xif_compressed.compressed_resp.accept  = 1'b0;

  // Issue interface response
  assign xif_issue.issue_ready                  = coproc_xif_ready;
  assign xif_issue.issue_resp.accept            = coproc_xif_accept;
  assign xif_issue.issue_resp.writeback         = 1'b1; // always write back data to RF
  assign xif_issue.issue_resp.dualwrite         = 1'b0; // no dual writeback
  assign xif_issue.issue_resp.dualread          = '0;   // no dual read
  assign xif_issue.issue_resp.loadstore         = 1'b0; // no load/store
  assign xif_issue.issue_resp.ecswrite          = 1'b0; // no write to CSR
  assign xif_issue.issue_resp.exc               = 1'b0; // no exception can be triggered

  // Result interface response
  assign xif_result.result_valid         = coproc_xif_valid;
  assign xif_result.result.we            = 1'b1; // always write back data to RF
  assign xif_result.result.exc           = 1'b0; // no exception can be triggered
  assign xif_result.result.id            = coproc_xif_tag.xif_id;
  assign xif_result.result.data          = coproc_xif_result;
  assign xif_result.result.rd            = coproc_xif_tag.rd_idx;
  assign xif_result.result.ecsdata       = '0; // no data to write to CSR
  assign xif_result.result.ecswe         = '0;  // no write to CSR
  assign xif_result.result.exccode       = 6'h2; // Illegal instruction (unknown opcode)
  assign xif_result.result.err           = 1'b0; // no bus errors (no load/store)
  assign xif_result.result.dbg           = 1'b0; // no debug events triggered

  // Memory interface request (unused)
  assign xif_mem.mem_valid     = 1'b0;
  assign xif_mem.mem_req.id    = '0;
  assign xif_mem.mem_req.addr  = '0;
  assign xif_mem.mem_req.mode  = '0;
  assign xif_mem.mem_req.we    = 1'b0;
  assign xif_mem.mem_req.size  = '0;
  assign xif_mem.mem_req.be    = '0;
  assign xif_mem.mem_req.attr  = '0;
  assign xif_mem.mem_req.wdata = '0;
  assign xif_mem.mem_req.last  = 1'b0;
  assign xif_mem.mem_req.spec  = 1'b0;
endmodule
