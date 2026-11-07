`timescale 1ns/1ps

module lilliput_round (
    input wire[127:0] state_in,
    input wire[63:0] round_tweakey,
    input wire final_round,
    output wire[127:0] state_out
);

    wire[7:0] sbox_in[0:7];
    wire[7:0] sbox_out[0:7];

    genvar i;

    generate
        for (i=0; i<8; i=i+1) begin : SBOX_LAYER
            assign sbox_in[i] = state_in[8*i +: 8] ^ round_tweakey[8*i +: 8];

            lilliput_sbox sbox_inst (
                .x(sbox_in[i]),
                .y(sbox_out[i])
            );
        end
    endgenerate

    reg[127:0] nonlinear;
    reg[127:0] linear;
    reg[127:0] permuted;

    integer j;

    always @(*) begin

        nonlinear = state_in;

        // Nonlinear transformation
        for (j=0; j<8; j=j+1) begin
            nonlinear[8*(15-j) +: 8] =
                state_in[8*(15-j) +: 8] ^ sbox_out[j];
        end

        linear = nonlinear;

        // Linear transformation
        linear[127:120] = nonlinear[127:120] ^ nonlinear[15:8] ^ nonlinear[23:16] ^ nonlinear[31:24] ^ nonlinear[39:32] ^ nonlinear[47:40] ^ nonlinear[55:48] ^ nonlinear[63:56];

        for (j=9; j<=14; j=j+1) begin
            linear[8*j +: 8] =
                nonlinear[8*j +: 8] ^
                nonlinear[63:56];
        end

        // Permutation layer
        permuted = 128'b0;

        permuted[13*8 +: 8] = linear[0*8 +: 8];
        permuted[9*8  +: 8] = linear[1*8 +: 8];
        permuted[14*8 +: 8] = linear[2*8 +: 8];
        permuted[8*8  +: 8] = linear[3*8 +: 8];

        permuted[10*8 +: 8] = linear[4*8 +: 8];
        permuted[11*8 +: 8] = linear[5*8 +: 8];
        permuted[12*8 +: 8] = linear[6*8 +: 8];
        permuted[15*8 +: 8] = linear[7*8 +: 8];

        permuted[4*8  +: 8] = linear[8*8 +: 8];
        permuted[5*8  +: 8] = linear[9*8 +: 8];
        permuted[3*8  +: 8] = linear[10*8 +: 8];
        permuted[1*8  +: 8] = linear[11*8 +: 8];

        permuted[2*8  +: 8] = linear[12*8 +: 8];
        permuted[6*8  +: 8] = linear[13*8 +: 8];
        permuted[0*8  +: 8] = linear[14*8 +: 8];
        permuted[7*8  +: 8] = linear[15*8 +: 8];

    end // always @ (*)

    assign state_out = final_round ? linear : permuted;

endmodule // lilliput_round
