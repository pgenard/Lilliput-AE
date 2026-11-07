`timescale 1ns/1ps

module tb_lilliput_sct2;

reg clk;
reg rst_n;
reg start;

reg[127:0] key;
reg[119:0] nonce;
reg[127:0] associated_data;
reg[127:0] plaintext;

reg[4:0] associated_data_len;
reg[4:0] plaintext_len;

wire[127:0] ciphertext;
wire[127:0] tag;

wire busy;
wire done;

integer errors;
integer passed;
integer timeout;
integer i;

`include "expected_sct2_zero.tv"

// DUT
lilliput_sct2 uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .key(key),
    .nonce(nonce),
    .associated_data(associated_data),
    .associated_data_len(associated_data_len),
    .plaintext(plaintext),
    .plaintext_len(plaintext_len),
    .ciphertext(ciphertext),
    .tag(tag),
    .busy(busy),
    .done(done)
);


// --------------------------------------------------
// Randomized SCT-2 test task
// --------------------------------------------------

task run_sct2_test;
    input[127:0] test_key;
    input[119:0] test_nonce;
    input[127:0] test_ad;
    input[127:0] test_plaintext;

    input[127:0] expected_ciphertext;
    input[127:0] expected_tag;

    input[8*16-1:0] test_name;

    integer timeout_local;

    begin

        @(negedge clk);

        key = test_key;
        nonce = test_nonce;
        associated_data = test_ad;
        plaintext = test_plaintext;

        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        timeout_local = 0;

        while ((done !== 1'b1) &&
               (timeout_local < 500)) begin
            @(negedge clk);
            timeout_local = timeout_local + 1;
        end

        #1;

        if (done !== 1'b1) begin

            $display("FAIL: %0s - TIMEOUT", test_name);
            errors = errors + 1;
        end

        else if ((ciphertext === expected_ciphertext) &&
                 (tag === expected_tag)) begin

            $display("PASS: %0s", test_name);
            passed = passed + 1;
        end

        else begin
            $display("FAIL: %0s", test_name);
            $display("Expected ciphertext = %032h",
                     expected_ciphertext);
            $display("Actual ciphertext   = %032h",
                     ciphertext);
            $display("Expected tag = %032h",
                     expected_tag);
            $display("Actual tag   = %032h",
                     tag);
            errors = errors + 1;

        end

    end

endtask

// --------------------------------------------------
// Clock
// --------------------------------------------------

initial begin

    clk = 1'b0;

    forever #5 clk = ~clk;

end

// --------------------------------------------------
// Main test sequence
// --------------------------------------------------

initial begin

    errors = 0;
    passed = 0;

    rst_n = 1'b0;
    start = 1'b0;

    key = 128'b0;
    nonce = 120'b0;
    associated_data = 128'b0;
    plaintext = 128'b0;
    associated_data_len = 5'd16;
    plaintext_len = 5'd16;

    $display("----------------------------------------");
    $display(" Lilliput-AE SCT-2 / II-128");
    $display("----------------------------------------");

    // Reset

    repeat (3) @(posedge clk);

    @(negedge clk);
    rst_n = 1'b1;

    // ------------------------------------------------
    // ZERO VECTOR
    // ------------------------------------------------

    $display("");
    $display("Running ZERO reference vector...");

    @(negedge clk);
    start = 1'b1;

    @(negedge clk);
    start = 1'b0;

    timeout = 0;

    while ((done !== 1'b1) && (timeout < 500)) begin
        @(negedge clk);
        timeout = timeout + 1;
    end

    #1;

    if (done !== 1'b1) begin
        $display("FAIL: ZERO vector timeout");
        errors = errors + 1;
    end

    else if ((ciphertext === EXPECTED_CIPHERTEXT) &&
             (tag === EXPECTED_TAG)) begin
        $display("PASS: ZERO reference vector");

        $display("C = %032h", ciphertext);
        $display("T = %032h", tag);

        passed = passed + 1;
    end

    else begin
        $display("FAIL: ZERO reference vector");

        $display("Expected C = %032h", EXPECTED_CIPHERTEXT);
        $display("Actual C   = %032h", ciphertext);

        $display("Expected T = %032h", EXPECTED_TAG);
        $display("Actual T   = %032h", tag);

        errors = errors + 1;
    end

    // ------------------------------------------------
    // RANDOMIZED REFERENCE VECTORS
    // ------------------------------------------------

    $display("");
    $display("Running 100 randomized reference vectors...");

    `include "random_sct2_tests.tv"

    // ------------------------------------------------
    // SUMMARY
    // ------------------------------------------------

    $display("");
    $display("----------------------------------------");
    $display(" Verification Summary");
    $display("----------------------------------------");

    $display("Total tests : %0d", passed + errors);
    $display("Passed      : %0d", passed);
    $display("Failed      : %0d", errors);

    if (errors == 0 && passed == 101) begin
        $display("");
        $display("RESULT: ALL TESTS PASSED");
    end

    else begin
        $display("");
        $display("RESULT: VERIFICATION FAILED");
    end

    $display("----------------------------------------");
    $finish;

end

endmodule // tb_lilliput_sct2
