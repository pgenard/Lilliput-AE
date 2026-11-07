`timescale 1ns/1ps

module lilliput_tbc_128 (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire[127:0] key,
    input wire[127:0] tweak,
    input wire[127:0] data_in,
    output reg[127:0] data_out,
    output reg busy,
    output reg done
);

    reg[127:0] state_reg;
    reg[255:0] tk_reg;
    reg[4:0] round_counter;

    wire[63:0] round_tweakey;
    wire[255:0] tk_next;
    wire[127:0] round_state;
    wire final_round;

    assign final_round = (round_counter == 5'd31);

    // Tweakey schedule
    lilliput_tweakey u_tweakey (
        .tk_state(tk_reg),
        .round_number(round_counter),
        .round_tweakey(round_tweakey),
        .next_tk_state(tk_next)
    );

    // Encryption round
    lilliput_round u_round (
        .state_in(state_reg),
        .round_tweakey(round_tweakey),
        .final_round(final_round),
        .state_out(round_state)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg     <= 128'b0;
            tk_reg        <= 256'b0;
            round_counter <= 5'b0;
            data_out      <= 128'b0;
            busy          <= 1'b0;
            done          <= 1'b0;
        end

        else begin
            done <= 1'b0;

            if (start && !busy) begin
                state_reg <= data_in;

                // TK = tweak || key
                // Byte zero occupies the least significant byte.
                tk_reg <= {
                    key[127:64],
                    key[63:0],
                    tweak[127:64],
                    tweak[63:0]
                };

                round_counter <= 5'd0;
                busy <= 1'b1;
            end

            else if (busy) begin
                state_reg <= round_state;

                if (final_round) begin
                    data_out <= round_state;
                    busy <= 1'b0;
                    done <= 1'b1;
                    round_counter <= 5'd0;
                end

                else begin
                    tk_reg <= tk_next;
                    round_counter <= round_counter + 1'b1;
                end
            end
        end
    end
endmodule // lilliput_tbc_128
