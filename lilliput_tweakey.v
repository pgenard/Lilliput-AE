`timescale 1ns/1ps

module lilliput_tweakey (
    input wire[255:0] tk_state,
    input wire[4:0] round_number,

    output wire[63:0] round_tweakey,
    output wire[255:0] next_tk_state
);

    function[63:0] mul_m;
        input[63:0] x;
        reg[7:0] b0, b1, b2, b3, b4, b5, b6, b7;

        begin
            b0=x[7:0];
            b1=x[15:8];
            b2=x[23:16];
            b3=x[31:24];
            b4=x[39:32];
            b5=x[47:40];
            b6=x[55:48];
            b7=x[63:56];

            mul_m[63:56] = b6;
            mul_m[55:48] = b5;
            mul_m[47:40] = (b5 << 3) ^ b4;
            mul_m[39:32] = (b4 >> 3) ^ b3;
            mul_m[31:24] = b2;
            mul_m[23:16] = (b6 << 2) ^ b1;
            mul_m[15:8] = b0;
            mul_m[7:0] = b7;
        end
    endfunction // mul_m

    function[63:0] alpha0;
        input[63:0] x;
        begin
            alpha0 = mul_m(x);
        end
    endfunction

    function[63:0] alpha1;
        input[63:0] x;
        begin
            alpha1 = mul_m(mul_m(x));
        end
    endfunction

    function[63:0] alpha2;
        input[63:0] x;
        begin
            alpha2 = mul_m(mul_m(mul_m(x)));
        end
    endfunction

    function[63:0] alpha3;
        input[63:0] x;
        begin
            alpha3 = mul_m(mul_m(mul_m(mul_m(x))));
        end
    endfunction

    wire[63:0] lane0;
    wire[63:0] lane1;
    wire[63:0] lane2;
    wire[63:0] lane3;

    assign lane0 = tk_state[63:0];
    assign lane1 = tk_state[127:64];
    assign lane2 = tk_state[191:128];
    assign lane3 = tk_state[255:192];

    assign round_tweakey = lane0 ^ lane1 ^ lane2 ^ lane3 ^ {56'h0, round_number};

    assign next_tk_state = {
        alpha3(lane3),
        alpha2(lane2),
        alpha1(lane1),
        alpha0(lane0)
    };

endmodule // lilliput_tweakey
