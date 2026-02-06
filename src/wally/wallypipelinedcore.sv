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
  logic                          IllegalBaseInstrD, IllegalBaseInstrD_1, IllegalBaseInstrD_2, IllegalBaseInstrD_3, IllegalFPUInstrD, IllegalFPUInstrD_1, IllegalFPUInstrD_2, IllegalFPUInstrD_3, IllegalIEUFPUInstrD;
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
  logic                          FpLoadStoreM, FpLoadStoreM_1, FpLoadStoreM_2, FpLoadStoreM_3;
  logic [4:0]                    SetFflagsM;
  logic [P.XLEN-1:0]             FIntDivResultW, FIntDivResultW_1, FIntDivResultW_2, FIntDivResultW_3;

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
    .IllegalBaseInstrD, .IllegalFPUInstrD, .InstrPageFaultF, .IllegalIEUFPUInstrD, .InstrMisalignedFaultM,
    // mmu management
    .PrivilegeModeW, .PTE, .PageType, .SATP_REGW, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV,
    .STATUS_MPP, .ENVCFG_PBMTE, .ENVCFG_ADUE, .ITLBWriteF, .sfencevmaM, .ITLBMissOrUpdateAF,
    // pmp/pma (inside mmu) signals.
    .PMPCFG_ARRAY_REGW,  .PMPADDR_ARRAY_REGW, .InstrAccessFaultF,
    // ============ NEW VLIW PORTS ============
    .VLIWInstr0D, .VLIWInstr1D, .VLIWInstr2D, .VLIWInstr3D,
    .VLIWValidD, .VLIWModeD); 

    
  // PRINT DECODED VLIW BUNDLES FOR STARBUG DEBUGGING
  always @(posedge clk) begin
    if (VLIWModeD) begin
      if (VLIWValidD[0]) begin
        $info("CORE: [PC~=0x%h] VLIW instr 0 (32b) 0x%08h", PCE, VLIWInstr0D);
      end
      if (VLIWValidD[1]) begin
        $info("CORE: [PC~=0x%h] VLIW instr 1 (32b) 0x%08h", PCE, VLIWInstr1D);
      end
      if (VLIWValidD[2]) begin
        $info("CORE: [PC~=0x%h] VLIW instr 2 (32b) 0x%08h", PCE, VLIWInstr2D);
      end
      if (VLIWValidD[3]) begin
        $info("CORE: [PC~=0x%h] VLIW instr 3 (32b) 0x%08h", PCE, VLIWInstr3D);
      end
    end
  end


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
  //ieu_1



  // integer execution unit: integer register file, datapath and controller
  ieu #(P) 
  ieu(.clk, .reset,
     // Decode Stage interface
     .InstrD(VLIWModeD ? VLIWInstr0D : InstrD), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD, .IllegalBaseInstrD,
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
     .RdW_1(RdW_1), .RdW_2(RdW_2), .RdW_3(RdW_3),                                           // These inputs are the WB stage dest reg selections from other FUs, to be used for forwarding check
     .RdM_1(RdM_1), .RdM_2(RdM_2), .RdM_3(RdM_3),                                           // These inputs are the Mem stage dest reg selections from other FUs, to be used for forwarding check
     .ResultW_1(ResultW_1), .ResultW_2(ResultW_2), .ResultW_3(ResultW_3),                   // These inputs are the results from other FUs' WB Stage
     .IFResultM_1(IFResultM_1), .IFResultM_2(IFResultM_2), .IFResultM_3(IFResultM_3),       // These inputs are the results from other FUs' Mem Stage
     .RegWriteMOut(RegWriteMOut), .RegWriteWOut(RegWriteWOut),                              // These outputs are WB and Mem stage write enable signals for this ieu instance, to be sent out to other FUs
     .ResultW(ResultW), .IFResultM(IFResultM)                                               // Results from this ieu instance
     );
    
    ieu #(P)
    ieu_1(.clk, .reset,
      // Decode Stage interface
      .InstrD(VLIWInstr1D), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD, .IllegalBaseInstrD(IllegalBaseInstrD_1),
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
     .ResultW(ResultW_1), .IFResultM(IFResultM_1)                                           // Results from this ieu instance
     );

    ieu #(P)
    ieu_2(.clk, .reset,
      // Decode Stage interface
      .InstrD(VLIWInstr2D), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD, .IllegalBaseInstrD(IllegalBaseInstrD_2),
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
     .ResultW(ResultW_2), .IFResultM(IFResultM_2)                                           // Results from this ieu instance
     );

    ieu #(P)
    ieu_3(.clk, .reset,
      // Decode Stage interface
      .InstrD(VLIWInstr3D), .STATUS_FS, .ENVCFG_CBE, .IllegalIEUFPUInstrD, .IllegalBaseInstrD(IllegalBaseInstrD_3),
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
     .ResultW(ResultW_3), .IFResultM(IFResultM_3)                                           // Results from this ieu instance
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

  lsu #(P)
  lsu_1(
    .clk, .reset, .StallM, .FlushM, .StallW, .FlushW,
    // CPU interface
    .MemRWE(MemRWE_1), .MemRWM(MemRWM_1), .Funct3M(Funct3M_1), .Funct7M(InstrM_1[31:25]), .AtomicM(AtomicM_1),
    .CommittedM(CommittedM_1), .DCacheMiss(DCacheMiss_1), .DCacheAccess(DCacheAccess_1), .SquashSCW(SquashSCW_1),
    .FpLoadStoreM(FpLoadStoreM_1), .FWriteDataM(FWriteDataM_1), 
    // .IEUAdrE, 
    // .IEUAdrM, 
    .WriteDataM(WriteDataM_1),
    .ReadDataW(ReadDataW_1), .FlushDCacheM(FlushDCacheM_1), .CMOpM(CMOpM_1), .LSUPrefetchM(LSUPrefetchM_1),
    // connected to ahb (all stay the same)
    // .LSUHADDR,  .HRDATA, .LSUHWDATA, .LSUHWSTRB, .LSUHSIZE,
    // .LSUHBURST, .LSUHTRANS, .LSUHWRITE, .LSUHREADY,
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
    .DCacheStallM(DCacheStallM_1),                // connects to privilege
    // .IEUAdrxTvalM,                // connects to privilege
    .LoadPageFaultM(LoadPageFaultM_1),              // connects to privilege
    .StoreAmoPageFaultM(StoreAmoPageFaultM_1),          // connects to privilege
    .LoadMisalignedFaultM(LoadMisalignedFaultM_1),        // connects to privilege
    .LoadAccessFaultM(LoadAccessFaultM_1),            // connects to privilege
    .HPTWInstrAccessFaultF(HPTWInstrAccessFaultF_1),       // connects to privilege
    .HPTWInstrPageFaultF(HPTWInstrPageFaultF_1),         // connects to privilege
    .StoreAmoMisalignedFaultM(StoreAmoMisalignedFaultM_1),    // connects to privilege
    .StoreAmoAccessFaultM(StoreAmoAccessFaultM_1),        // connects to privilege
    .PCSpillF, .ITLBMissOrUpdateAF, 
    // .PTE, 
    // .PageType, 
    .ITLBWriteF(ITLBWriteF_1), .SelHPTW(SelHPTW_1),
    .LSUStallM(LSUStallM_1));

    lsu #(P)
    lsu_2(
      .clk, .reset, .StallM, .FlushM, .StallW, .FlushW,
      // CPU interface
      .MemRWE(MemRWE_2), .MemRWM(MemRWM_2), .Funct3M(Funct3M_2), .Funct7M(InstrM_2[31:25]), .AtomicM(AtomicM_2),
      .CommittedM(CommittedM_2), .DCacheMiss(DCacheMiss_2), .DCacheAccess(DCacheAccess_2), .SquashSCW(SquashSCW_2),
      .FpLoadStoreM(FpLoadStoreM_2), .FWriteDataM(FWriteDataM_2), 
      // .IEUAdrE, 
      // .IEUAdrM, 
      .WriteDataM(WriteDataM_2),
      .ReadDataW(ReadDataW_2), .FlushDCacheM(FlushDCacheM_2), .CMOpM(CMOpM_2), .LSUPrefetchM(LSUPrefetchM_2),
      // connected to ahb (all stay the same)
      // .LSUHADDR,  .HRDATA, .LSUHWDATA, .LSUHWSTRB, .LSUHSIZE,
      // .LSUHBURST, .LSUHTRANS, .LSUHWRITE, .LSUHREADY,
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
      .DCacheStallM(DCacheStallM_2),                // connects to privilege
      // .IEUAdrxTvalM,                // connects to privilege
      .LoadPageFaultM(LoadPageFaultM_2),              // connects to privilege
      .StoreAmoPageFaultM(StoreAmoPageFaultM_2),          // connects to privilege
      .LoadMisalignedFaultM(LoadMisalignedFaultM_2),        // connects to privilege
      .LoadAccessFaultM(LoadAccessFaultM_2),            // connects to privilege
      .HPTWInstrAccessFaultF(HPTWInstrAccessFaultF_2),       // connects to privilege
      .HPTWInstrPageFaultF(HPTWInstrPageFaultF_2),         // connects to privilege
      .StoreAmoMisalignedFaultM(StoreAmoMisalignedFaultM_2),    // connects to privilege
      .StoreAmoAccessFaultM(StoreAmoAccessFaultM_2),        // connects to privilege
      .PCSpillF, .ITLBMissOrUpdateAF, 
      // .PTE, 
      // .PageType, 
      .ITLBWriteF(ITLBWriteF_2), .SelHPTW(SelHPTW_2),
      .LSUStallM(LSUStallM_2));
  
    lsu #(P)
    lsu_3(
      .clk, .reset, .StallM, .FlushM, .StallW, .FlushW,
      // CPU interface
      .MemRWE(MemRWE_3), .MemRWM(MemRWM_3), .Funct3M(Funct3M_3), .Funct7M(InstrM_3[31:25]), .AtomicM(AtomicM_3),
      .CommittedM(CommittedM_3), .DCacheMiss(DCacheMiss_3), .DCacheAccess(DCacheAccess_3), .SquashSCW(SquashSCW_3),
      .FpLoadStoreM(FpLoadStoreM_3), .FWriteDataM(FWriteDataM_3), 
      // .IEUAdrE, 
      // .IEUAdrM, 
      .WriteDataM(WriteDataM_3),
      .ReadDataW(ReadDataW_3), .FlushDCacheM(FlushDCacheM_3), .CMOpM(CMOpM_3), .LSUPrefetchM(LSUPrefetchM_3),
      // connected to ahb (all stay the same)
      // .LSUHADDR,  .HRDATA, .LSUHWDATA, .LSUHWSTRB, .LSUHSIZE,
      // .LSUHBURST, .LSUHTRANS, .LSUHWRITE, .LSUHREADY,
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
      .DCacheStallM(DCacheStallM_3),                // connects to privilege
      // .IEUAdrxTvalM,                // connects to privilege
      .LoadPageFaultM(LoadPageFaultM_3),              // connects to privilege
      .StoreAmoPageFaultM(StoreAmoPageFaultM_3),          // connects to privilege
      .LoadMisalignedFaultM(LoadMisalignedFaultM_3),        // connects to privilege
      .LoadAccessFaultM(LoadAccessFaultM_3),            // connects to privilege
      .HPTWInstrAccessFaultF(HPTWInstrAccessFaultF_3),       // connects to privilege
      .HPTWInstrPageFaultF(HPTWInstrPageFaultF_3),         // connects to privilege
      .StoreAmoMisalignedFaultM(StoreAmoMisalignedFaultM_3),    // connects to privilege
      .StoreAmoAccessFaultM(StoreAmoAccessFaultM_3),        // connects to privilege
      .PCSpillF, .ITLBMissOrUpdateAF, 
      // .PTE, 
      // .PageType, 
      .ITLBWriteF(ITLBWriteF_3), .SelHPTW(SelHPTW_3),
      .LSUStallM(LSUStallM_3));
    
  

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

  // global stall and flush control:
    // hazard unit inputs ORed for STARBUG VLIW implementation
  logic CSRWriteFenceM_OR = CSRWriteFenceM | CSRWriteFenceM_1 | CSRWriteFenceM_2 | CSRWriteFenceM_3;
  logic StructuralStallD_OR = StructuralStallD | StructuralStallD_1 | StructuralStallD_2 | StructuralStallD_3;
  logic LSUStallM_OR = LSUStallM; //| LSUStallM_1 | LSUStallM_2 | LSUStallM_3;
  logic FPUStallD_OR = FPUStallD | FPUStallD_1 | FPUStallD_2 | FPUStallD_3;
  logic DivBusyE_OR = DivBusyE | DivBusyE_1 | DivBusyE_2 | DivBusyE_3;
  logic FDivBusyE_OR = FDivBusyE | FDivBusyE_1 | FDivBusyE_2 | FDivBusyE_3;


  // hazard unit implementation with ORed signals from all 4 FU channels
  hazard hzu(
    .BPWrongE, .CSRWriteFenceM(CSRWriteFenceM_OR), .RetM, .TrapM,
    .StructuralStallD(StructuralStallD_OR),
    .LSUStallM(LSUStallM_OR), .IFUStallF,
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
      .FRegWriteM, .LoadStallD, .StoreStallD,
      .BPDirWrongM, .BTAWrongM, .BPWrongM,
      .RASPredPCWrongM, .IClassWrongM, .DivBusyE, .FDivBusyE,
      .IClassM, .DCacheMiss, .DCacheAccess, .ICacheMiss, .ICacheAccess, .PrivilegedM,
      .InstrPageFaultF, .LoadPageFaultM, .StoreAmoPageFaultM,
      .InstrMisalignedFaultM, .IllegalIEUFPUInstrD,
      .LoadMisalignedFaultM, .StoreAmoMisalignedFaultM,
      .MTimerInt, .MExtInt, .SExtInt, .MSwInt,
      .MTIME_CLINT, .IEUAdrxTvalM, .SetFflagsM,
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
      .InstrD,                             // instruction from IFU
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
      .FIntDivResultW);
  end else begin                           // no F_SUPPORTED or D_SUPPORTED; tie outputs low
    assign {FPUStallD, FWriteIntE, FCvtIntE, FIntResM, FCvtIntW, FRegWriteM,
            IllegalFPUInstrD, SetFflagsM, FpLoadStoreM,
            FWriteDataM, FCvtIntResW, FIntDivResultW, FDivBusyE} = '0;
  end

  if (P.F_SUPPORTED) begin:fpu_1
    fpu #(P) 
    fpu_1(
      .clk, .reset,
      .FRM_REGW,                           // Rounding mode from CSR
      .InstrD,                             // instruction from IFU
      .ReadDataW(ReadDataW_1[P.FLEN-1:0]),   // Read data from memory
      .ForwardedSrcAE(ForwardedSrcAE_1),                     // Integer input being processed (from IEU)
      .StallE, .StallM, .StallW, .FlushE, .FlushM, .FlushW,
      .RdE(RdE_1), .RdM(RdM_1), .RdW(RdW_1),                    // which FP register to write to (from IEU)
      .STATUS_FS,                          // is floating-point enabled?
      .FRegWriteM(FRegWriteM_1),                         // FP register write enable
      .FpLoadStoreM(FpLoadStoreM_1),
      .ForwardedSrcBE(ForwardedSrcBE_1),                     // Integer input for intdiv
      .Funct3E(Funct3E_1), .Funct3M(Funct3M_1), .IntDivE(IntDivE_1), .W64E(W64E_1), // Integer flags and functions
      .FPUStallD(FPUStallD_1),                          // Stall the decode stage
      .FWriteIntE(FWriteIntE_1), .FCvtIntE(FCvtIntE_1),              // integer register write enable, conversion operation
      .FWriteDataM(FWriteDataM_1),                        // Data to be written to memory
      .FIntResM(FIntResM_1),                           // data to be written to integer register
      .FCvtIntResW(FCvtIntResW_1),                        // fp -> int conversion result to be stored in int register
      .FCvtIntW(FCvtIntW_1),                           // fpu result selection
      .FDivBusyE(FDivBusyE_1),                          // Is the divide/sqrt unit busy (stall execute stage)
      .IllegalFPUInstrD(IllegalFPUInstrD_1),                   // Is the instruction an illegal fpu instruction
      // .SetFflagsM,                         // FPU flags (to privileged unit)
      .FIntDivResultW(FIntDivResultW_1));
  end else begin                           // no F_SUPPORTED or D_SUPPORTED; tie outputs low
    assign {FPUStallD_1, FWriteIntE_1, FCvtIntE_1, FIntResM_1, FCvtIntW_1, FRegWriteM_1,
            IllegalFPUInstrD_1, FpLoadStoreM_1,
            FWriteDataM_1, FCvtIntResW_1, FIntDivResultW_1, FDivBusyE_1} = '0;
  end

  if (P.F_SUPPORTED) begin:fpu_2
    fpu #(P) 
    fpu_2(
      .clk, .reset,
      .FRM_REGW,                           // Rounding mode from CSR
      .InstrD,                             // instruction from IFU
      .ReadDataW(ReadDataW_2[P.FLEN-1:0]),   // Read data from memory
      .ForwardedSrcAE(ForwardedSrcAE_2),                     // Integer input being processed (from IEU)
      .StallE, .StallM, .StallW, .FlushE, .FlushM, .FlushW,
      .RdE(RdE_2), .RdM(RdM_2), .RdW(RdW_2),                    // which FP register to write to (from IEU)
      .STATUS_FS,                          // is floating-point enabled?
      .FRegWriteM(FRegWriteM_2),                         // FP register write enable
      .FpLoadStoreM(FpLoadStoreM_2),
      .ForwardedSrcBE(ForwardedSrcBE_2),                     // Integer input for intdiv
      .Funct3E(Funct3E_2), .Funct3M(Funct3M_2), .IntDivE(IntDivE_2), .W64E(W64E_2), // Integer flags and functions
      .FPUStallD(FPUStallD_2),                          // Stall the decode stage
      .FWriteIntE(FWriteIntE_2), .FCvtIntE(FCvtIntE_2),              // integer register write enable, conversion operation
      .FWriteDataM(FWriteDataM_2),                        // Data to be written to memory
      .FIntResM(FIntResM_2),                           // data to be written to integer register
      .FCvtIntResW(FCvtIntResW_2),                        // fp -> int conversion result to be stored in int register
      .FCvtIntW(FCvtIntW_2),                           // fpu result selection
      .FDivBusyE(FDivBusyE_2),                          // Is the divide/sqrt unit busy (stall execute stage)
      .IllegalFPUInstrD(IllegalFPUInstrD_2),                   // Is the instruction an illegal fpu instruction
      // .SetFflagsM,                         // FPU flags (to privileged unit)
      .FIntDivResultW(FIntDivResultW_2));
  end else begin                           // no F_SUPPORTED or D_SUPPORTED; tie outputs low
    assign {FPUStallD_2, FWriteIntE_2, FCvtIntE_2, FIntResM_2, FCvtIntW_2, FRegWriteM_2,
            IllegalFPUInstrD_2, FpLoadStoreM_2,
            FWriteDataM_2, FCvtIntResW_2, FIntDivResultW_2, FDivBusyE_2} = '0;
  end

  if (P.F_SUPPORTED) begin:fpu_3
    fpu #(P) 
    fpu_3(
      .clk, .reset,
      .FRM_REGW,                           // Rounding mode from CSR
      .InstrD,                             // instruction from IFU
      .ReadDataW(ReadDataW_3[P.FLEN-1:0]),   // Read data from memory
      .ForwardedSrcAE(ForwardedSrcAE_3),                     // Integer input being processed (from IEU)
      .StallE, .StallM, .StallW, .FlushE, .FlushM, .FlushW,
      .RdE(RdE_3), .RdM(RdM_3), .RdW(RdW_3),                    // which FP register to write to (from IEU)
      .STATUS_FS,                          // is floating-point enabled?
      .FRegWriteM(FRegWriteM_3),                         // FP register write enable
      .FpLoadStoreM(FpLoadStoreM_3),
      .ForwardedSrcBE(ForwardedSrcBE_3),                     // Integer input for intdiv
      .Funct3E(Funct3E_3), .Funct3M(Funct3M_3), .IntDivE(IntDivE_3), .W64E(W64E_3), // Integer flags and functions
      .FPUStallD(FPUStallD_3),                          // Stall the decode stage
      .FWriteIntE(FWriteIntE_3), .FCvtIntE(FCvtIntE_3),              // integer register write enable, conversion operation
      .FWriteDataM(FWriteDataM_3),                        // Data to be written to memory
      .FIntResM(FIntResM_3),                           // data to be written to integer register
      .FCvtIntResW(FCvtIntResW_3),                        // fp -> int conversion result to be stored in int register
      .FCvtIntW(FCvtIntW_3),                           // fpu result selection
      .FDivBusyE(FDivBusyE_3),                          // Is the divide/sqrt unit busy (stall execute stage)
      .IllegalFPUInstrD(IllegalFPUInstrD_3),                   // Is the instruction an illegal fpu instruction
      // .SetFflagsM,                         // FPU flags (to privileged unit)
      .FIntDivResultW(FIntDivResultW_3));
  end else begin                           // no F_SUPPORTED or D_SUPPORTED; tie outputs low
    assign {FPUStallD_3, FWriteIntE_3, FCvtIntE_3, FIntResM_3, FCvtIntW_3, FRegWriteM_3,
            IllegalFPUInstrD_3, FpLoadStoreM_3,
            FWriteDataM_3, FCvtIntResW_3, FIntDivResultW_3, FDivBusyE_3} = '0;
  end

  
  // WIDENED STARBUG REGFILE
    // Instantiate Widened regfile
    regfile_widened #(P.XLEN, P.E_SUPPORTED) regfile_widened (
      .clk(clk), .reset(reset),
      .we3(we3), .we6(we6), .we9(we9), .we12(we12),
      .a1(a1), .a2(a2), .a3(a3),
      .a4(a4), .a5(a5), .a6(a6),
      .a7(a7), .a8(a8), .a9(a9),
      .a10(a10), .a11(a11), .a12(a12),
      .wd3(wd3), .wd6(wd6), .wd9(wd9), .wd12(wd12),
      .rd1(rd1), .rd2(rd2),
      .rd4(rd4), .rd5(rd5),
      .rd7(rd7), .rd8(rd8),
      .rd10(rd10), .rd11(rd11)
    );
  // END STARBUG REGFILE

endmodule
