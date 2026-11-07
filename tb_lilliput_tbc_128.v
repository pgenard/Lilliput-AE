`timescale 1ns/1ps

module tb_lilliput_tbc_128;

reg clk;
reg rst_n;
reg start;

reg [127:0] key;
reg [127:0] tweak;
reg [127:0] data_in;

wire [127:0] data_out;
wire busy;
wire done;

integer pass_count;
integer fail_count;

// DUT
lilliput_tbc_128 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .key(key),
    .tweak(tweak),
    .data_in(data_in),
    .data_out(data_out),
    .busy(busy),
    .done(done)
);

// 100 MHz clock
initial clk = 0;
always #5 clk = ~clk;

// Execute one encryption test
task run_test;

    input [127:0] test_key;
    input [127:0] test_tweak;
    input [127:0] test_plaintext;
    input [127:0] expected_ciphertext;
    input [80*8:1] test_name;

    integer timeout;

    begin

        // Apply inputs
        @(negedge clk);

        key = test_key;
        tweak = test_tweak;
        data_in = test_plaintext;

        // Start encryption
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Wait for completion
        timeout = 0;

        while ((done !== 1'b1) && (timeout < 100)) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        // Check result
        if (done !== 1'b1) begin

            $display("FAIL: %0s - TIMEOUT", test_name);
            fail_count = fail_count + 1;

        end
        else if (data_out !== expected_ciphertext) begin

            $display("FAIL: %0s", test_name);

            $display("  EXPECTED = %032h",
                     expected_ciphertext);

            $display("  ACTUAL   = %032h",
                     data_out);

            fail_count = fail_count + 1;

        end
        else begin

            $display("PASS: %0s", test_name);

            $display("  CIPHERTEXT = %032h",
                     data_out);

            pass_count = pass_count + 1;

        end

        // Allow DUT to return to idle
        @(negedge clk);

    end

endtask

// Main test sequence
initial begin
    $display("----------------------------------------");
    $display(" Lilliput-TBC-II-128 Testbench");
    $display("----------------------------------------");

    clk = 0;
    rst_n = 0;
    start = 0;

    key = 0;
    tweak = 0;
    data_in = 0;

    pass_count = 0;
    fail_count = 0;

    // Reset
    repeat (4) @(negedge clk);
    rst_n = 1;

    // --------------------------------
    // TEST 1: ZERO
    // --------------------------------

    run_test(
        128'h00000000000000000000000000000000,
        128'h00000000000000000000000000000000,
        128'h00000000000000000000000000000000,
        128'h7cc2622ba832f0505475edcf3a701eb5,
        "ZERO reference vector"
    );

    // --------------------------------
    // TEST 2: ORDER
    // --------------------------------

    // Randomized reference tests
    `include "random_tests.tv"

    run_test(
        128'h0f0e0d0c0b0a09080706050403020100,
        128'h0f0e0d0c0b0a09080706050403020100,
        128'h0f0e0d0c0b0a09080706050403020100,
        128'h5dd938caeda68da8fc1041ba58dd000e,
        "ORDER reference vector"
    );

    // --------------------------------
    // FINAL REPORT
    // --------------------------------

    $display("");
    $display("----------------------------------------");
    $display(" Verification Summary");
    $display("----------------------------------------");

    $display("Passed : %0d", pass_count);
    $display("Failed : %0d", fail_count);

    if (fail_count == 0 && pass_count == 12)
        $display("RESULT: ALL TESTS PASSED");
    else
        $display("RESULT: VERIFICATION FAILED");

    $display("----------------------------------------");

    $finish;

end

// Global timeout
initial begin
    #100000;
    $display("ERROR: Simulation timeout");
    $finish;
end

endmodule // tb_lilliput_tbc_128
