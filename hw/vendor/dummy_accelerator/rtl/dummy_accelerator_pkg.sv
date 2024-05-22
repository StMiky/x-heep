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

  // type definition
  typedef logic [ImmWidth-1:0] conf_type_t;

  typedef enum logic [EuCtlLen-1:0] {
    EU_CTL_PIPELINE,
    EU_CTL_ITERATIVE
  } ctl_type_t;

  typedef struct packed {
    logic [XIdWidth-1:0] id;
    logic [AddrWidth-1:0]  rd_idx;
  } tag_type_t;


  // architecture specific parameters
  // TODO: in len5 map to the external package values
  localparam int unsigned ImmWidth = 32'd12;
  localparam int unsigned EuCtlLen = 32'd1;
  localparam int unsigned AddrWidth = 32'd5;
  localparam int unsigned XLEN = 32'd32;
  localparam int unsigned MaxPipeLength = 32'd100;


  // X-IF parameters
  localparam int unsigned XNumRs = 32'd2;
  localparam int unsigned XIdWidth = 32'd4;
  localparam int unsigned XMemWidth = XLEN;
  localparam int unsigned XRfrWidth = XLEN;
  localparam int unsigned XRfwWidth = XLEN;
  localparam int unsigned XMisa = 0;

  // Instructions encoding, not needed in Len5 (instr_pkg.sv contains them)
  localparam logic [31:0] DummyIterative = 32'b?????????????????000?????1110111;
  localparam logic [31:0] DummyPipeline = 32'b?????????????????000?????1011011;
endpackage
