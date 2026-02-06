///////////////////////////////////////////
// ieu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: jc165@rice.edu 28 January 2026
//
// Purpose: Integer Execution Unit: datapath and controller
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

module ieu import cvw::*;  #(parameter cvw_t P) (
  input  logic              clk, reset,
  // Decode stage signals
  input  logic [31:0]       InstrD,                          // Instruction
  input  logic [1:0]        STATUS_FS,                       // is FPU enabled?
  input  logic [3:0]        ENVCFG_CBE,                      // Cache block operation enables
  input  logic              IllegalIEUFPUInstrD,             // Illegal instruction
  output logic              IllegalBaseInstrD,               // Illegal I-type instruction, or illegal RV32 access to upper 16 registers
  // Execute stage signals
  input  logic [P.XLEN-1:0] PCE,                             // PC
  input  logic [P.XLEN-1:0] PCLinkE,                         // PC + 4
  output logic              PCSrcE,                          // Select next PC (between PC+4 and IEUAdrE)
  input  logic              FWriteIntE, FCvtIntE,            // FPU writes to integer register file, FPU converts float to int
  output logic [P.XLEN-1:0] IEUAdrE,                         // Memory address
  output logic              IntDivE, W64E,                   // Integer divide, RV64 W-type instruction 
  output logic [2:0]        Funct3E,                         // Funct3 instruction field
  output logic [P.XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE,  // ALU src inputs before the mux choosing between them and PCE to put in srcA/B
  output logic [4:0]        RdE,                             // Destination register
  output logic              MDUActiveE,                      // Mul/Div instruction being executed
  output logic [3:0]        CMOpM,                           // 1: cbo.inval; 2: cbo.flush; 4: cbo.clean; 8: cbo.zero
  output logic              IFUPrefetchE,                    // instruction prefetch
  output logic              LSUPrefetchM,                    // datata prefetch
  // Memory stage signals
  input  logic              SquashSCW,                       // Squash store conditional, from LSU
  output logic [1:0]        MemRWE,                          // Read/write control goes to LSU
  output logic [1:0]        MemRWM,                          // Read/write control goes to LSU
  output logic [1:0]        AtomicM,                         // Atomic control goes to LSU
  output logic [P.XLEN-1:0] WriteDataM,                      // Write data to LSU
  output logic [2:0]        Funct3M,                         // Funct3 (size and signedness) to LSU
  output logic [P.XLEN-1:0] SrcAM,                           // ALU SrcA to Privileged unit and FPU
  output logic [4:0]        RdM,                             // Destination register
  input  logic [P.XLEN-1:0] FIntResM,                        // Integer result from FPU (fmv, fclass, fcmp)
  output logic              InvalidateICacheM, FlushDCacheM, // Invalidate I$, flush D$
  output logic              InstrValidD, InstrValidE, InstrValidM, // Instruction is valid
  output logic              BranchD, BranchE,
  output logic              JumpD, JumpE,
  // Writeback stage signals
  input  logic [P.XLEN-1:0] FIntDivResultW,                  // Integer divide result from FPU fdivsqrt)
  input  logic [P.XLEN-1:0] CSRReadValW,                     // CSR read value, 
  input  logic [P.XLEN-1:0] MDUResultW,                      // multiply/divide unit result
  input  logic [P.XLEN-1:0] FCvtIntResW,                     // FPU's float to int conversion result
  input  logic              FCvtIntW,                        // FPU converts float to int
  output logic [4:0]        RdW,                             // Destination register
  input  logic [P.XLEN-1:0] ReadDataW,                       // LSU's read data

  // Hazard unit signals
  input  logic              StallD, StallE, StallM, StallW,  // Stall signals from hazard unit
  input  logic              FlushD, FlushE, FlushM, FlushW,  // Flush signals
  output logic              StructuralStallD,                // IEU detects structural hazard in Decode stage
  output logic              LoadStallD,                      // Structural stalls for load, sent to performance counters
  output logic              StoreStallD,                     // load after store hazard
  output logic              CSRReadM, CSRWriteM, PrivilegedM,// CSR read, CSR write, is privileged instruction
  output logic              CSRWriteFenceM,                  // CSR write or fence instruction needs to flush subsequent instructions

  // Widened Regfile Signals (relay from inside datapath to outside IEU)
  input  logic [P.XLEN-1:0]  rd1_ieu, rd2_ieu,               // Read data for ports 1, 2
  output logic             we3_ieu,                          // Write enable
  output logic [4:0]       a1_ieu, a2_ieu, a3_ieu,           // Source registers to read (a1, a2), destination register to write (a3)
  output logic [P.XLEN-1:0]  wd3_ieu,                        // Write data for port 3

  // Modified STARBUG Signals for Forwarding -----------------------------------------

  input  logic [4:0] RdW_1, RdW_2, RdW_3,                                  // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
  input  logic [4:0] RdM_1, RdM_2, RdM_3,                                  // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
  input  logic [P.XLEN-1:0] ResultW_1, ResultW_2, ResultW_3,               // These inputs are the results from other FUs' WB Stage
  input  logic [P.XLEN-1:0] IFResultM_1, IFResultM_2, IFResultM_3,         // These inputs are the results from other FUs' Mem Stage
  output logic RegWriteMOut, RegWriteWOut,                                 // These outputs are WB and Mem stage write enable signals for this ieu instance, to be sent out to other FUs
  output logic ResultW, IFResultM                                          // These outputs are WB and Mem stage results of this ieu instance
  
  // ---------------------------------------------------------------------------------
);

  logic [2:0] ImmSrcD;                                       // Select type of immediate extension 
  logic [1:0] FlagsE;                                        // Comparison flags ({eq, lt})
  logic       ALUSrcAE, ALUSrcBE;                            // ALU source operands
  logic [2:0] ResultSrcW;                                    // Selects result in Writeback stage
  logic       ALUResultSrcE;                                 // Selects ALU result to pass on to Memory stage
  logic [2:0] ALUSelectE;                                    // ALU select mux signal
  logic       FWriteIntM;                                    // FPU writing to integer register file
  logic       IntDivW;                                       // Integer divide instruction
  logic [3:0] BSelectE;                                      // Indicates if ZBA_ZBB_ZBC_ZBS instruction in one-hot encoding
  logic [3:0] ZBBSelectE;                                    // ZBB Result Select Signal in Execute Stage
  logic [2:0] BALUControlE;                                  // ALU Control signals for B instructions in Execute Stage
  logic       SubArithE;                                     // Subtraction or arithmetic shift
  logic       UW64E;                                         // .uw-type instruction

  logic [6:0] Funct7E;

  // Forwarding signals
  logic [4:0] Rs1D, Rs2D;                                    // These are the D stage source regs of this ieu istance (treat as instance 0)
  logic [4:0] Rs1D_1, Rs2D_1;                                // These are the D stage source regs of connected instance 1
  logic [4:0] Rs1D_2, Rs2D_2;                                // These are the D stage source regs of connected instance 2
  logic [4:0] Rs1D_3, Rs2D_3;                                // These are the D stage source regs of connected instance 3


  logic [4:0] Rs2E;                                          // Source registers
  logic [1:0] ForwardAE, ForwardBE;                          // Select signals for forwarding multiplexers
  logic       RegWriteW;                                     // Register will be written in Writeback stage
  logic       BranchSignedE;                                 // Branch does signed comparison on operands
  logic       BMUActiveE;                                    // Bit manipulation instruction being executed
  logic [1:0] CZeroE;                                        // {czero.nez, czero.eqz} instructions active

  // Relay signals to accomodate widened RegFile (for VLIW STARBUG)
  logic [P.XLEN-1:0] rd1, rd2, wd3;
  logic [4:0]        a1, a2, a3;
  logic              we3;
  assign rd1 = rd1_ieu;
  assign rd2 = rd2_ieu;
  assign we3_ieu = we3;
  assign a1_ieu = a1;
  assign a2_ieu = a2;
  assign a3_ieu = a3;
  assign wd3_ieu = wd3;

  logic [1:0] ForwardSelectControllerToDatapath_Rs1;
  logic [1:0] ForwardSelectControllerToDatapath_Rs2;

  controller #(P) c(
    .clk, .reset, .StallD, .FlushD, .InstrD, .STATUS_FS, .ENVCFG_CBE, .ImmSrcD,
    .IllegalIEUFPUInstrD, .IllegalBaseInstrD, 
    .StructuralStallD, .LoadStallD, .StoreStallD, .Rs1D, .Rs2D,  .Rs2E,
    .StallE, .FlushE, .FlagsE, .FWriteIntE,
    .PCSrcE, .ALUSrcAE, .ALUSrcBE, .ALUResultSrcE, .ALUSelectE,
    .Funct3E, .Funct7E, .IntDivE, .W64E, .UW64E, .SubArithE, .BranchD, .BranchE, .JumpD, .JumpE,
    .BranchSignedE, .BSelectE, .ZBBSelectE, .BALUControlE, .BMUActiveE, .CZeroE, .MDUActiveE, 
    .FCvtIntE, .ForwardAE, .ForwardBE, .CMOpM, .IFUPrefetchE, .LSUPrefetchM,
    .StallM, .FlushM, .MemRWE, .MemRWM, .CSRReadM, .CSRWriteM, .PrivilegedM, .AtomicM, .Funct3M,
    .FlushDCacheM, .InstrValidM, .InstrValidE, .InstrValidD, .FWriteIntM,
    .StallW, .FlushW, .RegWriteW, .IntDivW, .ResultSrcW, .CSRWriteFenceM, .InvalidateICacheM,
    
    // RdW and RdM Also to be sent out to other FUs for forwarding (constituting the RdW_X and RdM_X inputs of another FU's controller module)
    .RdW, .RdE, .RdM,

    // New VLIW Forwarding ports
    .RegWriteMOut(RegWriteMOut), .RegWriteWOut(RegWriteWOut),   // These outputs are WB and Mem stage write enable signals for this ieu instance, to be sent out to other FUs
    .RdW_1(RdW_1), .RdW_2(RdW_2), .RdW_3(RdW_3),                // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
    .RdM_1(RdM_1), .RdM_2(RdM_2), .RdM_3(RdM_3),                // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
    .ForwardSelect_Rs1(ForwardSelectControllerToDatapath_Rs1),  // This output is a 2-bit internal signal indicating which FU this ieu has decided to accept forwarded results from (0 indicates itself)
    .ForwardSelect_Rs2(ForwardSelectControllerToDatapath_Rs2)    // This output is a 2-bit internal signal indicating which FU this ieu has decided to accept forwarded results from (0 indicates itself)
    );

  datapath #(P) dp(
    .clk, .reset, .ImmSrcD, .InstrD, .Rs1D, .Rs2D, .Rs2E, .StallE, .FlushE, .ForwardAE, .ForwardBE, .W64E, .UW64E, .SubArithE,
    .Funct3E, .Funct7E, .ALUSrcAE, .ALUSrcBE, .ALUResultSrcE, .ALUSelectE, .JumpE, .BranchSignedE, 
    .PCE, .PCLinkE, .FlagsE, .IEUAdrE, .ForwardedSrcAE, .ForwardedSrcBE, .BSelectE, .ZBBSelectE, .BALUControlE, .BMUActiveE, .CZeroE,
    .StallM, .FlushM, .FWriteIntM, .FIntResM, .SrcAM, .WriteDataM, .FCvtIntW,
    .StallW, .FlushW, .RegWriteW, .IntDivW, .SquashSCW, .ResultSrcW, .ReadDataW, .FCvtIntResW,
    .CSRReadValW, .MDUResultW, .FIntDivResultW, .RdW
    ,.rd1, .rd2, .we3, 
    .a1, .a2, .a3, .wd3,

    // New VLIW Forwarding Ports
    .ForwardSelect_Rs1(ForwardSelectControllerToDatapath_Rs1),                               // This input is the forward select signal from this ieu instance's controller module
    .ForwardSelect_Rs2(ForwardSelectControllerToDatapath_Rs2),                               // This input is the forward select signal from this ieu instance's controller module
    .ResultW_1(ResultW_1), .ResultW_2(ResultW_2), .ResultW_3(ResultW_3),                     // These inputs are the results from other FUs' WB Stage
    .IFResultM_1(IFResultM_1), .IFResultM_2(IFResultM_2), .IFResultM_3(IFResultM_3),         // These inputs are the results from other FUs' Mem Stage
    .ResultW(ResultW), .IFResultM_0(IFResultM)                                               // These are the Mem and WB stage results of this ieu instance
    );      


// TODO: adjust wallypipelinedcore to connect inter-ieu wires, also result outputs need to be brought out from datapath

endmodule
