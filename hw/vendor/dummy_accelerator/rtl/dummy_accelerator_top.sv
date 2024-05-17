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
// File: dummy_accelerator_top.sv
// Author: Flavia Guella
// Date: 16/05/2024

module dummy_accelerator_top #(
    parameter int unsigned      WIDTH = 32,
    parameter int unsigned      IMM_WIDTH = 11,
    parameter type              CtlType = logic [IMM_WIDTH-1:0],
    parameter type              TagType = logic
) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic                    flush_i,
    // signals from/to upstream hw
    input logic                     valid_i,
    output logic                    ready_o,
    // signals from/to downstream hw
    input logic                     ready_i,
    output logic                    valid_o,
    // input data
    input  logic    [WIDTH-1:0]     rs1_value_i,
    input  logic    [IMM_WIDTH-1:0] imm_i,
    //input CtlType                   ctl_i,
    input TagType                   tag_i,  // in case of x-if contains both rd and id
    // output data
    output logic    [WIDTH-1:0]     result_o,
    output TagType                  tag_o
);
  

logic [WIDTH-1:0] result_d, result_q;
// control unit <--> counter
logic clr_cnt, en_cnt, tc;
logic [IMM_WIDTH-1:0] count, tc_value;
// cotrol unit <--> output reg
logic out_reg_en, out_reg_sel; // enable out sampling, out mux control
TagType tag_d, tag_q;

// the datapath is a simple operation that is performed when a start signal arrives from CU
// the cu is a fsm which controls the datapath, and is able to go into a wait state which lasts N_CYCLES
// N_cycles is the number of cycles the accelerator has to wait before sending the result back to the processor
// the accelerator ony gives the valid signal after N_CYCLES cycles (>=!)

//////////////////   
// Control Unit //
//////////////////
dummy_accelerator_cu #(
    .CtlType    (CtlType)
) u_dummy_acc_cu(
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),
    .flush_i            (flush_i),
    .ctl_i              (imm_i),    // dummy ctl signal (insert for possible future uses)
    .tc_i               (tc),  
    .valid_i            (valid_i),
    .ready_o            (ready_o),
    .ready_i            (ready_i),
    .valid_o            (valid_o),
    .out_buff_en_o      (out_reg_en),    // TODO: check whether needed
    .buff_out_sel_o     (out_reg_sel),
    .clr_cnt_o          (clr_cnt),
    .en_cnt_o           (en_cnt)
);

//////////////////
// Up Counter //
//////////////////
updown_counter #(
  .WIDTH    (IMM_WIDTH)
) u_updown_counter (
    .clk_i          (clk_i),
    .rst_ni         (rst_ni), 
    .en_i           (en_cnt),   
    .clr_i          (clr_cnt),  
    .dn_i           (1'b0),   
    .ld_i           (1'b0),    
    .ld_val_i       (),
    .count_o        (count),
    .tc_o           ()
);

// Send end of computation signal to CU when count=imm_i
assign tc_value = imm_i;   // CHECK manage cases imm_i<2
assign tc = (count == tc_value) ? 1'b1 : 1'b0;

//////////////
// Datapath //
//////////////

// very complex cryptographic operation
assign result_d = rs1_value_i ^ {{WIDTH-IMM_WIDTH{1'b0}}, imm_i};

// Output register
always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        result_q <= '0;
    end else if (flush_i) begin
        result_q <= '0;
    end else if (out_reg_en) begin
        result_q <= result_d;
    end
end

// Tag register
assign tag_d = tag_i;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        tag_q <= '0;
    end else if (flush_i) begin
        tag_q <= '0;
    end else if (out_reg_en) begin
        tag_q <= tag_d;
    end
end


// Output assignment
assign result_o = (out_reg_sel) ? result_q : result_d;
assign tag_o = (out_reg_sel) ? tag_q : tag_d;

endmodule
