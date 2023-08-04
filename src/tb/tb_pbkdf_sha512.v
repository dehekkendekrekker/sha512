//======================================================================
//
// tb_sha512_core.v
// ----------------
// Testbench for the PBKDF using the SHA-512 core.
//
//
// Author: DHK
// Copyright (c) 2023, Rawatech R&D
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

`default_nettype none

module tb_pbkdf_sha512();
//----------------------------------------------------------------
// Internal constant and parameter definitions.
//----------------------------------------------------------------
parameter DEBUG = 0;

parameter CLK_PERIOD      = 2;
parameter CLK_HALF_PERIOD = CLK_PERIOD / 2;


//----------------------------------------------------------------
// Register and Wire declarations.
//----------------------------------------------------------------
reg [31 : 0] cycle_ctr;
reg [31 : 0] error_ctr;
reg [31 : 0] tc_ctr;

reg             tb_clk;
reg             tb_reset_n;
reg             tb_ce;
reg             tb_init;

reg [1023 : 0] tb_data;
reg [31   : 0] tb_rounds;
wire           tb_ready;

wire [511 : 0] tb_digest;

//----------------------------------------------------------------
// Device Under Test.
//----------------------------------------------------------------
pbkdf_sha512 dut(
    .clk(tb_clk),
    .reset_n(tb_reset_n),
    .ce(tb_ce),
    .init(tb_init),
    .data(tb_data),
    .rounds(tb_rounds),
    .ready(tb_ready),
    .digest(tb_digest)
);

//----------------------------------------------------------------
// clk_gen
//
// Always running clock generator process.
//----------------------------------------------------------------
always begin : clk_gen
    #CLK_HALF_PERIOD;
    tb_clk = !tb_clk;
end // clk_gen

//----------------------------------------------------------------
// reset_dut()
//
// Toggle reset to put the DUT into a well known state.
//----------------------------------------------------------------
task reset_dut;
begin
    $display("*** Toggle reset.");
    tb_reset_n = 0;
    #(2 * CLK_PERIOD);
    tb_reset_n = 1;
end
endtask // reset_dut

//----------------------------------------------------------------
// init_sim()
//
// Initialize all counters and testbed functionality as well
// as setting the DUT inputs to defined values.
//----------------------------------------------------------------
task init_sim;
begin
    cycle_ctr = 0;
    error_ctr = 0;
    tc_ctr = 0;

    tb_clk = 0;
    tb_reset_n = 1;
    tb_ce = 0;
    tb_rounds = 0;

    tb_init = 0;

    tb_data = {32{32'h00000000}};
end
endtask // init_dut

//----------------------------------------------------------------
// display_test_result()
//
// Display the accumulated test results.
//----------------------------------------------------------------
task display_test_result;
begin
    if (error_ctr == 0)
    begin
        $display("*** All %02d test cases completed successfully", tc_ctr);
    end
    else
    begin
        $display("*** %02d test cases did not complete successfully.", error_ctr);
    end
end
endtask // display_test_result

//----------------------------------------------------------------
// wait_ready()
//
// Wait for the ready flag in the dut to be set.
//
// Note: It is the callers responsibility to call the function
// when the dut is actively processing and will in fact at some
// point set the flag.
//----------------------------------------------------------------
task wait_ready;
begin
    while (!tb_ready)
    begin
        #(2 * CLK_PERIOD);
    end
end
endtask // wait_ready



//----------------------------------------------------------------
// pbkdf_ce_test()
//
// This testcase tests the correct operation of the CE pin
//----------------------------------------------------------------
task pbkdf_ce_test(
    input [7 : 0] tc_number,
    input ce,
    input expected
);
begin
    $display("*** TC %0d ce behaviour test case started.", tc_number);
    tc_ctr = tc_ctr + 1;

    tb_ce   = ce;
    tb_init = 1;

    #(2 * CLK_PERIOD);

    // Verify that ready is still high
    if (tb_ready == expected) begin
        $display("*** TC %0d successful.", tc_number);
        $display("");
    end else begin
        $display("*** ERROR: TC %0d NOT successful.", tc_number);
        $display("Expected: 0x%01x", expected);
        $display("Got:      0x%01x", tb_ready);
        $display("");

        error_ctr = error_ctr + 1;
    end
end
endtask


//----------------------------------------------------------------
// pbkdf_test_runner()
//
// This test case tests the correct operation of $rounds rounds of 
// single block SHA-512 hashes
//----------------------------------------------------------------
task pbkdf_test_runner(input [7 : 0]    tc_number,
                input [1023 : 0] block,
                input [31 : 0] rounds,
                input [511 : 0]  expected);

begin
    $display("*** TC %0d single block test case started.", tc_number);
    tc_ctr = tc_ctr + 1;

    tb_data = block;
    tb_rounds = rounds;
    tb_init = 1;
    
    #(2 * CLK_PERIOD);
    tb_init = 0;

    wait_ready();

    if (tb_digest == expected) begin
        $display("*** TC %0d successful.", tc_number);
        $display("");
    end else begin
        $display("*** ERROR: TC %0d NOT successful.", tc_number);
        $display("Expected: 0x%064x", expected);
        $display("Got:      0x%064x", tb_digest);
        $display("");

        error_ctr = error_ctr + 1;
    end
end
endtask

//----------------------------------------------------------------
// pbkdf_core_test
// The main test functionality.
//----------------------------------------------------------------
initial begin : pbkdf_core_test
    reg [1024 : 0] block;
    reg [511 : 0]  tc1_expected;
    reg [511 : 0]  tc2_expected;
    reg [511 : 0]  tc3_expected;
    reg [31:0] rounds;
    
    $display("   -- Testbench for pbkdf(sha512) core started --");

    init_sim();
    reset_dut();

    // CE behavior tests
    pbkdf_ce_test(8'd1, 1'b0, 1'b1);
    pbkdf_ce_test(8'd2, 1'b1, 1'b0);

    reset_dut();

    // Single block test mesage, calcute 2 rounds
    block = 1024'h6162638000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
    rounds       = 2;
    tc1_expected = 512'h373a9f3a902cf561003b513c94c5164ba4af135cbc4eb4d856b89ea5609523f130bbe5e453e6c645b2765a265aaeb1390c82c913130870636cd0c8ecf980d851;
    pbkdf_test_runner(8'd03, block, rounds, tc1_expected);

    // Single block test mesage, calcute 10 rounds
    block = 1024'h6162638000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
    rounds       = 10;
    tc2_expected = 512'h4c3ead8c83442fff47d4386702044f2a6c19730a806de541964b0fa9987cac08641611e02b2e0742ef2600ff82bfe3a711567c8e76dda16b4948f4c76e3c6e9c;
    pbkdf_test_runner(8'h04, block, rounds, tc2_expected);

    // Single block test mesage, calcute 50 rounds
    block = 1024'h6162638000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
    rounds       = 50;
    tc3_expected = 512'h26d4ce3f28c94c3f354ceac7100d8ce1755eccf86345c6a6fb327bf6eae6f7b267de0e6959b74fe4fe520e945f093692d8a24975973638fccd12855b3d7083ca;
    pbkdf_test_runner(8'h05, block, rounds, tc3_expected);

    display_test_result();
    $display("*** Simulation done.");
    $finish;
end // pbkdf_core_test

endmodule

