`timescale 1ns/1ps

module regfile_tb();

  parameter XLEN = 32;
  parameter E_SUPPORTED = 0;   // 32 registers mode

  logic clk, reset;

  // Write enables
  logic we3, we6, we9, we12;

  // Register numbers
  logic [4:0] a1, a2, a3;
  logic [4:0] a4, a5, a6;
  logic [4:0] a7, a8, a9;
  logic [4:0] a10, a11, a12;

  // Write data
  logic [XLEN-1:0] wd3, wd6, wd9, wd12;

  // Read data
  logic [XLEN-1:0] rd1, rd2;
  logic [XLEN-1:0] rd4, rd5;
  logic [XLEN-1:0] rd7, rd8;
  logic [XLEN-1:0] rd10, rd11;

  // Instantiate DUT
  regfile_widened #(XLEN, E_SUPPORTED) dut (
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

  // Clock
  always begin
    clk = 1; #5; clk = 0; #5;
  end

  initial begin
    $dumpfile("regfile.vcd");
    $dumpvars;

    //----------------------------------------
    // RESET
    //----------------------------------------
    reset = 1;
    we3 = 0; we6 = 0; we9 = 0; we12 = 0;
    #20;
    reset = 0;
    #10;

    //----------------------------------------
    // WRITE CYCLE 1: Write 1,2,3 → reg1,reg3,reg5
    //----------------------------------------
    $display("\n=== WRITE CYCLE 1 ===");

    a3 = 5'd1;   wd3  = 32'd1;   we3  = 1;
    a6 = 5'd3;   wd6  = 32'd2;   we6  = 1;
    a12 = 5'd5;  wd12 = 32'd3;   we12 = 1;

    // no write on port 9 this cycle
    we9 = 0;

    @(negedge clk);  // write happens here

    // Disable writes
    we3 = 0; we6 = 0; we12 = 0;

    //----------------------------------------
    // WRITE CYCLE 2: Write 4,5,6 → reg2,reg4,reg6
    //----------------------------------------
    $display("\n=== WRITE CYCLE 2 ===");

    a6  = 5'd2;  wd6  = 32'd4;  we6  = 1;
    a9  = 5'd4;  wd9  = 32'd5;  we9  = 1;
    a12 = 5'd6;  wd12 = 32'd6;  we12 = 1;

    @(negedge clk);

    // Disable writes
    we6 = 0; we9 = 0; we12 = 0;

    //----------------------------------------
    // READ CYCLE: ports 1,2,4,5,7,8
    // → should read reg1,reg2,reg3,reg4,reg5,reg6
    //----------------------------------------
    $display("\n=== READ CYCLE ===");

    a1 = 5'd1;
    a2 = 5'd2;

    a4 = 5'd3;
    a5 = 5'd4;

    a7 = 5'd5;
    a8 = 5'd6;

    @(posedge clk);

    $display("rd1  (reg1) = %0d", rd1);
    $display("rd2  (reg2) = %0d", rd2);
    $display("rd4  (reg3) = %0d", rd4);
    $display("rd5  (reg4) = %0d", rd5);
    $display("rd7  (reg5) = %0d", rd7);
    $display("rd8  (reg6) = %0d", rd8);

    //----------------------------------------
    // PRINT ALL REGISTERS
    //----------------------------------------
    $display("\n=== REGISTER FILE DUMP ===");
    for (int i = 0; i < dut.NUMREGS; i++) begin
      if (i == 0)
        $display("rf[%0d] = 0 (hardwired)", i);
      else
        $display("rf[%0d] = %0d", i, dut.rf[i]);
    end

    $display("\n=== TEST COMPLETE ===");
    $finish;
  end

endmodule
