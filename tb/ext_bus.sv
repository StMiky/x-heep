// Copyright 2022 EPFL and Politecnico di Torino.
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// File: ext_bus.sv
// Author: Michele Caon
// Date: 19/05/2023
// Description: external peripheral bus for X-HEEP testbench

module ext_bus #(
    parameter int unsigned EXT_XBAR_NMASTER = 1,
    parameter int unsigned EXT_XBAR_NSLAVE = 1,
    // Dependent parameters: do not override
    localparam int unsigned ExtXbarNmasterRnd = EXT_XBAR_NMASTER == 0 ? 1 : EXT_XBAR_NMASTER,
    localparam int unsigned ExtXbarNslaveRnd = EXT_XBAR_NSLAVE == 0 ? 1 : EXT_XBAR_NSLAVE,
    localparam int unsigned IdxWidth = cf_math_pkg::idx_width(EXT_XBAR_NSLAVE)
) (
    input logic clk_i,
    input logic rst_ni,

    // Address map
    input addr_map_rule_pkg::addr_map_rule_t [EXT_XBAR_NSLAVE-1:0] addr_map_i,

    // Default external slave index
    input logic [IdxWidth-1:0] default_idx_i,

    // X-HEEP master ports
    input  obi_pkg::obi_req_t  heep_core_instr_req_i,
    output obi_pkg::obi_resp_t heep_core_instr_resp_o,

    input  obi_pkg::obi_req_t  heep_core_data_req_i,
    output obi_pkg::obi_resp_t heep_core_data_resp_o,

    input  obi_pkg::obi_req_t  heep_debug_master_req_i,
    output obi_pkg::obi_resp_t heep_debug_master_resp_o,

    input  obi_pkg::obi_req_t  heep_dma_master0_ch0_req_i,
    output obi_pkg::obi_resp_t heep_dma_master0_ch0_resp_o,

    input  obi_pkg::obi_req_t  heep_dma_master1_ch0_req_i,
    output obi_pkg::obi_resp_t heep_dma_master1_ch0_resp_o,

    // External master ports
    input  obi_pkg::obi_req_t  [ExtXbarNmasterRnd-1:0] ext_master_req_i,
    output obi_pkg::obi_resp_t [ExtXbarNmasterRnd-1:0] ext_master_resp_o,

    // X-HEEP slave ports (one per external master)
    output obi_pkg::obi_req_t  [ExtXbarNmasterRnd-1:0] heep_slave_req_o,
    input  obi_pkg::obi_resp_t [ExtXbarNmasterRnd-1:0] heep_slave_resp_i,

    // External slave ports
    output obi_pkg::obi_req_t  [ExtXbarNslaveRnd-1:0] ext_slave_req_o,
    input  obi_pkg::obi_resp_t [ExtXbarNslaveRnd-1:0] ext_slave_resp_i
);
  import obi_pkg::*;
  import addr_map_rule_pkg::*;
  import core_v_mini_mcu_pkg::*;

  // X-HEEP + external master ports
  obi_req_t [core_v_mini_mcu_pkg::SYSTEM_XBAR_NMASTER+EXT_XBAR_NMASTER-1:0] master_req;
  obi_resp_t [core_v_mini_mcu_pkg::SYSTEM_XBAR_NMASTER+EXT_XBAR_NMASTER-1:0] master_resp;

  // Forward crossbars ports
  obi_req_t [EXT_XBAR_NMASTER-1:0][1:0] fwd_xbar_req;
  obi_resp_t [EXT_XBAR_NMASTER-1:0][1:0] fwd_xbar_resp;

  // Dummy external master portp (to prevent unused warning)
  obi_req_t [ExtXbarNmasterRnd-1:0] ext_master_req_unused;
  obi_resp_t [ExtXbarNmasterRnd-1:0] heep_slave_resp_unused;
  obi_resp_t [ExtXbarNslaveRnd-1:0] ext_slave_resp_unused;

  assign ext_master_req_unused = ext_master_req_i;
  assign heep_slave_resp_unused = heep_slave_resp_i;
  assign ext_slave_resp_unused = ext_slave_resp_i;

  // X-HEEP + external master requests
  assign master_req[CORE_INSTR_IDX] = heep_core_instr_req_i;
  assign master_req[CORE_DATA_IDX] = heep_core_data_req_i;
  assign master_req[DEBUG_MASTER_IDX] = heep_debug_master_req_i;
  assign master_req[DMA_MASTER0_CH0_IDX] = heep_dma_master0_ch0_req_i;
  assign master_req[DMA_MASTER1_CH0_IDX] = heep_dma_master1_ch0_req_i;
  generate
    for (genvar i = 0; i < EXT_XBAR_NMASTER; i++) begin : gen_ext_master_req_map
      assign master_req[SYSTEM_XBAR_NMASTER+i] = fwd_xbar_req[i][FWD_XBAR_EXT_SLAVE_IDX];
    end
  endgenerate

  // X-HEEP master responses
  assign heep_core_instr_resp_o = master_resp[CORE_INSTR_IDX];
  assign heep_core_data_resp_o = master_resp[CORE_DATA_IDX];
  assign heep_debug_master_resp_o = master_resp[DEBUG_MASTER_IDX];
  assign heep_dma_master0_ch0_resp_o = master_resp[DMA_MASTER0_CH0_IDX];
  assign heep_dma_master1_ch0_resp_o = master_resp[DMA_MASTER1_CH0_IDX];


  // X-HEEP slave requests
  generate
    for (genvar i = 0; i < EXT_XBAR_NMASTER; i++) begin
      assign heep_slave_req_o[i] = fwd_xbar_req[i][FWD_XBAR_INT_SLAVE_IDX];
    end
  endgenerate

  // X-HEEP slave responses
  generate
    for (genvar i = 0; unsigned'(i) < EXT_XBAR_NMASTER; i++) begin
      assign fwd_xbar_resp[i][FWD_XBAR_INT_SLAVE_IDX] = heep_slave_resp_i[i];
    end
  endgenerate

  // External slave responses
  generate
    for (genvar i = 0; unsigned'(i) < EXT_XBAR_NMASTER; i++) begin : gen_fwd_master_resp_map
      assign fwd_xbar_resp[i][FWD_XBAR_EXT_SLAVE_IDX] = master_resp[SYSTEM_XBAR_NMASTER+i];
    end
  endgenerate

`ifndef SYNTHESIS
  // show writes if requested
  always_ff @(posedge clk_i, negedge rst_ni) begin : verbose_writes
    if ($test$plusargs("verbose") != 0 && heep_core_data_req_i.req && heep_core_data_req_i.we)
      $display(
          "write addr=0x%08x: data=0x%08x", heep_core_data_req_i.addr, heep_core_data_req_i.wdata
      );
  end
`endif

  // 1-to-2 forward crossbars
  // ------------------------
  // These crossbars forward each external master to a port on the external
  // crossbar or to the corresponding slave port of X-HEEP.
  generate
    for (genvar i = 0; unsigned'(i) < EXT_XBAR_NMASTER; i++) begin : gen_fwd_xbar
      xbar_varlat_one_to_n #(
          .XBAR_NSLAVE(32'd2),  // internal crossbar + external crossbar
          .NUM_RULES  (32'd1)   // only the external address space is defined
      ) fwd_xbar_i (
          .clk_i        (clk_i),
          .rst_ni       (rst_ni),
          .addr_map_i   (FWD_XBAR_ADDR_RULES),
          .default_idx_i(FWD_XBAR_INT_SLAVE_IDX[0:0]),
          .master_req_i (ext_master_req_i[i]),
          .master_resp_o(ext_master_resp_o[i]),
          .slave_req_o  (fwd_xbar_req[i]),
          .slave_resp_i (fwd_xbar_resp[i])
      );
    end
  endgenerate

  // External system crossbar
  // ------------------------
  ext_xbar #(
      .XBAR_NMASTER(SYSTEM_XBAR_NMASTER + EXT_XBAR_NMASTER),
      .XBAR_NSLAVE (EXT_XBAR_NSLAVE)
  ) ext_xbar_i (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .addr_map_i(addr_map_i),
      .default_idx_i(default_idx_i),
      .master_req_i(master_req),
      .master_resp_o(master_resp),
      .slave_req_o(ext_slave_req_o),
      .slave_resp_i(ext_slave_resp_i)
  );

endmodule
