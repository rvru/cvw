///////////////////////////////////////////
// fregfile_widened.sv
//
// Written: OpenAI Codex
// Modified:
//
// Purpose: 12R4W floating-point register file for 4-wide VLIW
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module fregfile_widened #(parameter FLEN) (
  input  logic             clk, reset,
  input  logic             we0, we1, we2, we3,
  input  logic [4:0]       ra1_0, ra2_0, ra3_0, wa_0,
  input  logic [4:0]       ra1_1, ra2_1, ra3_1, wa_1,
  input  logic [4:0]       ra1_2, ra2_2, ra3_2, wa_2,
  input  logic [4:0]       ra1_3, ra2_3, ra3_3, wa_3,
  input  logic [FLEN-1:0]  wd_0, wd_1, wd_2, wd_3,
  output logic [FLEN-1:0]  rd1_0, rd2_0, rd3_0,
  output logic [FLEN-1:0]  rd1_1, rd2_1, rd3_1,
  output logic [FLEN-1:0]  rd1_2, rd2_2, rd3_2,
  output logic [FLEN-1:0]  rd1_3, rd2_3, rd3_3
);

  logic [FLEN-1:0] rf[31:0];
  integer i;

  always_ff @(negedge clk)
    if (reset) begin
      for (i = 0; i < 32; i++) rf[i] <= '0;
    end else begin
      if (we0) rf[wa_0] <= wd_0;
      if (we1) rf[wa_1] <= wd_1;
      if (we2) rf[wa_2] <= wd_2;
      if (we3) rf[wa_3] <= wd_3;
    end

  assign rd1_0 = rf[ra1_0];
  assign rd2_0 = rf[ra2_0];
  assign rd3_0 = rf[ra3_0];

  assign rd1_1 = rf[ra1_1];
  assign rd2_1 = rf[ra2_1];
  assign rd3_1 = rf[ra3_1];

  assign rd1_2 = rf[ra1_2];
  assign rd2_2 = rf[ra2_2];
  assign rd3_2 = rf[ra3_2];

  assign rd1_3 = rf[ra1_3];
  assign rd2_3 = rf[ra2_3];
  assign rd3_3 = rf[ra3_3];

endmodule
