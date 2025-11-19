///////////////////////////////////////////
// regfile_widened.sv
//
// Written: jc165@rice.edu
// Created: 16 November 2025
// Modified:
//
// Purpose: 12-port register file for 4-wide VLIW
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

module regfile_widened #(parameter XLEN, E_SUPPORTED) (
  input  logic             clk, reset,
  input  logic             we3, we6, we9, we12,  // Write enables for ports 3, 6, 9, 12
  input  logic [4:0]       a1, a2, a3,          // FU1: Source registers to read (a1, a2), destination register to write (a3)
  input  logic [4:0]       a4, a5, a6,          // FU2: Source registers to read (a4, a5), destination register to write (a6)
  input  logic [4:0]       a7, a8, a9,          // FU3: Source registers to read (a7, a8), destination register to write (a9)
  input  logic [4:0]       a10, a11, a12,       // FU4: Source registers to read (a10, a11), destination register to write (a12)
  input  logic [XLEN-1:0]  wd3, wd6, wd9, wd12,  // Write data for ports 3, 6, 9, and 12
  
  output logic [XLEN-1:0]  rd1, rd2,            // FU1: Read data for ports 1, 2
  output logic [XLEN-1:0]  rd4, rd5,            // FU2: Read data for ports 4, 5
  output logic [XLEN-1:0]  rd7, rd8,            // FU3: Read data for ports 7, 8
  output logic [XLEN-1:0]  rd10, rd11);         // FU4: Read data for ports 10, 11

  localparam NUMREGS = E_SUPPORTED ? 16 : 32;   // only 16 registers in E mode

  logic [XLEN-1:0] rf[NUMREGS-1:1];
  integer i;

  // Twelve ported register file
  // Read 8 ports combinationally (a1/rd1, a2/rd2, ...... a11/rd11)
  // Write 4 ports on rising edge of clock (a3/wd3/we3, a6/wd6/we6, a9/wd9/we9, a12/wd12/we12)
  // Write occurs on falling edge of clock
  // Register 0 hardwired to 0
  
  // reset is intended for simulation only, not synthesis
  // can logic be adjusted to not need resettable registers?
    
  always_ff @(negedge clk)
    if (reset) for(i=1; i<NUMREGS; i++) rf[i] <= '0;

    // Below is write assign logic
    else begin
      if (we3)                 rf[a3] <= wd3;
      if (we6)                 rf[a6] <= wd6;
      if (we9)                 rf[a9] <= wd9;
      if (we12)                rf[a12] <= wd12;
    end

  // Below is combinationally assigned read logic
  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;

  assign rd4 = (a4 != 0) ? rf[a4] : 0;
  assign rd5 = (a5 != 0) ? rf[a5] : 0;

  assign rd7 = (a7 != 0) ? rf[a7] : 0;
  assign rd8 = (a8 != 0) ? rf[a8] : 0;

  assign rd10 = (a10 != 0) ? rf[a10] : 0;
  assign rd11 = (a11 != 0) ? rf[a11] : 0;

endmodule