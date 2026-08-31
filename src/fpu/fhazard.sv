///////////////////////////////////////////
// fhazard.sv
//
// Written: me@KatherineParry.com 19 May 2021
// Modified: 
//
// Purpose: Determine forwarding, stalls and flushes for the FPU
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

module fhazard(
  input  logic [4:0]  Adr1D, Adr2D, Adr3D,                // read data addresses
  input  logic [4:0]  Adr1E, Adr2E, Adr3E,                // read data addresses
  input  logic        FRegWriteE, FRegWriteM, FRegWriteW, // is the fp register being written to
  input  logic [4:0]  RdE, RdM, RdW,                      // the address being written to
  input  logic        FpLoadStoreM,                       // load/store result is not available on the M-stage forward path
  input  logic        XEnD, YEnD, ZEnD,                   // are the inputs needed
  input  logic        FRegWriteE_1, FRegWriteE_2, FRegWriteE_3,
  input  logic        FRegWriteM_1, FRegWriteM_2, FRegWriteM_3,
  input  logic        FRegWriteW_1, FRegWriteW_2, FRegWriteW_3,
  input  logic        FpLoadStoreM_1, FpLoadStoreM_2, FpLoadStoreM_3,
  input  logic [4:0]  RdE_1, RdE_2, RdE_3,
  input  logic [4:0]  RdM_1, RdM_2, RdM_3,
  input  logic [4:0]  RdW_1, RdW_2, RdW_3,
  output logic        FPUStallD,                          // stall the decode stage
  output logic [1:0]  ForwardXE, ForwardYE, ForwardZE,    // select a forwarded value
  output logic [1:0]  ForwardLaneXE, ForwardLaneYE, ForwardLaneZE
);

  logic MatchDE_0, MatchDE_1, MatchDE_2, MatchDE_3;
  logic MatchDE;

  assign MatchDE_0 = FRegWriteE   & (((Adr1D == RdE)   & XEnD) | ((Adr2D == RdE)   & YEnD) | ((Adr3D == RdE)   & ZEnD));
  assign MatchDE_1 = FRegWriteE_1 & (((Adr1D == RdE_1) & XEnD) | ((Adr2D == RdE_1) & YEnD) | ((Adr3D == RdE_1) & ZEnD));
  assign MatchDE_2 = FRegWriteE_2 & (((Adr1D == RdE_2) & XEnD) | ((Adr2D == RdE_2) & YEnD) | ((Adr3D == RdE_2) & ZEnD));
  assign MatchDE_3 = FRegWriteE_3 & (((Adr1D == RdE_3) & XEnD) | ((Adr2D == RdE_3) & YEnD) | ((Adr3D == RdE_3) & ZEnD));
  assign MatchDE = MatchDE_0 | MatchDE_1 | MatchDE_2 | MatchDE_3;
  assign FPUStallD = MatchDE;
  
  always_comb begin
    // set defaults
    ForwardXE = 2'b00; // choose FRD1E
    ForwardYE = 2'b00; // choose FRD2E
    ForwardZE = 2'b00; // choose FRD3E
    ForwardLaneXE = 2'b00;
    ForwardLaneYE = 2'b00;
    ForwardLaneZE = 2'b00;

    // if the needed value is in the memory stage - input 1
    if ((Adr1E == RdM) & FRegWriteM & ~FpLoadStoreM) begin
      ForwardXE = 2'b10;
    end else if ((Adr1E == RdM_1) & FRegWriteM_1 & ~FpLoadStoreM_1) begin
      ForwardXE = 2'b10;
      ForwardLaneXE = 2'b01;
    end else if ((Adr1E == RdM_2) & FRegWriteM_2 & ~FpLoadStoreM_2) begin
      ForwardXE = 2'b10;
      ForwardLaneXE = 2'b10;
    end else if ((Adr1E == RdM_3) & FRegWriteM_3 & ~FpLoadStoreM_3) begin
      ForwardXE = 2'b10;
      ForwardLaneXE = 2'b11;
    end else if ((Adr1E == RdW) & FRegWriteW) begin
      ForwardXE = 2'b01;
    end else if ((Adr1E == RdW_1) & FRegWriteW_1) begin
      ForwardXE = 2'b01;
      ForwardLaneXE = 2'b01;
    end else if ((Adr1E == RdW_2) & FRegWriteW_2) begin
      ForwardXE = 2'b01;
      ForwardLaneXE = 2'b10;
    end else if ((Adr1E == RdW_3) & FRegWriteW_3) begin
      ForwardXE = 2'b01;
      ForwardLaneXE = 2'b11;
    end
  
    // if the needed value is in the memory stage - input 2
    if ((Adr2E == RdM) & FRegWriteM & ~FpLoadStoreM) begin
      ForwardYE = 2'b10;
    end else if ((Adr2E == RdM_1) & FRegWriteM_1 & ~FpLoadStoreM_1) begin
      ForwardYE = 2'b10;
      ForwardLaneYE = 2'b01;
    end else if ((Adr2E == RdM_2) & FRegWriteM_2 & ~FpLoadStoreM_2) begin
      ForwardYE = 2'b10;
      ForwardLaneYE = 2'b10;
    end else if ((Adr2E == RdM_3) & FRegWriteM_3 & ~FpLoadStoreM_3) begin
      ForwardYE = 2'b10;
      ForwardLaneYE = 2'b11;
    end else if ((Adr2E == RdW) & FRegWriteW) begin
      ForwardYE = 2'b01;
    end else if ((Adr2E == RdW_1) & FRegWriteW_1) begin
      ForwardYE = 2'b01;
      ForwardLaneYE = 2'b01;
    end else if ((Adr2E == RdW_2) & FRegWriteW_2) begin
      ForwardYE = 2'b01;
      ForwardLaneYE = 2'b10;
    end else if ((Adr2E == RdW_3) & FRegWriteW_3) begin
      ForwardYE = 2'b01;
      ForwardLaneYE = 2'b11;
    end

    // if the needed value is in the memory stage - input 3
    if ((Adr3E == RdM) & FRegWriteM & ~FpLoadStoreM) begin
      ForwardZE = 2'b10;
    end else if ((Adr3E == RdM_1) & FRegWriteM_1 & ~FpLoadStoreM_1) begin
      ForwardZE = 2'b10;
      ForwardLaneZE = 2'b01;
    end else if ((Adr3E == RdM_2) & FRegWriteM_2 & ~FpLoadStoreM_2) begin
      ForwardZE = 2'b10;
      ForwardLaneZE = 2'b10;
    end else if ((Adr3E == RdM_3) & FRegWriteM_3 & ~FpLoadStoreM_3) begin
      ForwardZE = 2'b10;
      ForwardLaneZE = 2'b11;
    end else if ((Adr3E == RdW) & FRegWriteW) begin
      ForwardZE = 2'b01;
    end else if ((Adr3E == RdW_1) & FRegWriteW_1) begin
      ForwardZE = 2'b01;
      ForwardLaneZE = 2'b01;
    end else if ((Adr3E == RdW_2) & FRegWriteW_2) begin
      ForwardZE = 2'b01;
      ForwardLaneZE = 2'b10;
    end else if ((Adr3E == RdW_3) & FRegWriteW_3) begin
      ForwardZE = 2'b01;
      ForwardLaneZE = 2'b11;
    end
  end 
endmodule
