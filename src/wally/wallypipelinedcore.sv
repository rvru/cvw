// //MODIFIED 4 WIDE VLIW

// ///////////////////////////////////////////
// // wallypipelinedcore.sv
// //
// // Written: David_Harris@hmc.edu 9 January 2021
// // Modified:
// //
// // Purpose: Pipelined RISC-V Processor
// //
// // Documentation: RISC-V System on Chip Design
// //
// // A component of the CORE-V-WALLY configurable RISC-V project.
// // https://github.com/openhwgroup/cvw
// //
// // Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
// //
// // SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// //
// // Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// // except in compliance with the License, or, at your option, the Apache License version 2.0. You
// // may obtain a copy of the License at
// //
// // https://solderpad.org/licenses/SHL-2.1/
// //
// // Unless required by applicable law or agreed to in writing, any work distributed under the
// // License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// // either express or implied. See the License for the specific language governing permissions
// // and limitations under the License.
// ////////////////////////////////////////////////////////////////////////////////////////////////

module wallypipelinedcore import cvw::*; #(parameter cvw_t P) (
   input  logic                  clk, reset,
   // Privileged
   input  logic                  MTimerInt, MExtInt, SExtInt, MSwInt,
   input  logic [63:0]           MTIME_CLINT,
   // Bus Interface
   input  logic [P.AHBW-1:0]     HRDATA,
   input  logic                  HREADY, HRESP,
   output logic                  HCLK, HRESETn,
   output logic [P.PA_BITS-1:0]  HADDR,
   output logic [P.AHBW-1:0]     HWDATA,
   output logic [P.XLEN/8-1:0]   HWSTRB,
   output logic                  HWRITE,
   output logic [2:0]            HSIZE,
   output logic [2:0]            HBURST,
   output logic [3:0]            HPROT,
   output logic [1:0]            HTRANS,
   output logic                  HMASTLOCK,
   input  logic                  ExternalStall
);

  localparam [31:0] NOP = 32'h00000013;

  logic                          StallF, StallD, StallE, StallM, StallW;
  logic                          FlushD, FlushE, FlushM, FlushW;
  logic                          TrapM, RetM;

  //  signals that must connect through DP
  logic                          IntDivE, IntDivE_1, IntDivE_2, IntDivE_3, W64E, W64E_1, W64E_2, W64E_3;
  logic                          CSRReadM, CSRReadM_1,  CSRReadM_2, CSRReadM_3, CSRWriteM, CSRWriteM_1, CSRWriteM_2, CSRWriteM_3; 
  logic                          PrivilegedM, PrivilegedM_1, PrivilegedM_2, PrivilegedM_3;
  logic [1:0]                    AtomicM, AtomicM_1, AtomicM_2, AtomicM_3;
  logic [P.XLEN-1:0]             ForwardedSrcAE, ForwardedSrcAE_1, ForwardedSrcAE_2, ForwardedSrcAE_3;
  logic [P.XLEN-1:0]             ForwardedSrcBE, ForwardedSrcBE_1, ForwardedSrcBE_2, ForwardedSrcBE_3;
  logic [P.XLEN-1:0]             SrcAM, SrcAM_1, SrcAM_2, SrcAM_3;
  logic [2:0]                    Funct3E, Funct3E_1, Funct3E_2, Funct3E_3;
  logic [31:0]                   InstrD;
  logic [31:0]                   InstrM, InstrM_1, InstrM_2, InstrM_3, InstrOrigM;
  logic [P.XLEN-1:0]             PCSpillF, PCE, PCLinkE;
  logic [P.XLEN-1:0]             PCM, PCSpillM;
  logic [P.XLEN-1:0]             CSRReadValW, MDUResultW, MDUResultW_1, MDUResultW_2, MDUResultW_3;
  logic [P.XLEN-1:0]             EPCM, TrapVectorM;
  logic [1:0]                    MemRWE, MemRWE_1, MemRWE_2, MemRWE_3;
  logic [1:0]                    MemRWM, MemRWM_1, MemRWM_2, MemRWM_3;
  logic                          InstrValidD, InstrValidD_1, InstrValidD_2, InstrValidD_3, InstrValidE, InstrValidE_1, InstrValidE_2, InstrValidE_3;
  logic                          InstrValidM, InstrValidM_1, InstrValidM_2, InstrValidM_3;
  logic                          InstrMisalignedFaultM;
  logic                          IllegalBaseInstrD, IllegalBaseInstrD_1, IllegalBaseInstrD_2, IllegalBaseInstrD_3, IllegalFPUInstrD, IllegalFPUInstrD_1, IllegalFPUInstrD_2, IllegalFPUInstrD_3, IllegalIEUFPUInstrD, IllegalIEUFPUInstrD_1, IllegalIEUFPUInstrD_2, IllegalIEUFPUInstrD_3;
  logic                          InstrPageFaultF, LoadPageFaultM, LoadPageFaultM_1, LoadPageFaultM_2, LoadPageFaultM_3, StoreAmoPageFaultM, StoreAmoPageFaultM_1, StoreAmoPageFaultM_2, StoreAmoPageFaultM_3;
  logic                          LoadMisalignedFaultM, LoadMisalignedFaultM_1, LoadMisalignedFaultM_2, LoadMisalignedFaultM_3, LoadAccessFaultM, LoadAccessFaultM_1, LoadAccessFaultM_2, LoadAccessFaultM_3;
  logic                          StoreAmoMisalignedFaultM, StoreAmoMisalignedFaultM_1, StoreAmoMisalignedFaultM_2, StoreAmoMisalignedFaultM_3;
  logic                          StoreAmoAccessFaultM, StoreAmoAccessFaultM_1, StoreAmoAccessFaultM_2, StoreAmoAccessFaultM_3;
  logic                          InvalidateICacheM, InvalidateICacheM_1, InvalidateICacheM_2, InvalidateICacheM_3, FlushDCacheM, FlushDCacheM_1, FlushDCacheM_2, FlushDCacheM_3;
  logic                          PCSrcE;
  logic                          CSRWriteFenceM, CSRWriteFenceM_1, CSRWriteFenceM_2, CSRWriteFenceM_3;
  logic                          DivBusyE, DivBusyE_1, DivBusyE_2, DivBusyE_3;
  logic                          StructuralStallD, StructuralStallD_1, StructuralStallD_2, StructuralStallD_3;
  logic                          LoadStallD, LoadStallD_1, LoadStallD_2, LoadStallD_3;
  logic                          StoreStallD, StoreStallD_1, StoreStallD_2, StoreStallD_3;
  logic                          SquashSCW, SquashSCW_1, SquashSCW_2, SquashSCW_3;
  logic                          MDUActiveE, MDUActiveE_1, MDUActiveE_2, MDUActiveE_3;                      // Mul/Div instruction being executed
  logic                          ENVCFG_ADUE;                     // HPTW A/D Update enable
  logic                          ENVCFG_PBMTE;                    // Page-based memory type enable
  logic [3:0]                    ENVCFG_CBE;                      // Cache Block operation enables
  logic [3:0]                    CMOpM, CMOpM_1, CMOpM_2, CMOpM_3;                           // 1: cbo.inval; 2: cbo.flush; 4: cbo.clean; 8: cbo.zero
  logic                          IFUPrefetchE, IFUPrefetchE_1, IFUPrefetchE_2, IFUPrefetchE_3, LSUPrefetchM, LSUPrefetchM_1, LSUPrefetchM_2, LSUPrefetchM_3;      // instruction / data prefetch hints

  // floating point unit signals
  logic [2:0]                    FRM_REGW;
  logic [4:0]                    RdE, RdE_1, RdE_2, RdE_3, RdM, RdM_1, RdM_2, RdM_3, RdW, RdW_1, RdW_2, RdW_3;
  logic                          FPUStallD, FPUStallD_1, FPUStallD_2, FPUStallD_3;
  logic                          FWriteIntE, FWriteIntE_1, FWriteIntE_2, FWriteIntE_3;
  logic [P.FLEN-1:0]             FWriteDataM, FWriteDataM_1, FWriteDataM_2, FWriteDataM_3;
  logic [P.XLEN-1:0]             FIntResM, FIntResM_1, FIntResM_2, FIntResM_3;
  logic [P.XLEN-1:0]             FCvtIntResW, FCvtIntResW_1, FCvtIntResW_2, FCvtIntResW_3;
  logic                          FCvtIntW, FCvtIntW_1, FCvtIntW_2, FCvtIntW_3;
  logic                          FDivBusyE, FDivBusyE_1, FDivBusyE_2, FDivBusyE_3;
  logic                          FRegWriteM, FRegWriteM_1, FRegWriteM_2, FRegWriteM_3;
  logic                          FPRegWriteE, FPRegWriteE_1, FPRegWriteE_2, FPRegWriteE_3;
  logic                          FPRegWriteW, FPRegWriteW_1, FPRegWriteW_2, FPRegWriteW_3;
  logic                          FpLoadStoreM, FpLoadStoreM_1, FpLoadStoreM_2, FpLoadStoreM_3;
  logic [4:0]                    SetFflagsM, SetFflagsM_1, SetFflagsM_2, SetFflagsM_3;
  logic [P.XLEN-1:0]             FIntDivResultW, FIntDivResultW_1, FIntDivResultW_2, FIntDivResultW_3;
  logic [P.FLEN-1:0]             FpResMForward, FpResMForward_1, FpResMForward_2, FpResMForward_3;
  logic [P.FLEN-1:0]             FResultWForward, FResultWForward_1, FResultWForward_2, FResultWForward_3;
  logic                          FRegWriteM_OR;
  logic [4:0]                    SetFflagsM_OR;

  logic [4:0]                    FRegFileRa1_0, FRegFileRa2_0, FRegFileRa3_0, FRegFileWa_0;
  logic [4:0]                    FRegFileRa1_1, FRegFileRa2_1, FRegFileRa3_1, FRegFileWa_1;
  logic [4:0]                    FRegFileRa1_2, FRegFileRa2_2, FRegFileRa3_2, FRegFileWa_2;
  logic [4:0]                    FRegFileRa1_3, FRegFileRa2_3, FRegFileRa3_3, FRegFileWa_3;
  logic [P.FLEN-1:0]             FRegFileWd_0, FRegFileWd_1, FRegFileWd_2, FRegFileWd_3;
  logic [P.FLEN-1:0]             FRegFileRd1_0, FRegFileRd2_0, FRegFileRd3_0;
  logic [P.FLEN-1:0]             FRegFileRd1_1, FRegFileRd2_1, FRegFileRd3_1;
  logic [P.FLEN-1:0]             FRegFileRd1_2, FRegFileRd2_2, FRegFileRd3_2;
  logic [P.FLEN-1:0]             FRegFileRd1_3, FRegFileRd2_3, FRegFileRd3_3;

  // memory management unit signals
  logic                          ITLBWriteF, ITLBWriteF_1, ITLBWriteF_2, ITLBWriteF_3;
  logic                          ITLBMissOrUpdateAF;
  logic [P.XLEN-1:0]             SATP_REGW;
  logic                          STATUS_MXR, STATUS_SUM, STATUS_MPRV;
  logic [1:0]                    STATUS_MPP, STATUS_FS;
  logic [1:0]                    PrivilegeModeW;
  logic [P.XLEN-1:0]             PTE;
  logic [1:0]                    PageType;
  logic                          sfencevmaM;
  logic                          SelHPTW, SelHPTW_1, SelHPTW_2, SelHPTW_3;

  // PMA checker signals
  /* verilator lint_off UNDRIVEN */ // these signals are undriven in configurations without a privileged unit
  var logic [P.PA_BITS-3:0]      PMPADDR_ARRAY_REGW[P.PMP_ENTRIES-1:0];
  var logic [7:0]                PMPCFG_ARRAY_REGW[P.PMP_ENTRIES-1:0];
  /* verilator lint_on UNDRIVEN */

  // IMem stalls
  logic                          IFUStallF;
  logic                          LSUStallM, LSUStallM_1, LSUStallM_2, LSUStallM_3;

  // cpu lsu interface
  logic [2:0]                    Funct3M, Funct3M_1, Funct3M_2, Funct3M_3;
  logic [P.XLEN-1:0]             IEUAdrE;
  logic [P.XLEN-1:0]             WriteDataM, WriteDataM_1, WriteDataM_2, WriteDataM_3;
  logic [P.XLEN-1:0]             IEUAdrM;
  logic [P.XLEN-1:0]             IEUAdrxTvalM;
  logic [P.LLEN-1:0]             ReadDataW, ReadDataW_1, ReadDataW_2, ReadDataW_3;
  logic                          CommittedM, CommittedM_1, CommittedM_2, CommittedM_3;

  // AHB ifu interface
  logic [P.PA_BITS-1:0]          IFUHADDR;
  logic [2:0]                    IFUHBURST;
  logic [1:0]                    IFUHTRANS;
  logic [2:0]                    IFUHSIZE;
  logic                          IFUHWRITE;
  logic                          IFUHREADY;

  // AHB LSU interface
  logic [P.PA_BITS-1:0]          LSUHADDR;
  logic [P.XLEN-1:0]             LSUHWDATA;
  logic [P.XLEN/8-1:0]           LSUHWSTRB;
  logic                          LSUHWRITE;
  logic                          LSUHREADY;

  logic                          BPWrongE, BPWrongM;
  logic                          BPDirWrongM;
  logic                          BTAWrongM;
  logic                          RASPredPCWrongM;
  logic                          IClassWrongM;
  logic [3:0]                    IClassM;
  logic                          InstrAccessFaultF, HPTWInstrAccessFaultF, HPTWInstrAccessFaultF_1, HPTWInstrAccessFaultF_2, HPTWInstrAccessFaultF_3, HPTWInstrPageFaultF, HPTWInstrPageFaultF_1, HPTWInstrPageFaultF_2, HPTWInstrPageFaultF_3;
  logic [2:0]                    LSUHSIZE;
  logic [2:0]                    LSUHBURST;
  logic [1:0]                    LSUHTRANS;

  logic                          DCacheMiss, DCacheMiss_1, DCacheMiss_2, DCacheMiss_3;
  logic                          DCacheAccess, DCacheAccess_1, DCacheAccess_2, DCacheAccess_3;
  logic                          ICacheMiss;
  logic                          ICacheAccess;
  logic                          BigEndianM;
  logic                          FCvtIntE, FCvtIntE_1, FCvtIntE_2, FCvtIntE_3;
  logic                          CommittedF;
  logic                          BranchD, BranchD_1, BranchD_2, BranchD_3, BranchE, BranchE_1, BranchE_2, BranchE_3;
  logic                          JumpD, JumpD_1, JumpD_2, JumpD_3, JumpE, JumpE_1, JumpE_2, JumpE_3;
  logic                          DCacheStallM, DCacheStallM_1, DCacheStallM_2, DCacheStallM_3, ICacheStallF;
  logic                          wfiM, IntPendingM;

  // Declarations for STARBUG VLIW
  logic             we3, we6, we9, we12;  // Write enables for ports 3, 6, 9, 12
  logic [4:0]       a1, a2, a3;          // FU1: Source registers to read (a1, a2), destination register to write (a3)
  logic [4:0]       a4, a5, a6;          // FU2: Source registers to read (a4, a5), destination register to write (a6)
  logic [4:0]       a7, a8, a9;          // FU3: Source registers to read (a7, a8), destination register to write (a9)
  logic [4:0]       a10, a11, a12;       // FU4: Source registers to read (a10, a11), destination register to write (a12)
  logic [P.XLEN-1:0]  wd3, wd6, wd9, wd12;  // Write data for ports 3, 6, 9, and 12
    
  logic [P.XLEN-1:0]  rd1, rd2;            // FU1: Read data for ports 1, 2
  logic [P.XLEN-1:0]  rd4, rd5;           // FU2: Read data for ports 4, 5
  logic [P.XLEN-1:0]  rd7, rd8;           // FU3: Read data for ports 7, 8
  logic [P.XLEN-1:0]  rd10, rd11;      // FU4: Read data for ports 10, 11

  logic [31:0]          VLIWInstr0D;       // First VLIW instruction (decoded)
  logic [31:0]          VLIWInstr1D;       // Second VLIW instruction (decoded)
  logic [31:0]          VLIWInstr2D;        // Third VLIW instruction (decoded)
  logic [31:0]          VLIWInstr3D;        // Fourth VLIW instruction (decoded)
  logic [3:0]           VLIWValidD;        // Valid bits for each VLIW instruction
  logic                 VLIWModeD;         // Indicates VLIW mode is active so we can ignore 
  logic [31:0]          LaneInstrD0, LaneInstrD1, LaneInstrD2, LaneInstrD3;
  logic                 LaneValidD0, LaneValidD1, LaneValidD2, LaneValidD3;

  assign LaneValidD0 = VLIWModeD ? VLIWValidD[0] : 1'b1;
  assign LaneValidD1 = VLIWModeD & VLIWValidD[1];
  assign LaneValidD2 = VLIWModeD & VLIWValidD[2];
  assign LaneValidD3 = VLIWModeD & VLIWValidD[3];

  assign LaneInstrD0 = VLIWModeD ? (VLIWValidD[0] ? VLIWInstr0D : NOP) : InstrD;
  assign LaneInstrD1 = LaneValidD1 ? VLIWInstr1D : NOP;
  assign LaneInstrD2 = LaneValidD2 ? VLIWInstr2D : NOP;
  assign LaneInstrD3 = LaneValidD3 ? VLIWInstr3D : NOP;

  // Temporary debug aid for Starbug VLIW bring-up. Enable with:
  //   wsim ... --args "+STARBUG_VLIW_DEBUG"
  always_ff @(posedge clk) begin
    if (!reset && $test$plusargs("STARBUG_VLIW_DEBUG")) begin
      if (VLIWModeD) begin
        $display("STARBUGDBG D valid=%b lane_valid=%b%b%b%b i0=%h i1=%h i2=%h i3=%h ill=%b%b%b%b",
                 VLIWValidD, LaneValidD3, LaneValidD2, LaneValidD1, LaneValidD0,
                 LaneInstrD0, LaneInstrD1, LaneInstrD2, LaneInstrD3,
                 IllegalIEUFPUInstrD_3, IllegalIEUFPUInstrD_2, IllegalIEUFPUInstrD_1, IllegalIEUFPUInstrD);
      end
      if (VLIWModeD ||
          InstrValidD || InstrValidD_1 || InstrValidD_2 || InstrValidD_3 ||
          InstrValidE || InstrValidE_1 || InstrValidE_2 || InstrValidE_3 ||
          InstrValidM || InstrValidM_1 || InstrValidM_2 || InstrValidM_3 ||
          ieu.c.InstrValidW || ieu_1.c.InstrValidW || ieu_2.c.InstrValidW || ieu_3.c.InstrValidW) begin
        $display("STARBUGDBG C ivD=%b%b%b%b ivE=%b%b%b%b ivM=%b%b%b%b ivW=%b%b%b%b rwD=%b%b%b%b rwE=%b%b%b%b rwM=%b%b%b%b rwW=%b%b%b%b rwo=%b%b%b%b rdW=%0d,%0d,%0d,%0d",
                 InstrValidD_3, InstrValidD_2, InstrValidD_1, InstrValidD,
                 InstrValidE_3, InstrValidE_2, InstrValidE_1, InstrValidE,
                 InstrValidM_3, InstrValidM_2, InstrValidM_1, InstrValidM,
                 ieu_3.c.InstrValidW, ieu_2.c.InstrValidW, ieu_1.c.InstrValidW, ieu.c.InstrValidW,
                 ieu_3.c.RegWriteD, ieu_2.c.RegWriteD, ieu_1.c.RegWriteD, ieu.c.RegWriteD,
                 ieu_3.c.RegWriteE, ieu_2.c.RegWriteE, ieu_1.c.RegWriteE, ieu.c.RegWriteE,
                 ieu_3.c.RegWriteM, ieu_2.c.RegWriteM, ieu_1.c.RegWriteM, ieu.c.RegWriteM,
                 ieu_3.c.RegWriteW, ieu_2.c.RegWriteW, ieu_1.c.RegWriteW, ieu.c.RegWriteW,
                 RegWriteWOut_3, RegWriteWOut_2, RegWriteWOut_1, RegWriteWOut,
                 RdW, RdW_1, RdW_2, RdW_3);
      end
      if (we3 || we6 || we9 || we12) begin
        $display("STARBUGDBG W we=%b%b%b%b rd=%0d,%0d,%0d,%0d wd=%h,%h,%h,%h",
                 we12, we9, we6, we3, a3, a6, a9, a12, wd3, wd6, wd9, wd12);
      end
    end
  end




  // instruction fetch unit: PC, branch prediction, instruction cache
  ifu #(P) ifu(.clk, .reset,
    .StallF, .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
    .InstrValidE, .InstrValidD,
    .BranchD, .BranchE, .JumpD, .JumpE, .ICacheStallF,
    // Fetch
    .HRDATA, .PCSpillF, .IFUHADDR,
    .IFUStallF, .IFUHBURST, .IFUHTRANS, .IFUHSIZE, .IFUHREADY, .IFUHWRITE,
    .ICacheAccess, .ICacheMiss,
    // Execute
    .PCLinkE, .PCSrcE, .IEUAdrE, .IEUAdrM, .PCE, .BPWrongE,  .BPWrongM,
    // Mem
    .CommittedF, .EPCM, .TrapVectorM, .RetM, .TrapM, .InvalidateICacheM, .CSRWriteFenceM,
    .InstrD, .InstrM, 
    .InstrM_1, .InstrM_2, .InstrM_3, .InstrOrigM, .PCM, .PCSpillM, .IClassM, .BPDirWrongM,
    .BTAWrongM, .RASPredPCWrongM, .IClassWrongM,
    // Faults out
    .IllegalBaseInstrD, .IllegalBaseInstrD_1, .IllegalBaseInstrD_2, .IllegalBaseInstrD_3,
    .IllegalFPUInstrD, .IllegalFPUInstrD_1, .IllegalFPUInstrD_2, .IllegalFPUInstrD_3,
    .InstrPageFaultF, .IllegalIEUFPUInstrD, .IllegalIEUFPUInstrD_1, .IllegalIEUFPUInstrD_2, .IllegalIEUFPUInstrD_3, .InstrMisalignedFaultM,
    // mmu management
    .PrivilegeModeW, .PTE, .PageType, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV,
    .STATUS_MPP, .ENVCFG_PBMTE, .ENVCFG_ADUE, .ITLBWriteF, .sfencevmaM, .ITLBMissOrUpdateAF,
    // pmp/pma (inside mmu) signals.
    .PMPCFG_ARRAY_REGW,  .PMPADDR_ARRAY_REGW, .InstrAccessFaultF,
    // ============ NEW VLIW PORTS ============
    .VLIWInstr0D, .VLIWInstr1D, .VLIWInstr2D, .VLIWInstr3D,
    .VLIWValidD, .VLIWModeD); 

    
  // PRINT DECODED VLIW BUNDLES FOR STARBUG DEBUGGING
  // always @(posedge clk) begin
  //   if (VLIWModeD) begin
  //     if (VLIWValidD[0]) begin
  //       $info("CORE: [PC~=0x%h] VLIW instr 0 (32b) 0x%08h", PCE, VLIWInstr0D);
  //     end
  //     if (VLIWValidD[1]) begin
  //       $info("CORE: [PC~=0x%h] VLIW instr 1 (32b) 0x%08h", PCE, VLIWInstr1D);
  //     end
  //     if (VLIWValidD[2]) begin
  //       $info("CORE: [PC~=0x%h] VLIW instr 2 (32b) 0x%08h", PCE, VLIWInstr2D);
  //     end
  //     if (VLIWValidD[3]) begin
  //       $info("CORE: [PC~=0x%h] VLIW instr 3 (32b) 0x%08h", PCE, VLIWInstr3D);
  //     end
  //   end
  // end


  // IEU CONNECTION SCHEME FOR VLIW STARBUG FORWARDING
    
    // ieu sees the following:
    //  - Connection 0: self
    //  - Connection 1: ieu_1
    //  - Connection 2: ieu_2
    //  - Connection 3: ieu_3

    // ieu_1 sees the following:
    //  - Connection 0: self
    //  - Connection 1: ieu
    //  - Connection 2: ieu_2
    //  - Connection 3: ieu_3

    // ieu_2 sees the following:
    //  - Connection 0: self
    //  - Connection 1: ieu
    //  - Connection 2: ieu_1
    //  - Connection 3: ieu_3

    // ieu_3 sees the following:
    //  - Connection 0: self
    //  - Connection 1: ieu
    //  - Connection 2: ieu_1
    //  - Connection 3: ieu_2

  // VLIW Forwarding Inter FU Connections
  //ieu
  //logic [4:0] RdW_1, RdW_2, RdW_3,                                  // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
  //logic [4:0] RdM_1, RdM_2, RdM_3,                                  // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
  logic [P.XLEN-1:0] ResultW, ResultW_1, ResultW_2, ResultW_3;               // These inputs are the results from other FUs' WB Stage
  logic [P.XLEN-1:0] IFResultM, IFResultM_1, IFResultM_2, IFResultM_3;         // These inputs are the results from other FUs' Mem Stage
  logic RegWriteMOut, RegWriteMOut_1, RegWriteMOut_2, RegWriteMOut_3;
  logic RegWriteWOut, RegWriteWOut_1, RegWriteWOut_2, RegWriteWOut_3;

  logic MemReadE, MemReadE_1, MemReadE_2, MemReadE_3;
  logic SCE, SCE_1, SCE_2, SCE_3;

  //ieu_1



  // integer execution unit: integer register file, datapath and controller
  ieu #(P) 
  ieu(.clk, .reset,
     // Decode Stage interface
     .InstrD(LaneInstrD0), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD, .LaneValidD(LaneValidD0), .IllegalBaseInstrD,
     // Execute Stage interface
     .PCE, .PCLinkE, .FWriteIntE, .FCvtIntE, .IEUAdrE, .IntDivE, .W64E,
     .Funct3E, .ForwardedSrcAE, .ForwardedSrcBE, .MDUActiveE, .CMOpM, .IFUPrefetchE, .LSUPrefetchM,
     // Memory stage interface
     .SquashSCW,  // from LSU
     .MemRWE,     // read/write control goes to LSU
     .MemRWM,     // read/write control goes to LSU
     .AtomicM,    // atomic control goes to LSU
     .WriteDataM, // Write data to LSU
     .Funct3M,    // size and signedness to LSU
     .SrcAM,      // to privilege and fpu
     .RdE, .RdM, .FIntResM, .FlushDCacheM,
     .BranchD, .BranchE, .JumpD, .JumpE,
     // Writeback stage
     .CSRReadValW, .MDUResultW, .FIntDivResultW, .RdW, .ReadDataW(ReadDataW[P.XLEN-1:0]),
     .InstrValidM, .InstrValidE, .InstrValidD(InstrValidD), .FCvtIntResW, .FCvtIntW,
     // hazards
     .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
     .StructuralStallD, .LoadStallD, .StoreStallD, .PCSrcE,
     .CSRReadM, .CSRWriteM, .PrivilegedM, .CSRWriteFenceM, .InvalidateICacheM,
     // VLIW STARBUG Signals (for widened regfile)
     .rd1_ieu(rd1), .rd2_ieu(rd2),
     .we3_ieu(we3),
     .a1_ieu(a1), .a2_ieu(a2), .a3_ieu(a3),
     .wd3_ieu(wd3),
     // VLIW STARBUG Signals (for forwarding between FUs)
     .RdW_1(P.STARBUG_SUPPORTED ? RdW_1 : '0), .RdW_2(P.STARBUG_SUPPORTED ? RdW_2 : '0), .RdW_3(P.STARBUG_SUPPORTED ? RdW_3 : '0),                                           // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
     .RdM_1(P.STARBUG_SUPPORTED ? RdM_1 : '0), .RdM_2(P.STARBUG_SUPPORTED ? RdM_2 : '0), .RdM_3(P.STARBUG_SUPPORTED ? RdM_3 : '0),                                           // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
     .ResultW_1(P.STARBUG_SUPPORTED ? ResultW_1 : '0), .ResultW_2(P.STARBUG_SUPPORTED ? ResultW_2 : '0), .ResultW_3(P.STARBUG_SUPPORTED ? ResultW_3 : '0),                   // These inputs are the results from other FUs' WB Stage
     .IFResultM_1(P.STARBUG_SUPPORTED ? IFResultM_1 : '0), .IFResultM_2(P.STARBUG_SUPPORTED ? IFResultM_2 : '0), .IFResultM_3(P.STARBUG_SUPPORTED ? IFResultM_3 : '0),       // These inputs are the results from other FUs' Mem Stage
     .RegWriteMOut(RegWriteMOut), .RegWriteWOut(RegWriteWOut),                              // These outputs are WB and Mem stage write enable signals for this ieu instance, to be sent out to other FUs
     .ResultW(ResultW), .IFResultM(IFResultM),                                              // Results from this ieu instance
     .RegWriteM_1(P.STARBUG_SUPPORTED ? RegWriteMOut_1 : 1'b0), .RegWriteM_2(P.STARBUG_SUPPORTED ? RegWriteMOut_2 : 1'b0), .RegWriteM_3(P.STARBUG_SUPPORTED ? RegWriteMOut_3 : 1'b0),       // WriteEnable status of other lanes insts in M stage
     .RegWriteW_1(P.STARBUG_SUPPORTED ? RegWriteWOut_1 : 1'b0), .RegWriteW_2(P.STARBUG_SUPPORTED ? RegWriteWOut_2 : 1'b0), .RegWriteW_3(P.STARBUG_SUPPORTED ? RegWriteWOut_3 : 1'b0),       // WriteEnable status of other lanes insts in W stage
     .RdE_1(P.STARBUG_SUPPORTED ? RdE_1 : '0), .RdE_2(P.STARBUG_SUPPORTED ? RdE_2 : '0), .RdE_3(P.STARBUG_SUPPORTED ? RdE_3 : '0),                                           // These are inputs to the controller that are used for MatchDE checking across lanes
     .InstrValidE_1(P.STARBUG_SUPPORTED ? InstrValidE_1 : 1'b0), .InstrValidE_2(P.STARBUG_SUPPORTED ? InstrValidE_2 : 1'b0), .InstrValidE_3(P.STARBUG_SUPPORTED ? InstrValidE_3 : 1'b0),
     
     .MemReadE(MemReadE),                                        // Output signal identifying whether a read of memory will happen for this lane
     .SCE(SCE),                                                  // Output signal identifying whether result source E == 3'b100
     .MemReadE_1(P.STARBUG_SUPPORTED ? MemReadE_1 : 1'b0), .MemReadE_2(P.STARBUG_SUPPORTED ? MemReadE_2 : 1'b0), .MemReadE_3(P.STARBUG_SUPPORTED ? MemReadE_3 : 1'b0),  // Input ignals identifying whether a read of memory will happen for other lanes
     .SCE_1(P.STARBUG_SUPPORTED ? SCE_1 : 1'b0), .SCE_2(P.STARBUG_SUPPORTED ? SCE_2 : 1'b0), .SCE_3(P.STARBUG_SUPPORTED ? SCE_3 : 1'b0),                // Input signals identifying whether result source E == 3'b100 for other lanes
     .MDUActiveE_1(P.STARBUG_SUPPORTED ? MDUActiveE_1 : 1'b0), .MDUActiveE_2(P.STARBUG_SUPPORTED ? MDUActiveE_2 : 1'b0), .MDUActiveE_3(P.STARBUG_SUPPORTED ? MDUActiveE_3 : 1'b0)
     );
    
    ieu #(P)
    ieu_1(.clk, .reset,
      // Decode Stage interface
      .InstrD(LaneInstrD1), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD(IllegalIEUFPUInstrD_1), .LaneValidD(LaneValidD1), .IllegalBaseInstrD(IllegalBaseInstrD_1),
      // Execute Stage interface
      .PCE, .PCLinkE, .FWriteIntE(FWriteIntE_1), .FCvtIntE(FCvtIntE_1), 
        // .IEUAdrE, 
      .IntDivE(IntDivE_1), .W64E(W64E_1),
      .Funct3E(Funct3E_1), .ForwardedSrcAE(ForwardedSrcAE_1), .ForwardedSrcBE(ForwardedSrcBE_1), 
      .MDUActiveE(MDUActiveE_1), .CMOpM(CMOpM_1), .IFUPrefetchE(IFUPrefetchE_1), .LSUPrefetchM(LSUPrefetchM_1),
      // Memory stage interface
      .SquashSCW(SquashSCW_1),  // from LSU
      .MemRWE(MemRWE_1),     // read/write control goes to LSU
      .MemRWM(MemRWM_1),     // read/write control goes to LSU
      .AtomicM(AtomicM_1),    // atomic control goes to LSU
      .WriteDataM(WriteDataM_1), // Write data to LSU
      .Funct3M(Funct3M_1),    // size and signedness to LSU
      .SrcAM(SrcAM_1),      // to privilege and fpu
      .RdE(RdE_1), .RdM(RdM_1), .FIntResM(FIntResM_1), .FlushDCacheM(FlushDCacheM_1),
      .BranchD(BranchD_1), .BranchE(BranchE_1), .JumpD(JumpD_1), .JumpE(JumpE_1),
      // Writeback stage
      .CSRReadValW, .MDUResultW(MDUResultW_1), .FIntDivResultW(FIntDivResultW_1), .RdW(RdW_1), .ReadDataW(ReadDataW_1[P.XLEN-1:0]),
      .InstrValidM(InstrValidM_1), .InstrValidE(InstrValidE_1), .InstrValidD(InstrValidD_1), .FCvtIntResW(FCvtIntResW_1), .FCvtIntW(FCvtIntW_1),
      // hazards
      .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
      .StructuralStallD(StructuralStallD_1), .LoadStallD(LoadStallD_1), .StoreStallD(StoreStallD_1), 
      // .PCSrcE,
      .CSRReadM(CSRReadM_1), .CSRWriteM(CSRWriteM_1), .PrivilegedM(PrivilegedM_1), .CSRWriteFenceM(CSRWriteFenceM_1), .InvalidateICacheM(InvalidateICacheM_1),
     // VLIW STARBUG Signals (for widened regfile)
     .rd1_ieu(rd4), .rd2_ieu(rd5),
     .we3_ieu(we6),
     .a1_ieu(a4), .a2_ieu(a5), .a3_ieu(a6),
     .wd3_ieu(wd6),
     // VLIW STARBUG Signals (for forwarding between FUs)
     .RdW_1(RdW), .RdW_2(RdW_2), .RdW_3(RdW_3),                                             // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
     .RdM_1(RdM), .RdM_2(RdM_2), .RdM_3(RdM_3),                                             // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
     .ResultW_1(ResultW), .ResultW_2(ResultW_2), .ResultW_3(ResultW_3),                     // These inputs are the results from other FUs' WB Stage
     .IFResultM_1(IFResultM), .IFResultM_2(IFResultM_2), .IFResultM_3(IFResultM_3),         // These inputs are the results from other FUs' Mem Stage
     .RegWriteMOut(RegWriteMOut_1), .RegWriteWOut(RegWriteWOut_1),                          // These outputs are WB and Mem stage write enable signals for this ieu instance, to be sent out to other FUs
     .ResultW(ResultW_1), .IFResultM(IFResultM_1),                                          // Results from this ieu instance
     .RegWriteM_1(RegWriteMOut), .RegWriteM_2(RegWriteMOut_2), .RegWriteM_3(RegWriteMOut_3),       // WriteEnable status of other lanes insts in M stage
     .RegWriteW_1(RegWriteWOut), .RegWriteW_2(RegWriteWOut_2), .RegWriteW_3(RegWriteWOut_3),       // WriteEnable status of other lanes insts in W stage
     .RdE_1(RdE), .RdE_2(RdE_2), .RdE_3(RdE_3),                                             // These are inputs to the controller that are used for MatchDE checking across lanes
     .InstrValidE_1(InstrValidE), .InstrValidE_2(InstrValidE_2), .InstrValidE_3(InstrValidE_3),
     
     .MemReadE(MemReadE_1),                                       // Output signal identifying whether a read of memory will happen for this lane
     .SCE(SCE_1),                                                 // Output signal identifying whether result source E == 3'b100
     .MemReadE_1(MemReadE), .MemReadE_2(MemReadE_2), .MemReadE_3(MemReadE_3),   // Input ignals identifying whether a read of memory will happen for other lanes
     .SCE_1(SCE), .SCE_2(SCE_2), .SCE_3(SCE_3),                   // Input signals identifying whether result source E == 3'b100 for other lanes
     .MDUActiveE_1(MDUActiveE), .MDUActiveE_2(MDUActiveE_2), .MDUActiveE_3(MDUActiveE_3)
     );

    ieu #(P)
    ieu_2(.clk, .reset,
      // Decode Stage interface
      .InstrD(LaneInstrD2), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD(IllegalIEUFPUInstrD_2), .LaneValidD(LaneValidD2), .IllegalBaseInstrD(IllegalBaseInstrD_2),
      // Execute Stage interface
      .PCE, .PCLinkE, .FWriteIntE(FWriteIntE_2), .FCvtIntE(FCvtIntE_2), 
        // .IEUAdrE, 
      .IntDivE(IntDivE_2), .W64E(W64E_2),
      .Funct3E(Funct3E_2), .ForwardedSrcAE(ForwardedSrcAE_2), .ForwardedSrcBE(ForwardedSrcBE_2), 
      .MDUActiveE(MDUActiveE_2), .CMOpM(CMOpM_2), .IFUPrefetchE(IFUPrefetchE_2), .LSUPrefetchM(LSUPrefetchM_2),
      // Memory stage interface
      .SquashSCW(SquashSCW_2),  // from LSU
      .MemRWE(MemRWE_2),     // read/write control goes to LSU
      .MemRWM(MemRWM_2),     // read/write control goes to LSU
      .AtomicM(AtomicM_2),    // atomic control goes to LSU
      .WriteDataM(WriteDataM_2), // Write data to LSU
      .Funct3M(Funct3M_2),    // size and signedness to LSU
      .SrcAM(SrcAM_2),      // to privilege and fpu
      .RdE(RdE_2), .RdM(RdM_2), .FIntResM(FIntResM_2), .FlushDCacheM(FlushDCacheM_2),
      .BranchD(BranchD_2), .BranchE(BranchE_2), .JumpD(JumpD_2), .JumpE(JumpE_2),
      // Writeback stage
      .CSRReadValW, .MDUResultW(MDUResultW_2), .FIntDivResultW(FIntDivResultW_2), .RdW(RdW_2), .ReadDataW(ReadDataW_2[P.XLEN-1:0]),
      .InstrValidM(InstrValidM_2), .InstrValidE(InstrValidE_2), .InstrValidD(InstrValidD_2), .FCvtIntResW(FCvtIntResW_2), .FCvtIntW(FCvtIntW_2),
      // hazards
      .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
      .StructuralStallD(StructuralStallD_2), .LoadStallD(LoadStallD_2), .StoreStallD(StoreStallD_2), 
      // .PCSrcE,
      .CSRReadM(CSRReadM_2), .CSRWriteM(CSRWriteM_2), .PrivilegedM(PrivilegedM_2), .CSRWriteFenceM(CSRWriteFenceM_2), .InvalidateICacheM(InvalidateICacheM_2),
       // VLIW STARBUG Signals (for widened regfile)
      .rd1_ieu(rd7), .rd2_ieu(rd8),
      .we3_ieu(we9),
      .a1_ieu(a7), .a2_ieu(a8), .a3_ieu(a9),
      .wd3_ieu(wd9),
      // VLIW STARBUG Signals (for forwarding between FUs)
     .RdW_1(RdW), .RdW_2(RdW_1), .RdW_3(RdW_3),                                             // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
     .RdM_1(RdM), .RdM_2(RdM_1), .RdM_3(RdM_3),                                             // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
     .ResultW_1(ResultW), .ResultW_2(ResultW_1), .ResultW_3(ResultW_3),                     // These inputs are the results from other FUs' WB Stage
     .IFResultM_1(IFResultM), .IFResultM_2(IFResultM_1), .IFResultM_3(IFResultM_3),         // These inputs are the results from other FUs' Mem Stage
     .RegWriteMOut(RegWriteMOut_2), .RegWriteWOut(RegWriteWOut_2),                          // These outputs are WB and Mem stage write enable signals for this ieu instance, to be sent out to other FUs
     .ResultW(ResultW_2), .IFResultM(IFResultM_2),                                          // Results from this ieu instance
     .RegWriteM_1(RegWriteMOut), .RegWriteM_2(RegWriteMOut_1), .RegWriteM_3(RegWriteMOut_3),       // WriteEnable status of other lanes insts in M stage
     .RegWriteW_1(RegWriteWOut), .RegWriteW_2(RegWriteWOut_1), .RegWriteW_3(RegWriteWOut_3),       // WriteEnable status of other lanes insts in W stage
     .RdE_1(RdE), .RdE_2(RdE_1), .RdE_3(RdE_3),                                             // These are inputs to the controller that are used for MatchDE checking across lanes
     .InstrValidE_1(InstrValidE), .InstrValidE_2(InstrValidE_1), .InstrValidE_3(InstrValidE_3),
     
     .MemReadE(MemReadE_2),                                         // Output signal identifying whether a read of memory will happen for this lane
     .SCE(SCE_2),                                                   // Output signal identifying whether result source E == 3'b100
     .MemReadE_1(MemReadE), .MemReadE_2(MemReadE_1), .MemReadE_3(MemReadE_3),   // Input ignals identifying whether a read of memory will happen for other lanes
     .SCE_1(SCE), .SCE_2(SCE_1), .SCE_3(SCE_3),                     // Input signals identifying whether result source E == 3'b100 for other lanes
     .MDUActiveE_1(MDUActiveE), .MDUActiveE_2(MDUActiveE_1), .MDUActiveE_3(MDUActiveE_3)
     );

    ieu #(P)
    ieu_3(.clk, .reset,
      // Decode Stage interface
      .InstrD(LaneInstrD3), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD(IllegalIEUFPUInstrD_3), .LaneValidD(LaneValidD3), .IllegalBaseInstrD(IllegalBaseInstrD_3),
      // Execute Stage interface
      .PCE, .PCLinkE, .FWriteIntE(FWriteIntE_3), .FCvtIntE(FCvtIntE_3), 
        // .IEUAdrE, 
      .IntDivE(IntDivE_3), .W64E(W64E_3),
      .Funct3E(Funct3E_3), .ForwardedSrcAE(ForwardedSrcAE_3), .ForwardedSrcBE(ForwardedSrcBE_3), 
      .MDUActiveE(MDUActiveE_3), .CMOpM(CMOpM_3), .IFUPrefetchE(IFUPrefetchE_3), .LSUPrefetchM(LSUPrefetchM_3),
      // Memory stage interface
      .SquashSCW(SquashSCW_3),  // from LSU
      .MemRWE(MemRWE_3),     // read/write control goes to LSU
      .MemRWM(MemRWM_3),     // read/write control goes to LSU
      .AtomicM(AtomicM_3),    // atomic control goes to LSU
      .WriteDataM(WriteDataM_3), // Write data to LSU
      .Funct3M(Funct3M_3),    // size and signedness to LSU
      .SrcAM(SrcAM_3),      // to privilege and fpu
      .RdE(RdE_3), .RdM(RdM_3), .FIntResM(FIntResM_3), .FlushDCacheM(FlushDCacheM_3),
      .BranchD(BranchD_3), .BranchE(BranchE_3), .JumpD(JumpD_3), .JumpE(JumpE_3),
      // Writeback stage
      .CSRReadValW, .MDUResultW(MDUResultW_3), .FIntDivResultW(FIntDivResultW_3), .RdW(RdW_3), .ReadDataW(ReadDataW_3[P.XLEN-1:0]),
      .InstrValidM(InstrValidM_3), .InstrValidE(InstrValidE_3), .InstrValidD(InstrValidD_3), .FCvtIntResW(FCvtIntResW_3), .FCvtIntW(FCvtIntW_3),
      // hazards
      .StallD, .StallE, .StallM, .StallW, .FlushD, .FlushE, .FlushM, .FlushW,
      .StructuralStallD(StructuralStallD_3), .LoadStallD(LoadStallD_3), .StoreStallD(StoreStallD_3), 
      // .PCSrcE,
      .CSRReadM(CSRReadM_3), .CSRWriteM(CSRWriteM_3), .PrivilegedM(PrivilegedM_3), .CSRWriteFenceM(CSRWriteFenceM_3), .InvalidateICacheM(InvalidateICacheM_3),
       // VLIW STARBUG Signals (for widened regfile)
      .rd1_ieu(rd10), .rd2_ieu(rd11),
      .we3_ieu(we12),
      .a1_ieu(a10), .a2_ieu(a11), .a3_ieu(a12),
      .wd3_ieu(wd12),
      // VLIW STARBUG Signals (for forwarding between FUs)
     .RdW_1(RdW), .RdW_2(RdW_1), .RdW_3(RdW_2),                                             // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
     .RdM_1(RdM), .RdM_2(RdM_1), .RdM_3(RdM_2),                                             // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
     .ResultW_1(ResultW), .ResultW_2(ResultW_1), .ResultW_3(ResultW_2),                     // These inputs are the results from other FUs' WB Stage
     .IFResultM_1(IFResultM), .IFResultM_2(IFResultM_1), .IFResultM_3(IFResultM_2),         // These inputs are the results from other FUs' Mem Stage
     .RegWriteMOut(RegWriteMOut_3), .RegWriteWOut(RegWriteWOut_3),                          // These outputs are WB and Mem stage write enable signals for this ieu instance, to be sent out to other FUs
     .ResultW(ResultW_3), .IFResultM(IFResultM_3),                                          // Results from this ieu instance
     .RegWriteM_1(RegWriteMOut), .RegWriteM_2(RegWriteMOut_1), .RegWriteM_3(RegWriteMOut_2),       // WriteEnable status of other lanes insts in M stage
     .RegWriteW_1(RegWriteWOut), .RegWriteW_2(RegWriteWOut_1), .RegWriteW_3(RegWriteWOut_2),       // WriteEnable status of other lanes insts in W stage
     .RdE_1(RdE), .RdE_2(RdE_1), .RdE_3(RdE_2),                                             // These are inputs to the controller that are used for MatchDE checking across lanes
     .InstrValidE_1(InstrValidE), .InstrValidE_2(InstrValidE_1), .InstrValidE_3(InstrValidE_2),

     .MemReadE(MemReadE_3),                                         // Output signal identifying whether a read of memory will happen for this lane
     .SCE(SCE_3),                                                   // Output signal identifying whether result source E == 3'b100
     .MemReadE_1(MemReadE), .MemReadE_2(MemReadE_1), .MemReadE_3(MemReadE_2),   // Input ignals identifying whether a read of memory will happen for other lanes
     .SCE_1(SCE), .SCE_2(SCE_1), .SCE_3(SCE_2),                     // Input signals identifying whether result source E == 3'b100 for other lanes
     .MDUActiveE_1(MDUActiveE), .MDUActiveE_2(MDUActiveE_1), .MDUActiveE_3(MDUActiveE_2)
     );


  lsu #(P) 
  lsu(
    .clk, .reset, .StallM, .FlushM, .StallW, .FlushW,
    // CPU interface
    .MemRWE, .MemRWM, .Funct3M, .Funct7M(InstrM[31:25]), .AtomicM,
    .CommittedM, .DCacheMiss, .DCacheAccess, .SquashSCW,
    .FpLoadStoreM, .FWriteDataM, .IEUAdrE, .IEUAdrM, .WriteDataM,
    .ReadDataW, .FlushDCacheM, .CMOpM, .LSUPrefetchM,
    // connected to ahb (all stay the same)
    .LSUHADDR,  .HRDATA, .LSUHWDATA, .LSUHWSTRB, .LSUHSIZE,
    .LSUHBURST, .LSUHTRANS, .LSUHWRITE, .LSUHREADY,
    // connect to csr or privilege and stay the same.
    .PrivilegeModeW, .BigEndianM, // connects to csr
    .PMPCFG_ARRAY_REGW,           // connects to csr
    .PMPADDR_ARRAY_REGW,          // connects to csr
    // hptw keep i/o
    .SATP_REGW,                   // from csr
    .STATUS_MXR,                  // from csr
    .STATUS_SUM,                  // from csr
    .STATUS_MPRV,                 // from csr
    .STATUS_MPP,                  // from csr
    .ENVCFG_PBMTE,                // from csr
    .ENVCFG_ADUE,                 // from csr
    .sfencevmaM,                  // connects to privilege
    .DCacheStallM,                // connects to privilege
    .IEUAdrxTvalM,                // connects to privilege
    .LoadPageFaultM,              // connects to privilege
    .StoreAmoPageFaultM,          // connects to privilege
    .LoadMisalignedFaultM,        // connects to privilege
    .LoadAccessFaultM,            // connects to privilege
    .HPTWInstrAccessFaultF,       // connects to privilege
    .HPTWInstrPageFaultF,         // connects to privilege
    .StoreAmoMisalignedFaultM,    // connects to privilege
    .StoreAmoAccessFaultM,        // connects to privilege
    .PCSpillF, .ITLBMissOrUpdateAF, .PTE, .PageType, .ITLBWriteF, .SelHPTW,
    .LSUStallM);    

  // Only lane 0 is backed by the LSU today; keep the unused return paths quiet.
  assign {SquashSCW_1, SquashSCW_2, SquashSCW_3,
          ReadDataW_1, ReadDataW_2, ReadDataW_3} = '0;


  if(P.BUS_SUPPORTED) begin : ebu
    ebu #(P) ebu(// IFU connections
      .clk, .reset,
      // IFU interface
      .IFUHADDR, .IFUHBURST, .IFUHTRANS, .IFUHREADY, .IFUHSIZE,
      // LSU interface
      .LSUHADDR, .LSUHWDATA, .LSUHWSTRB, .LSUHSIZE, .LSUHBURST,
      .LSUHTRANS, .LSUHWRITE, .LSUHREADY,
      // BUS interface
      .HREADY, .HRESP, .HCLK, .HRESETn,
      .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST,
      .HPROT, .HTRANS, .HMASTLOCK);
  end else begin
    assign {IFUHREADY, LSUHREADY, HCLK, HRESETn, HADDR, HWDATA,
            HWSTRB, HWRITE, HSIZE, HBURST, HPROT, HTRANS, HMASTLOCK} = '0;
  end


  logic CSRWriteFenceM_OR;
  logic StructuralStallD_OR;
  logic FPUStallD_OR;
  logic DivBusyE_OR;
  logic FDivBusyE_OR;
  // global stall and flush control:
    // hazard unit inputs ORed for STARBUG VLIW implementation
  assign CSRWriteFenceM_OR = P.STARBUG_SUPPORTED ? (CSRWriteFenceM | CSRWriteFenceM_1 | CSRWriteFenceM_2 | CSRWriteFenceM_3) : CSRWriteFenceM;
  assign StructuralStallD_OR = P.STARBUG_SUPPORTED ? (StructuralStallD | StructuralStallD_1 | StructuralStallD_2 | StructuralStallD_3) : StructuralStallD;
  assign FPUStallD_OR = P.STARBUG_SUPPORTED ? (FPUStallD | FPUStallD_1 | FPUStallD_2 | FPUStallD_3) : FPUStallD;
  assign DivBusyE_OR = P.STARBUG_SUPPORTED ? (DivBusyE | DivBusyE_1 | DivBusyE_2 | DivBusyE_3) : DivBusyE;
  assign FDivBusyE_OR = P.STARBUG_SUPPORTED ? (FDivBusyE | FDivBusyE_1 | FDivBusyE_2 | FDivBusyE_3) : FDivBusyE;
  assign FRegWriteM_OR = P.STARBUG_SUPPORTED ? (FRegWriteM | FRegWriteM_1 | FRegWriteM_2 | FRegWriteM_3) : FRegWriteM;
  assign SetFflagsM_OR = P.STARBUG_SUPPORTED ? (SetFflagsM | SetFflagsM_1 | SetFflagsM_2 | SetFflagsM_3) : SetFflagsM;


  // hazard unit implementation with ORed signals from all 4 FU channels
  hazard hzu(
    .BPWrongE, .CSRWriteFenceM(CSRWriteFenceM_OR), .RetM, .TrapM,
    .StructuralStallD(StructuralStallD_OR),
    .LSUStallM, .IFUStallF,
    .FPUStallD(FPUStallD_OR), .ExternalStall,
    .DivBusyE(DivBusyE_OR), .FDivBusyE(FDivBusyE_OR),
    .wfiM, .IntPendingM,
    // Stall & flush outputs
    .StallF, .StallD, .StallE, .StallM, .StallW,
    .FlushD, .FlushE, .FlushM, .FlushW);

  // privileged unit
  if (P.ZICSR_SUPPORTED) begin:priv
    privileged #(P) priv(
      .clk, .reset,
      .FlushD, .FlushE, .FlushM, .FlushW, .StallD, .StallE, .StallM, .StallW,
      .CSRReadM, .CSRWriteM, .SrcAM, .PCM, .PCSpillM,
      .InstrM, .InstrOrigM, .CSRReadValW, .EPCM, .TrapVectorM,
      .RetM, .TrapM, .sfencevmaM, .InvalidateICacheM, .DCacheStallM, .ICacheStallF,
      .InstrValidM, .CommittedM, .CommittedF,
      .FRegWriteM(FRegWriteM_OR), .LoadStallD, .StoreStallD,
      .BPDirWrongM, .BTAWrongM, .BPWrongM,
      .RASPredPCWrongM, .IClassWrongM, .DivBusyE(DivBusyE_OR), .FDivBusyE(FDivBusyE_OR),
      .IClassM, .DCacheMiss, .DCacheAccess, .ICacheMiss, .ICacheAccess, .PrivilegedM,
      .InstrPageFaultF, .LoadPageFaultM, .StoreAmoPageFaultM,
      .InstrMisalignedFaultM, .IllegalIEUFPUInstrD,
      .LoadMisalignedFaultM, .StoreAmoMisalignedFaultM,
      .MTimerInt, .MExtInt, .SExtInt, .MSwInt,
      .MTIME_CLINT, .IEUAdrxTvalM, .SetFflagsM(SetFflagsM_OR),
      .InstrAccessFaultF, .HPTWInstrAccessFaultF, .HPTWInstrPageFaultF, .LoadAccessFaultM, .StoreAmoAccessFaultM, .SelHPTW,
      .PrivilegeModeW, .SATP_REGW,
      .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP, .STATUS_FS,
      .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW,
      .FRM_REGW, .ENVCFG_CBE, .ENVCFG_PBMTE, .ENVCFG_ADUE, .wfiM, .IntPendingM, .BigEndianM);
  end else begin
    assign {CSRReadValW, PrivilegeModeW,
            SATP_REGW, STATUS_MXR, STATUS_SUM, STATUS_MPRV, STATUS_MPP, STATUS_FS, FRM_REGW,
            // PMPCFG_ARRAY_REGW, PMPADDR_ARRAY_REGW,
            ENVCFG_CBE, ENVCFG_PBMTE, ENVCFG_ADUE,
            EPCM, TrapVectorM, RetM, TrapM,
            sfencevmaM, BigEndianM, wfiM, IntPendingM} = '0;
  end

  // multiply/divide unit
  if (P.ZMMUL_SUPPORTED) begin:mdu
    mdu #(P) mdu(.clk, .reset, .StallM, .StallW, .FlushE, .FlushM, .FlushW,
      .ForwardedSrcAE, .ForwardedSrcBE,
      .Funct3E, .Funct3M, .IntDivE, .W64E, .MDUActiveE,
      .MDUResultW, .DivBusyE);
  end else begin // no M instructions supported
    assign MDUResultW = '0;
    assign DivBusyE   = 1'b0;
  end

  if (P.ZMMUL_SUPPORTED) begin:mdu_1
    mdu #(P) 
    mdu_1(.clk, .reset, .StallM, .FlushM, .StallW, .FlushW, .FlushE,
      .ForwardedSrcAE(ForwardedSrcAE_1), .ForwardedSrcBE(ForwardedSrcBE_1),
      .Funct3E(Funct3E_1), .Funct3M(Funct3M_1), .IntDivE(IntDivE_1), .W64E(W64E_1), .MDUActiveE(MDUActiveE_1),
      .MDUResultW(MDUResultW_1), .DivBusyE(DivBusyE_1));
  end else begin // no M instructions supported
    assign MDUResultW_1 = '0;
    assign DivBusyE_1   = 1'b0;
  end

  if (P.ZMMUL_SUPPORTED) begin:mdu_2
    mdu #(P) 
    mdu_2(.clk, .reset, .StallM, .FlushM, .StallW, .FlushW, .FlushE,
      .ForwardedSrcAE(ForwardedSrcAE_2), .ForwardedSrcBE(ForwardedSrcBE_2),
      .Funct3E(Funct3E_2), .Funct3M(Funct3M_2), .IntDivE(IntDivE_2), .W64E(W64E_2), .MDUActiveE(MDUActiveE_2),
      .MDUResultW(MDUResultW_2), .DivBusyE(DivBusyE_2));
  end else begin // no M instructions supported
    assign MDUResultW_2 = '0;
    assign DivBusyE_2   = 1'b0;
  end

  if (P.ZMMUL_SUPPORTED) begin:mdu_3
    mdu #(P) 
    mdu_3(.clk, .reset, .StallM, .FlushM, .StallW, .FlushW, .FlushE,
      .ForwardedSrcAE(ForwardedSrcAE_3), .ForwardedSrcBE(ForwardedSrcBE_3),
      .Funct3E(Funct3E_3), .Funct3M(Funct3M_3), .IntDivE(IntDivE_3), .W64E(W64E_3), .MDUActiveE(MDUActiveE_3),
      .MDUResultW(MDUResultW_3), .DivBusyE(DivBusyE_3));
  end else begin // no M instructions supported
    assign MDUResultW_3 = '0;
    assign DivBusyE_3   = 1'b0;
  end

  // floating point unit
  if (P.F_SUPPORTED) begin:fpu
    fpu #(P) fpu(
      .clk, .reset,
      .FRM_REGW,                           // Rounding mode from CSR
      .InstrD(LaneInstrD0),                // instruction from IFU
      .ReadDataW(ReadDataW[P.FLEN-1:0]),   // Read data from memory
      .ForwardedSrcAE,                     // Integer input being processed (from IEU)
      .StallE, .StallM, .StallW,           // stall signals from HZU
      .FlushE, .FlushM, .FlushW,           // flush signals from HZU
      .RdE, .RdM, .RdW,                    // which FP register to write to (from IEU)
      .STATUS_FS,                          // is floating-point enabled?
      .FRegWriteM,                         // FP register write enable
      .FpLoadStoreM,
      .ForwardedSrcBE,                     // Integer input for intdiv
      .Funct3E, .Funct3M, .IntDivE, .W64E, // Integer flags and functions
      .FPUStallD,                          // Stall the decode stage
      .FWriteIntE, .FCvtIntE,              // integer register write enable, conversion operation
      .FWriteDataM,                        // Data to be written to memory
      .FIntResM,                           // data to be written to integer register
      .FCvtIntResW,                        // fp -> int conversion result to be stored in int register
      .FCvtIntW,                           // fpu result selection
      .FDivBusyE,                          // Is the divide/sqrt unit busy (stall execute stage)
      .IllegalFPUInstrD,                   // Is the instruction an illegal fpu instruction
      .SetFflagsM,                         // FPU flags (to privileged unit)
      .FIntDivResultW,
      .FRD1D_rf(FRegFileRd1_0), .FRD2D_rf(FRegFileRd2_0), .FRD3D_rf(FRegFileRd3_0),
      .FRegWriteWOut(FPRegWriteW),
      .FAdr1D_rf(FRegFileRa1_0), .FAdr2D_rf(FRegFileRa2_0), .FAdr3D_rf(FRegFileRa3_0),
      .FAdrW_rf(FRegFileWa_0), .FWriteDataW_rf(FRegFileWd_0),
      .RdE_1(P.STARBUG_SUPPORTED ? RdE_1 : '0), .RdE_2(P.STARBUG_SUPPORTED ? RdE_2 : '0), .RdE_3(P.STARBUG_SUPPORTED ? RdE_3 : '0),
      .RdM_1(P.STARBUG_SUPPORTED ? RdM_1 : '0), .RdM_2(P.STARBUG_SUPPORTED ? RdM_2 : '0), .RdM_3(P.STARBUG_SUPPORTED ? RdM_3 : '0),
      .RdW_1(P.STARBUG_SUPPORTED ? RdW_1 : '0), .RdW_2(P.STARBUG_SUPPORTED ? RdW_2 : '0), .RdW_3(P.STARBUG_SUPPORTED ? RdW_3 : '0),
      .FRegWriteE_1(P.STARBUG_SUPPORTED ? FPRegWriteE_1 : 1'b0), .FRegWriteE_2(P.STARBUG_SUPPORTED ? FPRegWriteE_2 : 1'b0), .FRegWriteE_3(P.STARBUG_SUPPORTED ? FPRegWriteE_3 : 1'b0),
      .FRegWriteM_1(P.STARBUG_SUPPORTED ? FRegWriteM_1 : 1'b0), .FRegWriteM_2(P.STARBUG_SUPPORTED ? FRegWriteM_2 : 1'b0), .FRegWriteM_3(P.STARBUG_SUPPORTED ? FRegWriteM_3 : 1'b0),
      .FRegWriteW_1(P.STARBUG_SUPPORTED ? FPRegWriteW_1 : 1'b0), .FRegWriteW_2(P.STARBUG_SUPPORTED ? FPRegWriteW_2 : 1'b0), .FRegWriteW_3(P.STARBUG_SUPPORTED ? FPRegWriteW_3 : 1'b0),
      .FpLoadStoreM_1(P.STARBUG_SUPPORTED ? FpLoadStoreM_1 : 1'b0), .FpLoadStoreM_2(P.STARBUG_SUPPORTED ? FpLoadStoreM_2 : 1'b0), .FpLoadStoreM_3(P.STARBUG_SUPPORTED ? FpLoadStoreM_3 : 1'b0),
      .FpResM_1(P.STARBUG_SUPPORTED ? FpResMForward_1 : '0), .FpResM_2(P.STARBUG_SUPPORTED ? FpResMForward_2 : '0), .FpResM_3(P.STARBUG_SUPPORTED ? FpResMForward_3 : '0),
      .FResultW_1(P.STARBUG_SUPPORTED ? FResultWForward_1 : '0), .FResultW_2(P.STARBUG_SUPPORTED ? FResultWForward_2 : '0), .FResultW_3(P.STARBUG_SUPPORTED ? FResultWForward_3 : '0),
      .FRegWriteEOut(FPRegWriteE),
      .FpResMOut(FpResMForward),
      .FResultWOut(FResultWForward));

    fpu #(P) fpu_1(
      .clk, .reset,
      .FRM_REGW,
      .InstrD(LaneInstrD1),
      .ReadDataW('0),
      .ForwardedSrcAE(ForwardedSrcAE_1),
      .StallE, .StallM, .StallW,
      .FlushE, .FlushM, .FlushW,
      .RdE(RdE_1), .RdM(RdM_1), .RdW(RdW_1),
      .STATUS_FS,
      .FRegWriteM(FRegWriteM_1),
      .FpLoadStoreM(FpLoadStoreM_1),
      .ForwardedSrcBE(ForwardedSrcBE_1),
      .Funct3E(Funct3E_1), .Funct3M(Funct3M_1), .IntDivE(IntDivE_1), .W64E(W64E_1),
      .FPUStallD(FPUStallD_1),
      .FWriteIntE(FWriteIntE_1), .FCvtIntE(FCvtIntE_1),
      .FWriteDataM(FWriteDataM_1),
      .FIntResM(FIntResM_1),
      .FCvtIntResW(FCvtIntResW_1),
      .FCvtIntW(FCvtIntW_1),
      .FDivBusyE(FDivBusyE_1),
      .IllegalFPUInstrD(IllegalFPUInstrD_1),
      .SetFflagsM(SetFflagsM_1),
      .FIntDivResultW(FIntDivResultW_1),
      .FRD1D_rf(FRegFileRd1_1), .FRD2D_rf(FRegFileRd2_1), .FRD3D_rf(FRegFileRd3_1),
      .FRegWriteWOut(FPRegWriteW_1),
      .FAdr1D_rf(FRegFileRa1_1), .FAdr2D_rf(FRegFileRa2_1), .FAdr3D_rf(FRegFileRa3_1),
      .FAdrW_rf(FRegFileWa_1), .FWriteDataW_rf(FRegFileWd_1),
      .RdE_1(RdE), .RdE_2(RdE_2), .RdE_3(RdE_3),
      .RdM_1(RdM), .RdM_2(RdM_2), .RdM_3(RdM_3),
      .RdW_1(RdW), .RdW_2(RdW_2), .RdW_3(RdW_3),
      .FRegWriteE_1(FPRegWriteE), .FRegWriteE_2(FPRegWriteE_2), .FRegWriteE_3(FPRegWriteE_3),
      .FRegWriteM_1(FRegWriteM), .FRegWriteM_2(FRegWriteM_2), .FRegWriteM_3(FRegWriteM_3),
      .FRegWriteW_1(FPRegWriteW), .FRegWriteW_2(FPRegWriteW_2), .FRegWriteW_3(FPRegWriteW_3),
      .FpLoadStoreM_1(FpLoadStoreM), .FpLoadStoreM_2(FpLoadStoreM_2), .FpLoadStoreM_3(FpLoadStoreM_3),
      .FpResM_1(FpResMForward), .FpResM_2(FpResMForward_2), .FpResM_3(FpResMForward_3),
      .FResultW_1(FResultWForward), .FResultW_2(FResultWForward_2), .FResultW_3(FResultWForward_3),
      .FRegWriteEOut(FPRegWriteE_1),
      .FpResMOut(FpResMForward_1),
      .FResultWOut(FResultWForward_1));

    fpu #(P) fpu_2(
      .clk, .reset,
      .FRM_REGW,
      .InstrD(LaneInstrD2),
      .ReadDataW('0),
      .ForwardedSrcAE(ForwardedSrcAE_2),
      .StallE, .StallM, .StallW,
      .FlushE, .FlushM, .FlushW,
      .RdE(RdE_2), .RdM(RdM_2), .RdW(RdW_2),
      .STATUS_FS,
      .FRegWriteM(FRegWriteM_2),
      .FpLoadStoreM(FpLoadStoreM_2),
      .ForwardedSrcBE(ForwardedSrcBE_2),
      .Funct3E(Funct3E_2), .Funct3M(Funct3M_2), .IntDivE(IntDivE_2), .W64E(W64E_2),
      .FPUStallD(FPUStallD_2),
      .FWriteIntE(FWriteIntE_2), .FCvtIntE(FCvtIntE_2),
      .FWriteDataM(FWriteDataM_2),
      .FIntResM(FIntResM_2),
      .FCvtIntResW(FCvtIntResW_2),
      .FCvtIntW(FCvtIntW_2),
      .FDivBusyE(FDivBusyE_2),
      .IllegalFPUInstrD(IllegalFPUInstrD_2),
      .SetFflagsM(SetFflagsM_2),
      .FIntDivResultW(FIntDivResultW_2),
      .FRD1D_rf(FRegFileRd1_2), .FRD2D_rf(FRegFileRd2_2), .FRD3D_rf(FRegFileRd3_2),
      .FRegWriteWOut(FPRegWriteW_2),
      .FAdr1D_rf(FRegFileRa1_2), .FAdr2D_rf(FRegFileRa2_2), .FAdr3D_rf(FRegFileRa3_2),
      .FAdrW_rf(FRegFileWa_2), .FWriteDataW_rf(FRegFileWd_2),
      .RdE_1(RdE), .RdE_2(RdE_1), .RdE_3(RdE_3),
      .RdM_1(RdM), .RdM_2(RdM_1), .RdM_3(RdM_3),
      .RdW_1(RdW), .RdW_2(RdW_1), .RdW_3(RdW_3),
      .FRegWriteE_1(FPRegWriteE), .FRegWriteE_2(FPRegWriteE_1), .FRegWriteE_3(FPRegWriteE_3),
      .FRegWriteM_1(FRegWriteM), .FRegWriteM_2(FRegWriteM_1), .FRegWriteM_3(FRegWriteM_3),
      .FRegWriteW_1(FPRegWriteW), .FRegWriteW_2(FPRegWriteW_1), .FRegWriteW_3(FPRegWriteW_3),
      .FpLoadStoreM_1(FpLoadStoreM), .FpLoadStoreM_2(FpLoadStoreM_1), .FpLoadStoreM_3(FpLoadStoreM_3),
      .FpResM_1(FpResMForward), .FpResM_2(FpResMForward_1), .FpResM_3(FpResMForward_3),
      .FResultW_1(FResultWForward), .FResultW_2(FResultWForward_1), .FResultW_3(FResultWForward_3),
      .FRegWriteEOut(FPRegWriteE_2),
      .FpResMOut(FpResMForward_2),
      .FResultWOut(FResultWForward_2));

    fpu #(P) fpu_3(
      .clk, .reset,
      .FRM_REGW,
      .InstrD(LaneInstrD3),
      .ReadDataW('0),
      .ForwardedSrcAE(ForwardedSrcAE_3),
      .StallE, .StallM, .StallW,
      .FlushE, .FlushM, .FlushW,
      .RdE(RdE_3), .RdM(RdM_3), .RdW(RdW_3),
      .STATUS_FS,
      .FRegWriteM(FRegWriteM_3),
      .FpLoadStoreM(FpLoadStoreM_3),
      .ForwardedSrcBE(ForwardedSrcBE_3),
      .Funct3E(Funct3E_3), .Funct3M(Funct3M_3), .IntDivE(IntDivE_3), .W64E(W64E_3),
      .FPUStallD(FPUStallD_3),
      .FWriteIntE(FWriteIntE_3), .FCvtIntE(FCvtIntE_3),
      .FWriteDataM(FWriteDataM_3),
      .FIntResM(FIntResM_3),
      .FCvtIntResW(FCvtIntResW_3),
      .FCvtIntW(FCvtIntW_3),
      .FDivBusyE(FDivBusyE_3),
      .IllegalFPUInstrD(IllegalFPUInstrD_3),
      .SetFflagsM(SetFflagsM_3),
      .FIntDivResultW(FIntDivResultW_3),
      .FRD1D_rf(FRegFileRd1_3), .FRD2D_rf(FRegFileRd2_3), .FRD3D_rf(FRegFileRd3_3),
      .FRegWriteWOut(FPRegWriteW_3),
      .FAdr1D_rf(FRegFileRa1_3), .FAdr2D_rf(FRegFileRa2_3), .FAdr3D_rf(FRegFileRa3_3),
      .FAdrW_rf(FRegFileWa_3), .FWriteDataW_rf(FRegFileWd_3),
      .RdE_1(RdE), .RdE_2(RdE_1), .RdE_3(RdE_2),
      .RdM_1(RdM), .RdM_2(RdM_1), .RdM_3(RdM_2),
      .RdW_1(RdW), .RdW_2(RdW_1), .RdW_3(RdW_2),
      .FRegWriteE_1(FPRegWriteE), .FRegWriteE_2(FPRegWriteE_1), .FRegWriteE_3(FPRegWriteE_2),
      .FRegWriteM_1(FRegWriteM), .FRegWriteM_2(FRegWriteM_1), .FRegWriteM_3(FRegWriteM_2),
      .FRegWriteW_1(FPRegWriteW), .FRegWriteW_2(FPRegWriteW_1), .FRegWriteW_3(FPRegWriteW_2),
      .FpLoadStoreM_1(FpLoadStoreM), .FpLoadStoreM_2(FpLoadStoreM_1), .FpLoadStoreM_3(FpLoadStoreM_2),
      .FpResM_1(FpResMForward), .FpResM_2(FpResMForward_1), .FpResM_3(FpResMForward_2),
      .FResultW_1(FResultWForward), .FResultW_2(FResultWForward_1), .FResultW_3(FResultWForward_2),
      .FRegWriteEOut(FPRegWriteE_3),
      .FpResMOut(FpResMForward_3),
      .FResultWOut(FResultWForward_3));
  end else begin                           // no F_SUPPORTED or D_SUPPORTED; tie outputs low
    assign {FPUStallD, FPUStallD_1, FPUStallD_2, FPUStallD_3,
            FWriteIntE, FWriteIntE_1, FWriteIntE_2, FWriteIntE_3,
            FCvtIntE, FCvtIntE_1, FCvtIntE_2, FCvtIntE_3,
            FIntResM, FIntResM_1, FIntResM_2, FIntResM_3,
            FCvtIntW, FCvtIntW_1, FCvtIntW_2, FCvtIntW_3,
            FRegWriteM, FRegWriteM_1, FRegWriteM_2, FRegWriteM_3,
            FPRegWriteE, FPRegWriteE_1, FPRegWriteE_2, FPRegWriteE_3,
            FPRegWriteW, FPRegWriteW_1, FPRegWriteW_2, FPRegWriteW_3,
            IllegalFPUInstrD, IllegalFPUInstrD_1, IllegalFPUInstrD_2, IllegalFPUInstrD_3,
            SetFflagsM, SetFflagsM_1, SetFflagsM_2, SetFflagsM_3,
            FpLoadStoreM, FpLoadStoreM_1, FpLoadStoreM_2, FpLoadStoreM_3,
            FWriteDataM, FWriteDataM_1, FWriteDataM_2, FWriteDataM_3,
            FCvtIntResW, FCvtIntResW_1, FCvtIntResW_2, FCvtIntResW_3,
            FIntDivResultW, FIntDivResultW_1, FIntDivResultW_2, FIntDivResultW_3,
            FDivBusyE, FDivBusyE_1, FDivBusyE_2, FDivBusyE_3,
            FpResMForward, FpResMForward_1, FpResMForward_2, FpResMForward_3,
            FResultWForward, FResultWForward_1, FResultWForward_2, FResultWForward_3,
            FRegFileRa1_0, FRegFileRa2_0, FRegFileRa3_0, FRegFileWa_0,
            FRegFileRa1_1, FRegFileRa2_1, FRegFileRa3_1, FRegFileWa_1,
            FRegFileRa1_2, FRegFileRa2_2, FRegFileRa3_2, FRegFileWa_2,
            FRegFileRa1_3, FRegFileRa2_3, FRegFileRa3_3, FRegFileWa_3,
            FRegFileWd_0, FRegFileWd_1, FRegFileWd_2, FRegFileWd_3} = '0;
  end
  
  // WIDENED STARBUG REGFILE
    // Instantiate Widened regfile
    regfile_widened #(P.XLEN, P.E_SUPPORTED) regfile_widened (
      .clk(clk), .reset(reset),
      .we3(we3), .we6(P.STARBUG_SUPPORTED ? we6 : 1'b0), .we9(P.STARBUG_SUPPORTED ? we9 : 1'b0), .we12(P.STARBUG_SUPPORTED ? we12 : 1'b0),
      .a1(a1), .a2(a2), .a3(a3),
      .a4(P.STARBUG_SUPPORTED ? a4 : '0), .a5(P.STARBUG_SUPPORTED ? a5 : '0), .a6(P.STARBUG_SUPPORTED ? a6 : '0),
      .a7(P.STARBUG_SUPPORTED ? a7 : '0), .a8(P.STARBUG_SUPPORTED ? a8 : '0), .a9(P.STARBUG_SUPPORTED ? a9 : '0),
      .a10(P.STARBUG_SUPPORTED ? a10 : '0), .a11(P.STARBUG_SUPPORTED ? a11 : '0), .a12(P.STARBUG_SUPPORTED ? a12 : '0),
      .wd3(wd3), .wd6(P.STARBUG_SUPPORTED ? wd6 : '0), .wd9(P.STARBUG_SUPPORTED ? wd9 : '0), .wd12(P.STARBUG_SUPPORTED ? wd12 : '0),
      .rd1(rd1), .rd2(rd2),
      .rd4(rd4), .rd5(rd5),
      .rd7(rd7), .rd8(rd8),
      .rd10(rd10), .rd11(rd11)
    );
    fregfile_widened #(P.FLEN) fregfile_widened (
      .clk(clk), .reset(reset),
      .we0(FPRegWriteW), .we1(P.STARBUG_SUPPORTED ? FPRegWriteW_1 : 1'b0), .we2(P.STARBUG_SUPPORTED ? FPRegWriteW_2 : 1'b0), .we3(P.STARBUG_SUPPORTED ? FPRegWriteW_3 : 1'b0),
      .ra1_0(FRegFileRa1_0), .ra2_0(FRegFileRa2_0), .ra3_0(FRegFileRa3_0), .wa_0(FRegFileWa_0),
      .ra1_1(P.STARBUG_SUPPORTED ? FRegFileRa1_1 : '0), .ra2_1(P.STARBUG_SUPPORTED ? FRegFileRa2_1 : '0), .ra3_1(P.STARBUG_SUPPORTED ? FRegFileRa3_1 : '0), .wa_1(P.STARBUG_SUPPORTED ? FRegFileWa_1 : '0),
      .ra1_2(P.STARBUG_SUPPORTED ? FRegFileRa1_2 : '0), .ra2_2(P.STARBUG_SUPPORTED ? FRegFileRa2_2 : '0), .ra3_2(P.STARBUG_SUPPORTED ? FRegFileRa3_2 : '0), .wa_2(P.STARBUG_SUPPORTED ? FRegFileWa_2 : '0),
      .ra1_3(P.STARBUG_SUPPORTED ? FRegFileRa1_3 : '0), .ra2_3(P.STARBUG_SUPPORTED ? FRegFileRa2_3 : '0), .ra3_3(P.STARBUG_SUPPORTED ? FRegFileRa3_3 : '0), .wa_3(P.STARBUG_SUPPORTED ? FRegFileWa_3 : '0),
      .wd_0(FRegFileWd_0), .wd_1(P.STARBUG_SUPPORTED ? FRegFileWd_1 : '0), .wd_2(P.STARBUG_SUPPORTED ? FRegFileWd_2 : '0), .wd_3(P.STARBUG_SUPPORTED ? FRegFileWd_3 : '0),
      .rd1_0(FRegFileRd1_0), .rd2_0(FRegFileRd2_0), .rd3_0(FRegFileRd3_0),
      .rd1_1(FRegFileRd1_1), .rd2_1(FRegFileRd2_1), .rd3_1(FRegFileRd3_1),
      .rd1_2(FRegFileRd1_2), .rd2_2(FRegFileRd2_2), .rd3_2(FRegFileRd3_2),
      .rd1_3(FRegFileRd1_3), .rd2_3(FRegFileRd2_3), .rd3_3(FRegFileRd3_3)
    );
  // END STARBUG REGFILE

endmodule
